#$ -S /bin/bash

set -x

# Reading variables

FileName=${1}
AGE_PATIENT=${2}
SUBJ_SEX=${3}
user_email=${4}

# sets the unique folder where outputs are stored

date_string=$(date '+%Y-%m-%d %H:%M:%S')
day=$(echo "${date_string}" | cut -d' ' -f1 | sed 's/-//g')
hour=$(echo "${date_string}" |cut -d' ' -f2 | sed 's/://g')
rnd=$(echo $RANDOM)
rnd=${rnd:0:2}

app_home="/var/www/html"
job_folder="${day}${hour}${rnd}"
job_home=${app_home}/Data/jobs/${job_folder}
mkdir ${job_home}
cd ${job_home}

## populate job folder with useful files

cp -r ${app_home}/scripts/sustain $job_home
cp ${app_home}/commons/LATEX/template.tex $job_home
cp ${app_home}/commons/LATEX/template_zero.tex $job_home
cp ${app_home}/commons/LATEX/legend.png $job_home

########################################################################                                                
#                       Freesurfer                                     #
########################################################################

touch FS.run

export FREESURFER_HOME=/opt/FreeSurfer-5.3.0
source $FREESURFER_HOME/SetUpFreeSurfer.sh
export SUBJECTS_DIR=${job_home}

fileBaseName="${FileName%%.*}"

mkdir ${job_home}/uploaded_file
cp ${app_home}/Data/uploads/${FileName} ${job_home}/uploaded_file

bash ${app_home}/scripts/eXtract.sh ${job_home}/uploaded_file complex
mkdir ${job_home}/inputs

bash ${app_home}/scripts/toNiftiConv.sh ${job_home}/uploaded_file ${job_home}/inputs 
bash ${app_home}/scripts/eXtract.sh ${job_home}/inputs simple
 
