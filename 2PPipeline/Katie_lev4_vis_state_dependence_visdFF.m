function Katie_lev4_vis_state_dependence_visdFF(dirsel,overwrite)
% VIS_STATE_DEPENDENCE determines the dF/F for every visual stim trial and
% every state type for a single recording.
% Output:
% Ca, CaInfo, meanCa_trials, meanCa_cells.
% Ca: dF/F value for every state type, every stim amplitude, every cell, every state trial, and across every ind in the visual stim trial
% Ca is stored as Ca{state,cell number}(Ca per ind in vis stim trial, vis stim).  So e.g., if we have a CRF recording, Ca{2,1}(55,:,7) will give you the dF/F
% values for state type 2 (Q), 0% contrast, cell number 55, every indices
% in the visual stim trial
% CaInfo describes this format: CaInfo.struct: {'state'  'cellnum'}, CaInfo.mat: {'Ca per ind'  'vis stim'}
% along with other infomation about stim duration and time used for baseline (CaInfo.F0time)
% meanCa_trials is the average of Ca across all vis trials in that
% recording
% meanCa_cells is the average of Ca across all cells in that recording


global info
global figureDirCardin
global outputDirCardin
inputVisState = 'lev3_vis_state_visdFF';
inputCa     = 'lev2_calculate_dFF'; %'lev1_align_caframes';
analysis = 'lev4_vis_state_dependence_visdFF';
% analysis = 'lev4_vis_state_visdFF2'; %change by stefan
nDirs = length(info);

