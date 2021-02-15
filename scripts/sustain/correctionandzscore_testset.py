###
# pySuStaIn: SuStaIn algorithm in Python (https://www.nature.com/articles/s41468-018-05892-0)
# Author: Peter Wijeratne (p.wijeratne@ucl.ac.uk)
# Contributors: Leon Aksman (l.aksman@ucl.ac.uk), Arman Eshaghi (a.eshaghi@ucl.ac.uk)
###
import numpy as np
import os
import csv
import pandas as pd
from scipy.stats import linregress

##### SETTINGS ################################################################

input_1= 'aseg2.csv'
input_2= 'parclh2.csv'
input_3= 'parcrh2.csv'

biomarkers_list         = ['Hippocampus','Precuneus','MidTemporal','Fusiform','Entorhinal']
revert_b                = [1,1,1,1,1]
isvolume                = [1,1,1,1,1]

avg_ADNI                = [7399, 16795, 19770, 18020, 3601]
std_ADNI		= [878,  1742,  2170,  1980 , 562 ]

factors_list            = ['Age','PTGENDER','ICV']
means_list              = [72.68, 0.46, 1532051]
slopes_list             = [[-67.6, -237,  0.00134],[-39.3, -1520, 0.00755],[-81.9, -1840, 0.00837],[-72.4, -1666, 0.00691],[-9.15, -374,  0.00129]]
output_file             = 'zscores.csv' 

#import data

in_data_1 = pd.read_csv(input_1)
in_data_2 = pd.read_csv(input_2)
in_data_3 = pd.read_csv(input_3)   

#to be read from ext

age=int(os.environ['pyage'])
sex=int(os.environ['pysex'])
print(type(age),type(sex))
tiv=in_data_2['eTIV'][0]

factors=[]

factors.append(age)
factors.append(sex)
factors.append(tiv)

#create tpd.data frame with the correct volumes

firsttable=pd.DataFrame() 
outtable=pd.DataFrame()

#hippocampus
element=[in_data_1['Left-Hippocampus'][0]+in_data_1['Right-Hippocampus'][0]]
firsttable.insert(0,biomarkers_list[0],element)

#precuneus
element=[in_data_2['lh_precuneus_volume'][0]+in_data_3['rh_precuneus_volume'][0]]
firsttable.insert(1,biomarkers_list[1],element)

#midtemporal
element=[in_data_2['lh_middletemporal_volume'][0]+in_data_3['rh_middletemporal_volume'][0]]
firsttable.insert(2,biomarkers_list[2],element)

#fusiform
element=[in_data_2['lh_fusiform_volume'][0]+in_data_3['rh_fusiform_volume'][0]]
firsttable.insert(3,biomarkers_list[3],element)

#entorhinal
element=[in_data_2['lh_entorhinal_volume'][0]+in_data_3['rh_entorhinal_volume'][0]]
firsttable.insert(4,biomarkers_list[4],element)

#corrections against confounding factors

for i in range(len(biomarkers_list)):
    tobecorrected=firsttable[biomarkers_list[i]][0]
    for j in range(len(factors_list)):
        slope=slopes_list[i][j]
        avg_f=means_list[j]
        tobecorrected=tobecorrected-slope*(factors[j]-avg_f)
       
#zscores
    avg=avg_ADNI[i]
    std=std_ADNI[i]
    zscores=(tobecorrected-avg)/std
    if revert_b[i] == 1:
        zscores=-zscores
    if zscores < 0:
        zscores = 0
    if zscores > 3:
        zscores = 3
    outtable.insert(i,biomarkers_list[i],[zscores])
    
#write outputs    
           
outtable.to_csv(output_file)