cp ${app_home}/uploaded_file/*.nii ${job_home}/inputs

NIFTINAME=$(find ${job_home}/inputs | grep .nii | head -1)


RESULT=${fileBaseName}

recon-all -i ${NIFTINAME} -s "${RESULT}_OUT" -cw256 -all # -openmp 4

mkdir ${RESULT}_OUT/FSresults/
mri_binarize --i ${RESULT}_OUT/mri/aseg.mgz --o "${RESULT}_OUT"/FSresults/_mask_LX.nii.gz --match 17
fslreorient2std  ${RESULT}_OUT/FSresults/_mask_LX.nii.gz ${RESULT}_OUT/FSresults/_mask_LX_o.nii.gz
mri_binarize --i ${RESULT}_OUT/mri/aseg.mgz --o ${RESULT}_OUT/FSresults/_mask_RX.nii.gz --match 53
fslreorient2std  ${RESULT}_OUT/FSresults/_mask_RX.nii.gz ${RESULT}_OUT/FSresults/_mask_RX_o.nii.gz

PAT1=`find ./ -type f -name aseg.stats` ;
echo `sed -n '36p' $PAT1 | awk '{print $9}' | sed "s/,//"` > ${RESULT}_OUT/FSresults/_intracranial.txt

cp -r ${RESULT}_OUT  ${SUBJECTS_DIR} 
asegstats2table -s ${RESULT}_OUT --tablefile ${job_home}/aseg.csv
aparcstats2table -s ${RESULT}_OUT --hemi lh --meas volume --tablefile ${job_home}/parclh.csv
aparcstats2table -s ${RESULT}_OUT --hemi rh --meas volume --tablefile ${job_home}/parcrh.csv

sed 's/\t/,/g' ${job_home}/aseg.csv > ${job_home}/aseg2.csv
sed 's/\t/,/g' ${job_home}/parclh.csv > ${job_home}/parclh2.csv
sed 's/\t/,/g' ${job_home}/parcrh.csv > ${job_home}/parcrh2.csv

#########################################################################
#			Run Sustain                                     #
#########################################################################

# the script below reads the FS outputs, corrects them against confounding factors and calcualtes z-scores which are saved in zscores.csv
export pyage=$AGE_PATIENT
export pysex=$SUBJ_SEX
python3 sustain/correctionandzscore_testset.py

# the script below reads zscores.csv and saves sustain output in sustainout.csv and model_zscores.csv
python3 sustain/stagesussustain_real.py

# read sustainout.csv and save sustain output as variables
SUBJ_SUBTP=$(awk -F "\"*,\"*" 'NR==2 {printf $2}' ${job_home}/sustainout.csv)
SUBJ_STAGE=$(awk -F "\"*,\"*" 'NR==2 {printf $3}' ${job_home}/sustainout.csv)
PROB_SUBTP=$(awk -F "\"*,\"*" 'NR==2 {printf $4}' ${job_home}/sustainout.csv)
PROB_STAGE=$(awk -F "\"*,\"*" 'NR==2 {printf $5}' ${job_home}/sustainout.csv)

PSA=$(awk -F "\"*,\"*" 'NR==2 {printf $6}' ${job_home}/sustainout.csv)
PSB=$(awk -F "\"*,\"*" 'NR==2 {printf $7}' ${job_home}/sustainout.csv)
PSC=$(awk -F "\"*,\"*" 'NR==2 {printf $8}' ${job_home}/sustainout.csv)

sed -i "s#@@PSA@@#$PSA#" sustain/Histomaker.py
sed -i "s#@@PSB@@#$PSB#" sustain/Histomaker.py
sed -i "s#@@PSC@@#$PSC#" sustain/Histomaker.py

python3 sustain/Histomaker.py

########################################################################                                                
#                       Brainpainter                                   #
########################################################################                                                

# lines below read model-zscores.csv to produce brain images to be included in the report with brainpainter 

hipp=$(awk -F "\"*,\"*" 'NR==2 {printf $1}' model_zscores.csv)
prec=$(awk -F "\"*,\"*" 'NR==2 {printf $2}' model_zscores.csv)
mdtp=$(awk -F "\"*,\"*" 'NR==2 {printf $3}' model_zscores.csv)
fusi=$(awk -F "\"*,\"*" 'NR==2 {printf $4}' model_zscores.csv)
ento=$(awk -F "\"*,\"*" 'NR==2 {printf $5}' model_zscores.csv)

cd sustain/brain-coloring/

sed -i "s#@@hipp@@#$hipp#" input/Tourville_template_D.csv
sed -i "s#@@prec@@#$prec#" input/Tourville_template_D.csv
sed -i "s#@@mdtp@@#$mdtp#" input/Tourville_template_D.csv
sed -i "s#@@fusi@@#$fusi#" input/Tourville_template_D.csv
sed -i "s#@@ento@@#$ento#" input/Tourville_template_D.csv

make

cp output/cortical-inner-right-hemisphere_Test.png ${job_home}/cort_inn.png
cp output/cortical-outer-right-hemisphere_Test.png ${job_home}/cort_out.png
cp output/subcortical_Test.png ${job_home}/sub_cort.png

cd ${job_home}

########################################################################                                                
#                       Latex                                          #
########################################################################                                                

# Two latex templates are edited, template_zero.tex in case the subject's stage is 0, template.tex otherwise

SUBJ_ID=$RESULT

sed -i "s#@@IDDDD@@#$SUBJ_ID#" template_zero.tex
sed -i "s#@@AGGGE@@#$AGE_PATIENT#" template_zero.tex
sed -i "s#@@IDDDD@@#$SUBJ_ID#" template.tex
sed -i "s#@@AGGGE@@#$AGE_PATIENT#" template.tex
sed -i "s#@@STAGE@@#$SUBJ_STAGE#" template.tex

if [ $SUBJ_SEX == 0 ]; then
  sed -i "s#@@SSEXX@@#Male#" template.tex
  sed -i "s#@@SSEXX@@#Male#" template_zero.tex
else
  sed -i "s#@@SSEXX@@#Female#" template.tex
  sed -i "s#@@SSEXX@@#Female#" template_zero.tex
fi

sed -i "s#@@SUBPB@@#$PROB_SUBTP#" template.tex
sed -i "s#@@STAPB@@#$PROB_STAGE#" template.tex

sed -i "s#@@X1@@#$X1#" template.tex
sed -i "s#@@X2@@#$X2#" template.tex
 
if [ $SUBJ_SUBTP == 1 ]; then
  sed -i "s#@@SUBTP@@#Subtype 1#" template.tex
  sed -i "s#@@COMMT@@#Subtype 1 comment.#" template.tex
elif [ $SUBJ_SUBTP == 2 ]; then
  sed -i "s#@@SUBTP@@#Subtype 2#" template.tex
  sed -i "s#@@COMMT@@#Subtype 2 comment.#" template.tex
elif [ $SUBJ_SUBTP == 3 ]; then
  sed -i "s#@@SUBTP@@#Subtype 3#" template.tex
  sed -i "s#@@COMMT@@#Subtype 3 comment.#" template.tex
fi

if [ $SUBJ_STAGE == 0 ]; then
  pdflatex template_zero.tex  cp template_zero.pdf ${SUBJ_ID}_Sustain_Report.pdf
  cp template_zero.pdf ${SUBJ_ID}_Sustain_Report.pdf
else
  pdflatex template.tex 
  cp template.pdf ${SUBJ_ID}_Sustain_Report.pdf
fi

# Sending report through Mail

echo "Please find attached your SuStaIn Report." | mail -a ${SUBJ_ID}_Sustain_Report.pdf -s "SuStaIn Report" -- ${user_email}

# Remove useless things from job folder

rm -r ${job_home}/sustain
rm -r ${job_home}/fsaverage
rm -r ${job_home}/inputs
rm -r ${job_home}/*_OUT
rm ${job_home}/FS.run
rm ${job_home}/legend.png
rm ${job_home}/template*
rm ${job_home}/aseg*
rm ${job_home}/parc*

