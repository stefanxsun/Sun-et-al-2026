function [varargout] = VEHA_L1_RunSpikeDetekt(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Checks the for general meta structure
chSourcePath_1 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L0-1-2_UnitClustering');
chMUATDF_Mat = 'VEHA_L0_MUAToDATFile.mat';
chMUATDF_Dat = 'MUA.dat';
if ~exist(fullfile(chSourcePath_1, chSessionName, chMUATDF_Mat), 'file')
    error('%s does not exist for session %s in %s\n', chMUATDF_Mat, chSessionName, chSourcePath_1)
elseif ~exist(fullfile(chSourcePath_1, chSessionName, chMUATDF_Dat), 'file')
    error('%s does not exist for session %s in %s\n', chMUATDF_Dat, chSessionName, chSourcePath_1)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L0-1-2_UnitClustering';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
chDestFolder = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chDestFolder)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chDestFolder);
end
chDestFile_Mat  = 'VEHA_L1_RunSpikeDetekt.mat';
chPRBFile       = '16chan1shankA1.prb';
chPRMFile     = [chSessionName '.prm'];
%Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile_Mat), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\n %s.\n Skipped...\n', chDestFile_Mat, fullfile(chDestPath, chDestMetaFolder, chDestFolder));
    return
else
    fprintf('Processing %s ...', chDestFolder);
end

%Loads input
sINPUT_1 = load(fullfile(chSourcePath_1, chSessionName, chMUATDF_Mat), '-mat'); sINPUT_1 = sINPUT_1.sCFG;
inSampleRate = sINPUT_1.sL0MUATDF.inSampleRate;

%Creates the parameter file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hFID_PRM = fopen(fullfile(chDestPath, chDestMetaFolder, chDestFolder,chPRMFile), 'w');

%writes the parameter file
fprintf(hFID_PRM, 'experiment_name = ''%s''\n', chSessionName);
fprintf(hFID_PRM, 'prb_file = ''16chan1shankA1.prb''\n\n');

fprintf(hFID_PRM, 'traces = dict(\n');
fprintf(hFID_PRM, '\traw_data_files=''%s'',\n', chMUATDF_Dat);
fprintf(hFID_PRM, '\tvoltage_gain=10.,\n');
fprintf(hFID_PRM, '\tsample_rate=%d,\n', inSampleRate);
fprintf(hFID_PRM, '\tn_channels=16,\n');
fprintf(hFID_PRM, '\tdtype=''int16'',\n');
fprintf(hFID_PRM, ')\n\n');

fprintf(hFID_PRM, 'spikedetekt = dict(\n');
fprintf(hFID_PRM, '\tfilter_low=500.,  # Low pass frequency (Hz)\n');
fprintf(hFID_PRM, '\tfilter_high_factor=0.95 * .5,\n');
fprintf(hFID_PRM, '\tfilter_butter_order=3,  # Order of Butterworth filter.\n');
fprintf(hFID_PRM, '\tfilter_lfp_low=0,  # LFP filter low-pass frequency\n');
fprintf(hFID_PRM, '\tfilter_lfp_high=300,  # LFP filter high-pass frequency\n');
fprintf(hFID_PRM, '\tchunk_size_seconds=1,\n');
fprintf(hFID_PRM, '\tchunk_overlap_seconds=.015,\n');
fprintf(hFID_PRM, '\tn_excerpts=50,\n');
fprintf(hFID_PRM, '\texcerpt_size_seconds=1,\n');
fprintf(hFID_PRM, '\tthreshold_strong_std_factor=%.1f,\n', sCFG.sPARAM.dbThresholdStrong );
fprintf(hFID_PRM, '\tthreshold_weak_std_factor=%.1f,\n', sCFG.sPARAM.dbThresholdWeak );
fprintf(hFID_PRM, '\tdetect_spikes=''negative'',\n');
fprintf(hFID_PRM, '\tconnected_component_join_size=1,\n');
fprintf(hFID_PRM, '\textract_s_before=%d,\n', round(sCFG.sPARAM.dbWavfrmBefore_ms * inSampleRate / 1000));
fprintf(hFID_PRM, '\textract_s_after=%d,\n', round(sCFG.sPARAM.dbWavfrmAfter_ms * inSampleRate / 1000));
fprintf(hFID_PRM, '\tn_features_per_channel=3,  # Number of features per channel.\n');
fprintf(hFID_PRM, '\tpca_n_waveforms_max=10000,\n');
fprintf(hFID_PRM, ')\n\n');

fprintf(hFID_PRM, 'klustakwik2 = dict(\n');
fprintf(hFID_PRM, '\tnum_starting_clusters=%d,\n', sCFG.sPARAM.inStartClustNum);
fprintf(hFID_PRM, ')');

%Closes the parameter file
fclose(hFID_PRM);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hFID_PRB = fopen(fullfile(chDestPath, chDestMetaFolder, chDestFolder,chPRBFile), 'w');

