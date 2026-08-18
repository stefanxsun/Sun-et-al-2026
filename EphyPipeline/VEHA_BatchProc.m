%% LFP and MUA
% run StartupAnalysis.m
cd 'E:\Ephy\VisExpHighAll';
%%
run VEHA_L0_PreProcessLFP_MS.m
run VEHA_L0_PreProcessMUA_MS.m
%% Spike sorting
% run VEHA_L0_MUAToDATFile_MS.m
% run VEHA_L1_RunSpikeDetekt_MS.m
% run VEHA_L2_ClusterCut_GUI.m
%% Wheel
run VEHA_L0_PreProcessWheelRotation_MS.m
run VEHA_L1_DetectWheelChangePoint_MS.m
%% Visual stimulations
run VEHA_L0_PreProcessVisualAnalog_MS.m
run VEHA_L0_PreProcessNlxLogFile_MS.m
run VEHA_L1_DetectPresentationSet_MS.m
run VEHA_L2_MatchStimLogWithPresentationSet_MS.m

%% Map layers using CSD analysis
run VEHA_L3_LayerMapping_GUI.m  
%% Pupil
% run VEHA_L0_SetPupilMovieParameters_MS.m
%%
run VEHA_L0_PreProcessCameraTrigger_MS.m 
% run VEHA_L1_DetectPupil_MS.m
% run VEHA_L2_RejectPupilErrors_MS.m
% run VEHA_L3_MatchPupilWithCameraTriggers_MS.m
%% FaceMap processing
run VEHA_L0_PrintFaceMapMovieProc
addpath(genpath('E:\Ephy\Utilities\FaceMap-master_Quentin'));
MovieGUI
%%
run VEHA_L1_RunFaceMap_MS.m
run VEHA_L2_DetectFaceChangePoint_MS.m
run VEHA_L3_MatchFaceMapWithCameraTriggers_MS.m
%% Meta Data Structure
run VEHA_L4_MakeMetaDataStructure_MS.m
%%
run VEHA_L5_Hilbert_SFrCtrSSz_MS
%%  power spectra
run VEHA_L5_Grating_MakeDataStructure_MS.m
run VEHA_L6_Grating_FourierPower_MS.m
run VEHA_L7_Grating_PlotLFPPower_SFrCtrSSz_MS.m
%%
run VEHA_L5_MUA_StimuliAverage_MS.m

%%
run VEHA_L5_Visually_Evoked_Potential_MS
%%  Now Beta Events stuff
run VEHA_L5_GetPulse_MS

run VEHA_L6_Pulse_SFrCtrSSz_MS
%%
run VEHA_L6_Pulse_vs_LFP_ETA_MS.m
%%
run VEHA_L6_Pulse_vs_MUA_ETA_MS.m