for iDir = dirsel
    exptag = info(iDir).dir;
    mouse = exptag(1:6);
    outputDir = fullfile(outputDirCardin, analysis, mouse, exptag);
    mkdir(outputDir);
  
    dataDirCa       = fullfile(outputDirCardin, inputCa, mouse, exptag);
    dataDirVisState       = fullfile(outputDirCardin, inputVisState, mouse, exptag);
    
    dirInfoVisState      = dir(dataDirVisState);
    
    fileNamesVisState = {}; names = {};
    cnt = 0;
    nFiles     = length(dirInfoVisState);
    
    for iFile = 1:nFiles
        if isempty(strfind(dirInfoVisState(iFile).name, '.mat')), continue,end
        
        cnt = cnt + 1;
        names{cnt}     = dirInfoVisState(iFile).name;
        fileNamesVisState{cnt} = fullfile(dataDirVisState, dirInfoVisState(iFile).name);
        fileNamesCa{cnt} = fullfile(dataDirCa, dirInfoVisState(iFile).name);
    end
    
    for iFile = 1:length(fileNamesVisState)
        
        outputFilename = fullfile(outputDir,names{iFile}(1:end-4));
        if exist([outputFilename '.mat'], 'file') && overwrite==0
            fprintf('skipping %s file %s \n', info(iDir).dir,outputFilename), continue,end
        
        if exist(fileNamesCa{iFile}, 'file')==7, continue,
        elseif exist(fileNamesCa{iFile}, 'file')~=2
            fprintf('Warning: %s does not exist.  Skipping \n', fileNamesCa{iFile}), continue,end
        
        fprintf('Processing %s\n', outputFilename);
        
        % load the visual stim data
        load(fileNamesVisState{iFile})
        
        % load the Ca data
        load(fileNamesCa{iFile})
        
        Ca=cell(2,size(datadFF.Ca,1));
        CaPre=cell(2,size(datadFF.Ca,1));
        CaWhole=cell(2,size(datadFF.Ca,1));
        rawCa=cell(2,size(datadFF.Ca,1));
        %meanCa_trials=[]; meanCa_cells=[];
        stimInd=[]; CaMean=[];
        
        for state=1:2
            stimInd=stateVis{state}.stimInd;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%STEFAN edited to avoid vision gui problem which leads to not enough frames, but should be ok to noramlly use it
            deletetrial = stimInd(:,1)<61 | stimInd(:,1)>(length(datadFF.frameInd)-119);
            stimInd(deletetrial,:)=[];  
            stateVis{state}.stimValue(deletetrial,:)=[];
            stateVis{state}.stimAxis=unique(stateVis{state}.stimValue,'rows');
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if isempty(stimInd), continue, end   %no vis stim completely in state
            
            F0time=stateVis{state}.F0time;  %must use the window we did when checking for state across vis stim
            F0winInd=floor(F0time*info(1).fcasample);
            
            numStim=size(stimInd,1);
            minvislength=min(stimInd(:,2)-stimInd(:,1));
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             minvislength=59;   %%%%%% STEFAN edited to avoid vision gui problem, shouldn't use in later time
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            for stimNum=1:numStim
                %F0=mean(datadFF.Ca(:,stimInd(stimNum,1)-F0winInd:stimInd(stimNum,1)-1),2);
                %F=datadFF.Ca(:,stimInd(stimNum,1):stimInd(stimNum,1)+minvislength);   %rather than to visInd(vistrial,2) since rounding errors can give one ind off
                %Fdiff=bsxfun(@minus,F,F0);   %F-F0
                %dFF=bsxfun(@rdivide,Fdiff,F0);  %(F-F0)/F0
                dFF=datadFF.dFF(:,stimInd(stimNum,1):stimInd(stimNum,1)+minvislength);
                dFFPre=datadFF.dFF(:,(stimInd(stimNum,1)-30):stimInd(stimNum,1)-1); %for the 1 second before vis stim CF
                dFFWhole=datadFF.dFF(:,(stimInd(stimNum,1)-60):stimInd(stimNum,1)+119); %for the 6 seconds around vis stim SS
                rawF=datadFF.Ca(:,(stimInd(stimNum,1)-60):stimInd(stimNum,1)+119); %for the 6 seconds around vis stim SS
                for cellNum=1:size(datadFF.Ca,1)
                    Ca{state,cellNum}(:,stimNum)=dFF(cellNum,:);
                    CaPre{state,cellNum}(:,stimNum)=dFFPre(cellNum,:); %saving the 1 second before vis stim CF
                    CaWhole{state,cellNum}(:,stimNum)=dFFWhole(cellNum,:); %saving the 6 second around vis stim SS
                    rawCa{state,cellNum}(:,stimNum)=rawF(cellNum,:); %saving the 6 second around vis stim SS
                    %meanCaAcrossInd{state,cellNum}=mean(Ca{state,cellNum},1);
                    CaMean.ind{state,cellNum}=mean(Ca{state,cellNum},1);
                    CaMean.preInd{state,cellNum}=mean(CaPre{state,cellNum},1); %saving the 1 second before vis stim CF
                end
                F0=[]; F=[]; Fdiff=[]; dFF=[];
                %meanCa_trials{state,cell}=mean(Ca{state,stimval},3);
                
                %meanCa_cells{state,stimval}=mean(meanCa_trials{state,stimval},1);
            end
            
            %CaMean.ind{state,cellNum}=mean(Ca{state,cellNum},1);
            
            startvisind=stimInd(1,1);
            startind=startvisind;
            endind=stimInd(1,1)+minvislength;
            time=datadFF.time(startind:endind)-datadFF.time(startvisind);  %need to use +minvislength instead of visInd(statetrialnum,2) since can have variable number of vis ind length (by 1, depending on downsample)
                       
            
            CaInfo.stimAxis{state}=stateVis{state}.stimAxis;
            CaInfo.stimValue{state}=stateVis{state}.stimValue;

            %             %figure(state)
            %             %for stimval=1:length(stateVis{state}.stimAxis)
            %                 %visInd=[];
            %                 for stimNum=1:numStim
            %                     %if ~isempty(stateVis{state}.stimInd{stimNum}{stimval})
            %                     %if ~isempty(stateVis{state}.stimInd(stimNum)
            %                         %visInd=[visInd; stateVis{state}.stimind{stimNum}{stimval}];
            %                     %end
            %                 end
            %                 if isempty(stimInd), continue, end
            %                 minvislength=min(stimInd(:,2)-stimInd(:,1));
            %                 for vistrial=1:size(stimInd,1)  %for every vis stim trial
            %                     F0=mean(datadFF.Ca(:,stimInd(vistrial,1)-F0winInd:stimInd(vistrial,1)-1),2);
            %                     F=datadFF.Ca(:,stimInd(vistrial,1):stimInd(vistrial,1)+minvislength);   %rather than to visInd(vistrial,2) since rounding errors can give one ind off
            %                     Fdiff=bsxfun(@minus,F,F0);   %F-F0
            %                     dFF=bsxfun(@rdivide,Fdiff,F0);  %(F-F0)/F0
            %                     Ca{state,stimval}(:,:,vistrial)=dFF;
            %                     F0=[]; F=[]; Fdiff=[]; dFF=[];
            %                 end
            %                 meanCa_trials{state,stimval}=mean(Ca{state,stimval},3);
            %                 startvisind=stimInd(1,1);
            %                 startind=startvisind;
            %                 endind=stimInd(1,1)+minvislength;
            %                 time=datadFF.time(startind:endind)-datadFF.time(startvisind);  %need to use +minvislength instead of visInd(statetrialnum,2) since can have variable number of vis ind length (by 1, depending on downsample)
            %
            %                 meanCa_cells{state,stimval}=mean(meanCa_trials{state,stimval},1);
            
            
        end
        CaInfo.goodCells=datadFF.goodCells;
        %        CaInfo.artifactCells=datadFF.artifactCells;
        %CaInfo.projCellNum=info(iDir).labelledCells;
        %CaInfo.numProjCells=length(find(CaInfo.goodCells<=CaInfo.projCellNum));
        %CaInfo.projCellInd=find(CaInfo.goodCells <= CaInfo.projCellNum);
        
        CaInfo.F0time=F0time;
        %CaInfo.struct={'state','stim value'};
        CaInfo.struct={'state','cell'};
        %CaInfo.mat={'cell','Ca per ind','trial num'};
        CaInfo.mat={'Ca per ind','stim'};
        CaInfo.expType=stateVis{2}.expType;  %2=Q
        
        CaInfo.stimDur=stateVis{2}.stimDur;
        CaInfo.interStimDur=stateVis{2}.interStimDur;
        
        %save(outputFilename, 'Ca','meanCa_trials','meanCa_cells','CaInfo');
        save(outputFilename, 'Ca','CaPre','CaWhole','CaMean','CaInfo','rawCa');
    end
    
    
    
end
end








