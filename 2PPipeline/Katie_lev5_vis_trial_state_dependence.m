function Katie_lev5_vis_trial_state_dependence(dirsel,overwrite)
%%
global info
global figureDirCardin
global outputDirCardin
inputVisState = 'lev4_vis_state_dependence_visdFF'; %'lev4_vis_state_dependence';
analysis = 'lev5_vis_trial_state_dependence'; %'lev5_vis_trial_state_dependence';
nDirs = length(info);


for iDir = dirsel
    skipflag=0;
    
    exptag = info(iDir).dir;
    mouse = exptag(1:6);
    outputDir = fullfile(outputDirCardin, analysis, mouse, exptag);
    mkdir(outputDir);
    
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
    end
    
    
    if ~isempty(fileNamesVisState)
        
        for iFile = 1:length(fileNamesVisState)
            outputFilename = fullfile(outputDir,info(iDir).dir);
            if exist([outputFilename '.mat'], 'file') && overwrite==0,
                fprintf('skipping %s file %s \n', info(iDir).dir,outputFilename),skipflag=1; continue,end
            
            fprintf('Processing %s\n', fileNamesVisState{iFile});
            
            % load the visual stim data
            load(fileNamesVisState{iFile})
            
            
            CaTrial=cell(2,size(Ca,2));    %2=L,Q; size(Ca,2)=length(visaxis);
            CaTrialPre=cell(2,size(CaPre,2)); %for the recording before stim
            CaTrialWhole=cell(2,size(CaWhole,2)); %for the recording covering 6s before during and after stimuli
            CaTrialRaw=cell(2,size(rawCa,2)); %for the recording covering 6s before during and after stimuli
            CaTrialInfo.stimValue=cell(2,1);
            minInd=floor(CaInfo.stimDur.*info(iDir).fcasample); %make sure that all files have the same number of ind (dimension2) - otherwise can have rounding errors
            
            minInd=min(minInd,floor(CaInfo.stimDur.*info(iDir).fcasample));
        end
        
        
        
        for state=1:2
            for cellnum=1:size(Ca,2)
                if isempty(Ca{state,cellnum}), continue, end
                if ~isempty(Ca{state,cellnum}) %% & CaInfo.goodCells(cellnum)==1 %%%%%%%%%%%%%%%%%%%%%%%%
                    %if different sized matrices wrt index due to rounding differences, adjust to smaller size
                    %minSz=min(size(Ca{state,visval},2),size(CaTrial{stimType}{state,visval},2));
                    if abs(minInd-size(Ca{state,cellnum},1))>2, continue, end  %if the number of ind are way off what they should be (i.e. not a rounding error), then stim trial was cut so discard
                    Ca{state,cellnum}=Ca{state,cellnum}(1:minInd,:);
                    CaPre{state,cellnum}=CaPre{state,cellnum}(1:floor(minInd/2),:);
                    CaWhole{state,cellnum}=CaWhole{state,cellnum}(1:minInd*3,:);
                    rawCa{state,cellnum}=rawCa{state,cellnum}(1:minInd*3,:);
                    if ~isempty(CaTrial{state,cellnum})    %make sure all consistent sizes
                        %CaTrial{state,cellnum}=CaTrial{state,cellnum}(oldGoodCellInd,1:minInd,:);
                        CaTrial{state,cellnum}=CaTrial{state,cellnum}(1:minInd,:);
                        CaTrialPre{state,cellnum}=CaTrialPre{state,cellnum}(1:minInd,:);
                        CaTrialWhole{state,cellnum}=CaTrialWhole{state,cellnum}(1:minInd,:);
                        CaTrialRaw{state,cellnum}=CaTrialRaw{state,cellnum}(1:minInd,:);
                    end
                    CaTrial{state,cellnum}=cat(2,CaTrial{state,cellnum},Ca{state,cellnum});
                    CaTrialPre{state,cellnum}=cat(2,CaTrialPre{state,cellnum},CaPre{state,cellnum});
                    CaTrialWhole{state,cellnum}=cat(2,CaTrialWhole{state,cellnum},CaWhole{state,cellnum});
                    CaTrialRaw{state,cellnum}=cat(2,CaTrialRaw{state,cellnum},rawCa{state,cellnum});
                end
            end
            CaTrialInfo.stimValue{state}=cat(1,CaTrialInfo.stimValue{state},CaInfo.stimValue{state});
        end
        
        
        %stimDur and interStimDur may vary for each stim type.
        
        CaTrialInfo.stimDur=CaInfo.stimDur;
        CaTrialInfo.interStimDur=CaInfo.interStimDur;
        CaTrialInfo.goodCells=cat(2,CaInfo.goodCells);
    end
    
    CaTrialMean.ind=cellfun(@(x) mean(x,1), CaTrial,'UniformOutput',0);
    CaTrialMean.preInd=cellfun(@(x) mean(x,1), CaTrialPre,'UniformOutput',0);
    
    
    if skipflag==1, continue, end
    %         CaTrialInfo.struct1={'CRF','ORT','SF'};
    CaTrialInfo.struct1={'CRF','ORT','SF','radius'}; %edited by Stefan
    CaTrialInfo.struct2={'state','cell'};
    CaTrialInfo.mat={'every point of each stim','visual stim'};
    save(outputFilename, 'CaTrial','CaTrialPre','CaTrialWhole','CaTrialMean','CaTrialInfo','CaTrialRaw');
end

end








