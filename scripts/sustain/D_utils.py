# -*- coding: utf-8 -*-

def ImportData(input_file,biomarkers_list,DX_label,RID_label):
    
    import numpy as np
    import pandas as pd
    
    in_data = pd.read_csv(input_file)
    
    DX_list=in_data[DX_label].tolist()
    RID_list=in_data[RID_label].tolist()
    
    data=[]
    for j in biomarkers_list:
        data.append(in_data[j])
    data=np.asarray(data)
    data=data.transpose()
    return data,DX_list,RID_list    

def ImportData_ND(input_file,biomarkers_list):
    
    import numpy as np
    import pandas as pd
    
    in_data = pd.read_csv(input_file)

    data=[]
    for j in biomarkers_list:
        data.append(in_data[j])
    data=np.asarray(data)
    data=data.transpose()
    return data    


def printsettings(output_folder,sustainType,dataset_file,biomarkers_list,N,M,N_startpoints,use_parallel_startpoints,N_S_max,N_iterations_MCMC,validate,N_folds):
    outfile= open(output_folder+'/settings.txt', "w")
    outfile.write("sustain type = "+sustainType+"\n")
    outfile.write("Input data file = "+dataset_file+"\n")
    outfile.write("Number of subjects = "+str(M)+"\n")
    outfile.write("Number of startpoints = "+str(N_startpoints)+"( parallel="+str(use_parallel_startpoints)+")"+"\n")
    outfile.write("Max Number of subtypes = "+str(N_S_max)+"\n")
    outfile.write("MCMC iterations = "+str(N_iterations_MCMC)+"\n")
    outfile.write("validation = "+str(validate)+"("+str(N_folds)+"-fold)"+"\n")
    outfile.write("Biomarkers = ")
    outfile.writelines(biomarkers_list) 
    outfile.close() 
    

