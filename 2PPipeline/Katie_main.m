% This is the main file from which you will run all your functions/analysis.  
% Run each cell individually to step through the analysis bit by bit. 
cd 'E:\data\code\Stefan_2P_pipeline_shortname_updatedFormat';
% Katie Ferguson, Yale University, 2017
clc;
clear;
 
overwrite=1;  %1=yes, 0=no
cfgMaster=[];
% stefan_info_record
[info,infoSummary] = Stefan_info_file_example_shortname();

% [info,infoSummary] = Stefan_info_file_example(mouse);  %auto filing, 
dirsel=1:length(info);

% TransferSuite2pMatFile
%%
Katie_lev0_readwheel(dirsel,overwrite);
%%
% Stefan_lev0_readopto(dirsel,overwrite);
%%
Katie_lev0_readframes(dirsel, overwrite);
%%
% Katie_lev0_readca(dirsel, overwrite);  %% from ROI gui
%%
Stefan_lev0_readcaSuite2p(dirsel, overwrite); %%Python vesion
% Stefan_lev0_readcaSuite2p_matlab(dirsel, overwrite); %%matlab vesion
%%
% Katie_lev0_readvis_psychtoolbox(dirsel, overwrite)
Stefan_lev0_readvis_psychtoolbox(dirsel, overwrite)
% Stefan_lev0_readvis_RFmapping(dirsel, overwrite) %% for the RF mapping fast fipping photo diode signal
%%
Stefan_lev0_face(dirsel, overwrite)
%%
Katie_lev1_wheel_changepoints(dirsel,overwrite);
% Katie_lev1_wheel_changepoints_specialv(dirsel,overwrite); % edited to roughly deal with bad wheel traces (Stefan)
%% optional: plot wheel changepoints
% Katie_plot_lev1_wheel_changepoints_01(dirsel) %need to ask Katie if this needs to be reconsidered
%%
Katie_lev1_align_caframes(dirsel, overwrite)
%%
Katie_lev2_align_state3(cfgMaster,dirsel,overwrite)
%%
Katie_lev2_align_vis(dirsel,overwrite) 
%%
% Stefan_lev2_calculate_dFF(dirsel,overwrite)
tic
Stefan_lev2_calculate_dFF_parfor(dirsel,overwrite)
toc
%%  some plotting to look at dF/F wrt running/vis stim
% Katie_plot_lev2_Ca_changepoints2(dirsel) 
% Katie_plot_lev2_Ca_vis_state(dirsel,overwrite) %need to edit for Mike's code for cf022 since it has that initial red screen artifact... did the edit back in lev0 readvis
%%
Katie_lev3_define_state2(cfgMaster,dirsel,overwrite)
%% vis stim / state analysis
Katie_lev3_vis_state_visdFF(dirsel,overwrite)
%%
% Stefan_lev2_assign_facestate(dirsel,overwrite) 
%%
% Katie_plot_lev2_Ca_vis_state(dirsel,overwrite)
% Stefan_plot_lev2_Ca_vis_state(dirsel,overwrite)  % add two other panels, facemap zscored traces and behavioral state(1-4 quartiles) assigned to each trial based on facemap
%%
Katie_lev4_vis_state_dependence_visdFF(dirsel,overwrite)
%%
Katie_lev5_vis_trial_state_dependence(dirsel,overwrite)
%%
reorder = 1;     %decide here whether to reorder (basically only for python suite2p multiple day imaging)
Stefan_lev6_vis_cell_state_dependence(dirsel,overwrite,reorder)  
