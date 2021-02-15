#!/bin/bash

#set -x
#set -e

###################################################################################################
# Script       : eXtract.sh                                                                       #
#                                                                                                 #
# Version      : 1.2                                                                              #
#                                                                                                 #
# Description  : Script to recursively extract all archives in any given directory                #
#                Valid archive types are zip, tar, tar.gz, tar.bz2 , bz, bz2, gz, tgz             #
#                                                                                                 #
# Usage        : path_to_script/eXtract.sh <path_to_directory> <extraction_method>                #
#                Where extraction_method can be:                                                  #
#                  simple  : All archives are extracted in the current folder                     #
#                  complex : Every archive is extracted in a separate folder                      #
#                                                                                                 #
# Author       : E. Sbeiti                                                                        #
#                                                                                                 #
# Last Modification: 28/04/2016                                                                   #                                                                        #
# - Fixed an issue where .tar files were not extracted in simple mode (17/11/2015)                #
# - Temporary information is stored in txt files no longer (16/03/2016)                           #
# - 'for' iterations replaced with 'while', to read input file containing namespaces (15/04/2016) #
# - The script is now able to extrart RAR archives (18/04/2016)                                   #
###################################################################################################

echo ""
echo "############################################################"
echo "##      __   __ _                      _            _     ##"
echo "#       \ \ / /| |                    | |          | |     #"
echo "#   ___  \ V / | |_  _ __  __ _   ___ | |_     ___ | |__   #"
echo "#  / _ \ /   \ | __||  __|/ _  | / __|| __|   / __||  _ \  #"
echo "# |  __// /^\ \| |_ | |  | (_| || (__ | |_  _ \__ \| | | | #"
echo "#  \___|\/   \/ \__||_|   \__,_| \___| \__|(_)|___/|_| |_| #"
echo "##                                                        ##"
echo "############################################################"
echo ""

inputDir="${1}"
extraction_method="${2}"

if [[ ${extraction_method} != "simple" ]] && [[ ${extraction_method} != "complex" ]]; then
	echo "Warning: No valid extraction method specified, using default complex mode"
	extraction_method="complex"
fi

# The ${archtrue} variable is set to 1 to let the cicle begin
archtrue=1
while [ ${archtrue} -eq 1 ]; do
	# The cicle started, ${archtrue} is set to 0
	# Every time an archive is found, ${archtrue} is set to 1, so that the cicle can begin again
	archtrue=0
	# If directories have been found, check for archives to extract
	n=$( find "${inputDir}" -type d | wc -l )
	if [ ${n} -gt 0 ]; then
		while read directory
		do
			extrDir=${directory}
			# If at least one file is found in the directory, extract them
			c=$( find "${extrDir}" -maxdepth 1 -type f | wc -l )
			if [ ${c} -gt 0 ]; then
				if [[ ${extraction_method} == "simple" ]];then
					while read archive
					do
						type=$( file -b "${archive}" )
						echo "Analyzing file: ${archive}"
						echo "File type is : ${type}"
						# Detect archive type
						case "${type}" in
							bzip2*) bunzip2 -f "${archive}"; archtrue=1 ;;
							Zip*) unzip -oq -d "${extrDir}" "${archive}"; archtrue=1; rm "${archive}"  ;;
							gzip*) gunzip -f "${archive}"; archtrue=1 ;;
							Minix*) gunzip -f "${archive}"; archtrue=1 ;;
							POSIX*) tar -xf "${archive}" -C "${extrDir}" ; archtrue=1; rm "${archive}" ;;
							tar*)  tar -xf "${archive}" -C "${extrDir}" ; archtrue=1; rm "${archive}" ;;
							RAR*) unrar e "${archive}" "${extrDir}"; archtrue=1; rm "${archive}" ;;
						esac
					done < <(find "${extrDir}" -maxdepth 1 -type f)

				elif [[ ${extraction_method} == "complex" ]];then
					while read archive
					do
						type=$( file -b "${archive}" )
						echo "Analyzing file: ${archive}"
						echo "File type is : ${type}"
						dirPath=$( dirname "${archive}" )
						archiveBaseNameExt=$( basename "${archive}" )
						archiveBaseName=${archiveBaseNameExt%%.*}

						# Detect archive type
						case "${type}" in
							bzip2*) mkdir "${dirPath}/${archiveBaseName}"; mv "${archive}" "${dirPath}/${archiveBaseName}"; bunzip2 -f "${dirPath}/${archiveBaseName}/${archiveBaseNameExt}"; archtrue=1 ;;
							Zip*) mkdir "${dirPath}/${archiveBaseName}"; unzip -oq -d "${dirPath}/${archiveBaseName}" "${archive}"; archtrue=1;  rm "${archive}"  ;;
							gzip*) mkdir "${dirPath}/${archiveBaseName}"; mv "${archive}" "${dirPath}/${archiveBaseName}"; gunzip -f "${dirPath}/${archiveBaseName}/${archiveBaseNameExt}"; archtrue=1 ;;
							Minix*) mkdir "${dirPath}/${archiveBaseName}"; mv "${archive}" "${dirPath}/${archiveBaseName}"; gunzip -f "${dirPath}/${archiveBaseName}/${archiveBaseNameExt}"; archtrue=1 ;;
							POSIX*) mkdir "${dirPath}/${archiveBaseName}"; tar -xf "${archive}" -C "${dirPath}/${archiveBaseName}" ; archtrue=1; rm "${archive}" ;;
							tar*) mkdir "${dirPath}/${archiveBaseName}"; tar -xvf "${archive}" -C "${dirPath}/${archiveBaseName}" ; archtrue=1; rm "${archive}" ;;
							RAR*) mkdir "${dirPath}/${archiveBaseName}"; unrar e "${archive}" "${dirPath}/${archiveBaseName}" ; archtrue=1; rm "${archive}" ;;
						esac
					done < <(find "${extrDir}" -maxdepth 1 -type f)
				fi
			fi
		done < <(find "${inputDir}" -type d)
	fi
done

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
echo "##         end eXtract.sh #"
echo "###########################"
echo ""
