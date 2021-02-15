###
# pySuStaIn: SuStaIn algorithm in Python (https://www.nature.com/articles/s41468-018-05892-0)
# Author: Peter Wijeratne (p.wijeratne@ucl.ac.uk)
# Contributors: Leon Aksman (l.aksman@ucl.ac.uk), Arman Eshaghi (a.eshaghi@ucl.ac.uk)
###
import numpy as np
from matplotlib import cbook as cbook
import pickle
import pandas as pd

from kdeebm.mixture_model import fit_all_kde_models, fit_all_gmm_models
from kdeebm import plotting
import D_utils as D_utils
import warnings
warnings.filterwarnings("ignore",category=cbook.mplDeprecation)

from ZscoreSustain  import ZscoreSustain
from MixtureSustain import MixtureSustain

def main():

##### SETTINGS ################################################################

    #either 'mixture_GMM' or 'mixture_KDE' or 'zscore'
    sustainType             = 'zscore'
    assert sustainType in ("mixture_GMM", "mixture_KDE", "zscore"), "sustainType should be either mixture_GMM, mixture_KDE or zscore"

    #input/output
    dataset_name            = 'mock_data'
    dataset_file            = 'sustain/mock_data.csv'
    output_folder           = 'sustain/mock_model/'
    pickle_filename_s       = output_folder+'mock_data_subtype2.pickle'

    biomarkers_list         = ['Hippocampus','Precuneus','MidTemporal','Fusiform','Entorhinal']
    DX_label                = 'DX'
    RID_label               = 'PTID'

#test set settings

    testsets_file          = 'zscores.csv'
    Z_output_file          = 'model_zscores.csv'
    data,DX_list,RID_list=D_utils.ImportData(dataset_file,biomarkers_list,DX_label,RID_label)

    N                       = data.shape[1]         # number of biomarkers
    M                       = data.shape[0]       # number of observations ( e.g. subjects )

    # choose which subjects will be cases and which will be controls  

    labels                  = 2 * np.ones(M, dtype=int)  # 2 - MCI, default assignment here
    for i in range(len(labels)):
        if DX_list[i] == 'CN':
            labels[i] = 1
        elif DX_list[i] == 'AD':
            labels[i] = 0

#    model parameters

    Z_vals                  = np.array([[1,2,3]]*N)     # Z-scores for each biomarker
    Z_max                   = np.array([5]*N)           # maximum z-score

    #parameters needed to define the sustain class
    N_startpoints = 0
    N_S_max = 0
    N_iterations_MCMC = 0
    use_parallel_startpoints = False
    SuStaInLabels           = biomarkers_list

##### MODELRUN ################################################################

    if      sustainType == 'mixture_GMM' or sustainType == "mixture_KDE":

        data_case_control   = data[labels != 2, :]
        labels_case_control = labels[labels != 2]

        if sustainType == "mixture_GMM":
            mixtures        = fit_all_gmm_models(data, labels)
        elif sustainType == "mixture_KDE":
            mixtures        = fit_all_kde_models(data, labels)

        fig, ax, _          = plotting.mixture_model_grid(data_case_control, labels_case_control, mixtures, SuStaInLabels)
        fig.show()

        L_yes               = np.zeros(data.shape)
        L_no                = np.zeros(data.shape)
        for i in range(N):
            if sustainType == "mixture_GMM":
                L_no[:, i], L_yes[:, i] = mixtures[i].pdf(None, data[:, i])
            elif sustainType   == "mixture_KDE":
                L_no[:, i], L_yes[:, i] = mixtures[i].pdf(data[:, i].reshape(-1, 1))

        sustain             = MixtureSustain(L_yes, L_no,        SuStaInLabels, N_startpoints, N_S_max, N_iterations_MCMC, output_folder, dataset_name)

    elif    sustainType == 'zscore':

        sustain             = ZscoreSustain(data, Z_vals, Z_max, SuStaInLabels, N_startpoints, N_S_max, N_iterations_MCMC, output_folder, dataset_name, use_parallel_startpoints)

#### IMPORT SUSTAIN FROM PICKLE

    pickle_file                 = open(pickle_filename_s, 'rb')

    loaded_variables            = pickle.load(pickle_file)

    samples_sequence            = loaded_variables["samples_sequence"]
    samples_f                   = loaded_variables["samples_f"]

    pickle_file.close()

    N_Sub                   = np.shape(samples_sequence)[0]-1
##### EXTERNAL SET ############################################################
    datatest_i=D_utils.ImportData_ND(testsets_file,biomarkers_list)
    N_samples                           = 1000 

    ml_subtype_i, prob_ml_subtype_i, ml_stage_i, prob_ml_stage_i, prob_subtype= sustain.subtype_and_stage_individuals_newData(datatest_i, samples_sequence, samples_f, N_samples)

    testsetstaging_i= pd.DataFrame({'Subtype':int(ml_subtype_i[0]+1), 'prob_subtype':np.around(100*prob_ml_subtype_i[0]), 'stage':int(ml_stage_i[0]), 'prob_stage':np.around(100*prob_ml_stage_i[0]), 'prob_S1':np.around(100*prob_subtype[0,0]), 'prob_S2':np.around(100*prob_subtype[0,1]), 'prob_S3':np.around(100*prob_subtype[0,2])})

    testsetstaging_i.to_csv('sustainout.csv')

##### extract Z-scores slice ######################

    colour_mat                          = np.array([[1, 0, 0], [1, 0, 1], [0, 0, 1]]) #, [0.5, 0, 1], [0, 1, 1]])
    temp_mean_f                         = np.mean(samples_f, 1)
    vals                                = np.sort(temp_mean_f)[::-1]
    vals                                = np.array([np.round(x * 100.) for x in vals]) / 100.
    ix                                  = np.argsort(temp_mean_f)[::-1]
    N_S                                 = samples_sequence.shape[0]
    N_bio                               = len(sustain.biomarker_labels)

    for i in range(N_Sub):
        this_samples_sequence           = np.squeeze(samples_sequence[ix[i], :, :]).T
        markers                         = np.unique(sustain.stage_biomarker_index)
        N                               = this_samples_sequence.shape[1]
        confus_matrix                   = np.zeros((N, N))
        for j in range(N):
            confus_matrix[j, :]         = sum(this_samples_sequence == j)
        confus_matrix                   /= float(max(this_samples_sequence.shape))

        zvalues                         = np.unique(sustain.stage_zscore)
        N_z                             = len(zvalues)
        confus_matrix_z                 = np.zeros((N_bio, N, N_z))
        for z in range(N_z):
            confus_matrix_z[sustain.stage_biomarker_index[sustain.stage_zscore == zvalues[z]], :, z] = confus_matrix[(sustain.stage_zscore == zvalues[z])[0],:]

        Z_seq_matrix=np.zeros((N_bio, N))
        for i_bio in range(N_bio):
            for i_sta in range(N):
                Z_seq_matrix[i_bio,i_sta]=Z_seq_matrix[i_bio,max(i_sta-1,0)]+np.sum(confus_matrix_z[i_bio,i_sta,:])        


        if i == ml_subtype_i:
            stage_slice=Z_seq_matrix[:,int(ml_stage_i[0,0])-1]
            data=[biomarkers_list,stage_slice.tolist()]
            with open(Z_output_file, "w") as txt_file:
                for line in data:
                    line=str(line).replace('[', '')
                    line=line.replace(']', '')
                    line=line.replace("'", '')
                    line=line.replace(' ', '')
                    txt_file.write(line + "\n")


if __name__ == '__main__':
    np.random.seed(42)
    main()