%writes the probe file
fprintf(hFID_PRB, 'channel_groups = {\n');
fprintf(hFID_PRB, '\t# Shank index.\n');
fprintf(hFID_PRB, '\t0:\n');
fprintf(hFID_PRB, '\t\t{\n');
fprintf(hFID_PRB, '\t\t\t# List of channels to keep for spike detection.\n');
fprintf(hFID_PRB, '\t\t\t''channels'': range(16),\n\n');
            
fprintf(hFID_PRB, '\t\t\t# Adjacency graph. Dead channels will be automatically discarded\n');
fprintf(hFID_PRB, '\t\t\t# by considering the corresponding subgraph.\n');
fprintf(hFID_PRB, '\t\t\t''graph'': [\n');
fprintf(hFID_PRB, '\t\t\t\t(0, 1), (1, 2),\n');
fprintf(hFID_PRB, '\t\t\t\t(2, 3), (3, 4),\n');
fprintf(hFID_PRB, '\t\t\t\t(4, 5), (5, 6),\n');
fprintf(hFID_PRB, '\t\t\t\t(6, 7), (7, 8),\n');
fprintf(hFID_PRB, '\t\t\t\t(8, 9), (9, 10),\n');
fprintf(hFID_PRB, '\t\t\t\t(10, 11), (11, 12),\n');
fprintf(hFID_PRB, '\t\t\t\t(12, 13), (13, 14),\n');
fprintf(hFID_PRB, '\t\t\t\t(14, 15)\n');
fprintf(hFID_PRB, '\t\t\t],\n\n');
            
fprintf(hFID_PRB, '\t\t\t# 2D positions of the channels, only for visualization purposes\n');
fprintf(hFID_PRB, '\t\t\t# in KlustaViewa. The unit doesn''t matter.\n');
fprintf(hFID_PRB, '\t\t\t''geometry'': {\n');
fprintf(hFID_PRB, '\t\t\t\t15: (0, -7),\n');
fprintf(hFID_PRB, '\t\t\t\t14: (0, -6),\n');
fprintf(hFID_PRB, '\t\t\t\t13: (0, -5),\n');
fprintf(hFID_PRB, '\t\t\t\t12: (0, -4),\n');
fprintf(hFID_PRB, '\t\t\t\t11: (0, -3),\n');
fprintf(hFID_PRB, '\t\t\t\t10: (0, -2),\n');
fprintf(hFID_PRB, '\t\t\t\t9: (0, -1),\n');
fprintf(hFID_PRB, '\t\t\t\t8: (0, 0),\n');
fprintf(hFID_PRB, '\t\t\t\t7: (0, 1),\n');
fprintf(hFID_PRB, '\t\t\t\t6: (0, 2),\n');
fprintf(hFID_PRB, '\t\t\t\t5: (0, 3),\n');
fprintf(hFID_PRB, '\t\t\t\t4: (0, 4),\n');
fprintf(hFID_PRB, '\t\t\t\t3: (0, 5),\n');
fprintf(hFID_PRB, '\t\t\t\t2: (0, 6),\n');
fprintf(hFID_PRB, '\t\t\t\t1: (0, 7),\n');
fprintf(hFID_PRB, '\t\t\t\t0: (0, 8),\n');
fprintf(hFID_PRB, '\t\t\t}\n');
fprintf(hFID_PRB, '\t}\n');
fprintf(hFID_PRB, '}');

%Closes the probe file
fclose(hFID_PRB);

%CDs into the folder for analysis
chOldPath = cd;
%Gets the name of the conda environment set by the user for the klusta suite
chEnv = sCFG.sPARAM.chCondaEnvironment;

%Runs spike detekt using the command line
if isunix
%     chCMD = sprintf('export PATH=/usr/local/miniconda3/condabin:$PATH && conda activate %s && klusta %s --overwrite', chEnv, chPRMFile); %cell array of system commands
    chCMD = sprintf('./VEHA_L1_RunSpikeDetekt.sh %s %s %s', fullfile(chDestPath, chDestMetaFolder, chDestFolder), chEnv, chPRMFile);
else
    cd(fullfile(chDestPath, chDestMetaFolder, chDestFolder));
    chCMD = sprintf('activate %s && %s %s --overwrite', chEnv, chEnv, chPRMFile); %cell array of system commands
end
[blStat, chCmdOut] = system(chCMD, '-echo');
if blStat %status is zero if there is an error
    %         keyboard
    error('ERROR in system command with report:\n%s', chCmdOut)
end

%Gets back to root directory
cd(chOldPath)

%Update sREC
sCFG.sREC = sREC;

%Writes the output in CFG
sCFG.sL1RST.chPRMFile           = chPRMFile;  
sCFG.sL1RST.chPRBFile           = chPRBFile;
sCFG.sL1RST.chScriptName        = mfilename('fullpath');
sCFG.sL1RST.chTimeComputed      = datestr(now);

%Saves the output parameter structure
save(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile_Mat), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('Done! \r')