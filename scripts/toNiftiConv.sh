
#########################################################################################################
# Script       : toNiftiConv.sh                                                                         #
#                                                                                                       #
# Version      : 1.3                                                                                    #
#                                                                                                       #
# Dependencies: eXtract.sh                                                                              #
#               In neuGrid environment, the script will be automatically downloaded                     #
#                                                                                                       #
# Description  : Script that converts and orients .dicoms_tNC and mnc to nifti.                         #
#                The script does not extract compressed packages.                                       #
#                In case of multiple dicom series it is mandatory that they are well                    #
#                separated in different directories.                                                    #
#                                                                                                       #
# Usage        : path_to_script/toNiftiConv.sh <input_directory> <output_directory> <fdg_priority>      #
#                                                                                                       #
# Author       : E. Sbeiti                                                                              #
#                                                                                                       #
# Last Modification: 02/12/2016                                                                         #
# - Script modified to use mri_convert instead of Dimon (23/11/2015)                                    #
# - Temporary information is stored in txt files no longer (25/02/2016)                                 #
# - The script now finds and converts multiple images (regardless of the number of directory sublevels) #
# - If mri_convert fails, the script will attempt to use dcm2nii (14/11/2016)                           #
# - Added an option to prioritize fdg-pet images, excluding other types (24/11/2016)                    #
#########################################################################################################

echo ""
echo "########################################################################"
echo "##  _   _ _  __ _   _   _____                           _             ##"
echo "## | \ | (_)/ _| | (_) /  __ \                         | |            ##"
echo "## |  \| |_| |_| |_ _  | /  \/ ___  _ ____   _____ _ __| |_ ___ _ __  ##"
echo "## | .   | |  _| __| | | |    / _ \| '_ \ \ / / _ \ '__| __/ _ \ '__| ##"
echo "## | |\  | | | | |_| | | \__/\ (_) | | | \ V /  __/ |  | ||  __/ |    ##"
echo "## \_| \_/_|_|  \__|_|  \____/\___/|_| |_|\_/ \___|_|   \__\___|_|    ##"
echo "##                                                      toNiftiConv.sh #"
echo "########################################################################"
echo ""

set_origin(){
	echo "Attempting to set scan origin"
	# Unzipping necessary files
	input_image_BN=${1}
	output_image=${2}
	if [ ! -f v717.zip ];then
		cp /media/NG/MCR/v717.zip ./v717.zip
	fi
        if [ ! -f setorigin_center.zip ];then
		cp /media/NG/commons/setorigin_center/setorigin_center.zip ./setorigin_center.zip
	fi
	unzip ./v717.zip
	unzip ./setorigin_center.zip
	mv ${input_image_BN} set_my_origin.nii
	chmod +x ./run_setorigin_center.sh
	./run_setorigin_center.sh ./v717
	export FSLOUTPUTTYPE=NIFTI
	fslreorient2std set_my_origin.nii ${output_image}
	rm -rf v717
	rm -rf v717.zip
}

# Debug Mode
set -x

# Initialize here freesurfer, fsl, dcmtk

input_dir="${1}"
output_dir="${2}"
fdg_priority="${3}" # If set to 1, the script will prioritize the conversion of the fdg-pet images, in case mutiple series are found 
if [ -z "${fdg_priority}" ];then
	fdg_priority=0
fi

mkdir .tmpDir_tNC
mkdir .dicoms_tNC
mkdir .niftiDir_tNC

cp -r ${input_dir}/* .tmpDir_tNC/

/var/www/html/scripts/eXtract.sh .tmpDir_tNC complex

i=0
inputIsDicom=0
floatConversion=0

while read dirName
do
	baseDirName=$( basename "${dirName}" )
	n=1
	while [ -d ".dicoms_tNC/${baseDirName}" ];do
		n=$((${n}+1))
		baseDirName="${baseDirName}-${n}"
	done
	exeConv=1 # Useful variable if using mri_convert, it prevents the tool from repeating the conversion for every dicom slice of the same image  

	while read line
	do
		if [ -f "${line}" ];then
			type=$( file -b "${line}" )
			# Move all dicoms to be converted in the next step 
			if [[ "${type}" == DICOM* ]] && [ ${exeConv} -eq 1 ]; then 
				inputIsDicom=1
				if [ ${fdg_priority} -eq 1 ];then
					fdgpet_found=0
					modality=$(dcmdump ${line} | grep modality)
					if [[ $modality == *PET* ]] || [[ $modality == *PT* ]] || [[ $modality == *FDG* ]] || [[ $modality == *pet* ]] || [[ $modality == *pt* ]] || [[ $modality == *fdg* ]];then
						fdgpet_found=$((${fdgpet_found}+1))
					else
						SeriesDescription=$(dcmdump ${line} | grep modality SeriesDescription)
						if [[ $SeriesDescription == *PET* ]] || [[ $SeriesDescription == *PT* ]] || [[ $SeriesDescription == *FDG* ]] || [[ $SeriesDescription == *pet* ]] || [[ $SeriesDescription == *pt* ]] || [[ $SeriesDescription == *fdg* ]];then
							fdgpet_found=$((${fdgpet_found}+1))
						fi
					fi
					
					if [ ${fdgpet_found} -ge 1 ];then
						if [ ! -e ".dicoms_tNC/${baseDirName}" ]; then
							mkdir ".dicoms_tNC/${baseDirName}"
						fi
						mv "${line}" ".dicoms_tNC/${baseDirName}"
					fi
				else
					if [ ! -e ".dicoms_tNC/${baseDirName}" ]; then
						mkdir ".dicoms_tNC/${baseDirName}"
					fi
					mv "${line}" ".dicoms_tNC/${baseDirName}"
				fi
			elif [[ "${type}" == NetCDF* ]];then
				exeConv=1
				baseLineName=$( basename "${line}" ".mnc" )
				mri_convert "${line}" ".niftiDir_tNC/${baseLineName}.nii"
				fslreorient2std ".niftiDir_tNC/${baseLineName}.nii" ".niftiDir_tNC/o_${baseLineName}_${i}.nii"
				error_code=$?
				if [ ${error_code} -ne 0 ];then
					echo "FSL was probably unable to re-orient the image, adding origin center to the image"
					set_origin ".niftiDir_tNC/${baseLineName}.nii" ".niftiDir_tNC/o_${baseLineName}_${i}.nii"
				fi
				rm ".niftiDir_tNC/${baseLineName}.nii"
			elif [[ "${type}" != DICOM* ]] && [[ "${type}" != NetCDF* ]];then
				type2=$( fslinfo ${line} | tail -1 ) 
				if [[ "${type2}" == *NIFTI* ]]; then
					exeConv=1
					baseLineName=$( basename "${line}" ".nii" )
					fslreorient2std "${line}" ".niftiDir_tNC/o_${baseLineName}_${i}.nii"
					error_code=$?
					if [ ${error_code} -ne 0 ];then
						echo "FSL was probably unable to re-orient the image, adding origin center to the image"
						set_origin "${line}" ".niftiDir_tNC/o_${baseLineName}_${i}.nii"
					fi
				fi
			fi
		fi
	done< <(find "${dirName}" -maxdepth 1 -type f | sort)
done< <(find ".tmpDir_tNC" -type d)

# Dicom extraction using cmtk tools
if [ ${inputIsDicom} -eq 1 ];then

	line="" # Set to null the $line already used
	while read line
	do
		dcmftest "${line}" # &> /dev/null
		retcode=$?
		if [ $retcode -eq 0 ]; then
			echo "${line}: processing..."
			tipo=`dcmdump "${line}" | grep '(0002,0010)'`
			if [[ "$tipo" == *LittleEndianExplicit* ]]; then
				echo "already uncompressed."
			elif [[ "$tipo" == *JPEGLossless* ]]; then
				echo "uncompressing JPEG..."
				dcmdjpeg "${line}" "${line}"
			elif [[ "$tipo" == *JPEGLSLossless* ]]; then
				echo "uncompressing JPEG-LS..."
				dcmdjpls "${line}" "${line}"
			elif [[ "$tipo" == *RLELossless* ]]; then
				echo "uncompressing RLE..."
				dcmdrle "${line}" "${line}"
			fi
		else
			echo "${line} is not a dicom!"
			#exit 1
		fi

	done< <(find .dicoms_tNC -type f)

	while read dicomDir
	do
		dicomDirName=$( basename "${dicomDir}" )
		echo "This is what i found: ${dicomDir}"

		firstDicom=$( find "${dicomDir}" -type f | head -1 )
		mri_convert "${firstDicom}" "${dicomDirName}.nii"
		if [[ $? -ne 0 ]];then
			/cvmfs/neugrid.egi.eu/software/x86_64/dcm2nii-6-2013/dcm2nii ${dicomDir}
			/var/www/html/scripts/eXtract.sh ${dicomDir} simple
			converted_image=$(ls ${dicomDir} | grep o*.nii | head -1)
			# If dcm2nii produced no oriented images
			if [ -z "${converted_image}" ]; then
				converted_image=$(ls ${dicomDir} | grep .nii | head -1)
			fi
			mv ${dicomDir}/${converted_image} ${dicomDirName}.nii
		fi
		if [ -e ".niftiDir_tNC/o_${dicomDirName}.nii" ];then
			n=1
			while [ -f ".niftiDir_tNC/o_${dicomDirName}.nii" ];do
				n=$((${n}+1))
				dicomDirName="${dicomDirName}_${n}"
			done
		fi
		fslreorient2std "${dicomDirName}.nii" ".niftiDir_tNC/o_${dicomDirName}.nii"
		error_code=$?
		if [ ${error_code} -ne 0 ];then
			echo "FSL was probably unable to re-orient the image, adding origin center to the image"
			set_origin "${dicomDirName}.nii" ".niftiDir_tNC/o_${dicomDirName}.nii"
		fi
	done< <(find .dicoms_tNC/ -type d)
fi

mv .niftiDir_tNC/* "${output_dir}/"
/var/www/html/scripts/eXtract.sh "${output_dir}/" simple

rm -rf .tmpDir_tNC
rm -rf .dicoms_tNC
rm -rf .niftiDir_tNC

set -x

echo ""
echo "###########################"
echo "##                       ##"
echo "# ______               _  #"
echo "# | ___ \             | | #"
echo "# | |_/ / _   _   ___ | | #"
echo "# | ___ \| | | | / _ \| | #"
echo "# | |_/ /| |_| ||  __/|_| #"
echo "# \____/  \__, | \___|(_) #"
echo "#          __/ |          #"
echo "#         |___/           #"
echo "#                         #"
echo "##     end toNiftiConv.sh #"
echo "###########################"
echo ""


