function Katie_lev3_vis_state_visdFF(dirsel,overwrite)
% KATIE_LEV3_VIS_STATE Determines which visual stims are in which states for every recording.
% Output:
% VISSTATE{X}, where x=1,2,.. for each state (state name in visState{x}.LABEL)
% visState{x}.VISIND [N x 2 double] gives the start and end vis stim indices for vis stim in each state trial (N trials)
% visState{x}.STATEIND [N x 2 double] gives the indices for the start and end of every state trial
% visState{x}.STATETIMES [N x 2 double] gives the time for the start and end of every state trial
% visState{x}.TIMES {1 x N cell} gives the start and end times of every visual stim in
% every state.  e.g., visState{x}.times{y} will give a n x 2 matrix of
% start and end times for the n visual stim trials found in state trial number y of type
% x
% visState{x}.IND {1 x N cell} same as above, but in indices
% visState{x}.STIM {1 x N cell} gives stim amplitude of every visual stim in
% every state.  e.g., visState{x}.stim{y} will give a n x 1 matrix of stim amplitudes
% for the n visual stim trials found in state trial number y of type x
% visState{x}.STIMTIMES {1 x N cell} gives the visual stim times arranged by stim
% amplitude.  e.g., visState{x}.stimtimes{y}{z} will give an n x 2 matrix
% of the vis stim start and end times every n visual trials in state trial y and visual stim
% amplitude z (e.g., if z=1 for a CRF recording, are accessing stim times for 0% contrast in that trial)
% visState{x}.STIMIND {1 x N cell} same as above but in indices
% visState{x}.STIM_AXIS [1 x M double] are the stim ampl values and order. e.g. for
% ORT trial, visState{x}.stim_axis= [30 60 90 120 150 180 210 240 270 300 330 360]
% visState{x}.EXPTYPE: e.g., 'ORT'
% visState{x}.F0TIME: time (in seconds) used for calculating baseline for
% dF/F (preceding visual stim)
% visState{x}.STIMDUR: average time (in seconds) of visual stim
% visState{x}.INTERSTIMDUR: average time (in seconds) between visual stim


% Katie Ferguson, Yale University, 2016

global info
global figureDirCardin
global outputDirCardin
inputVis = 'lev2_align_vis';
inputState  = 'lev3_define_state';
analysis = 'lev3_vis_state_visdFF';
nDirs = length(info);

F0time=1;  %dFF based on 1 second before vis stim:

for iDir = dirsel
    exptag = info(iDir).dir;
    mouse = exptag(1:6);
    outputDir = fullfile(outputDirCardin, analysis, mouse, exptag);
    mkdir(outputDir);
   
    dataDirState       = fullfile(outputDirCardin, inputState, mouse, exptag);
    dataDirVis       = fullfile(outputDirCardin, inputVis, mouse, exptag);
    
    dirInfoVis      = dir(dataDirVis);
    fileNamesVis = {}; names = {};
    cnt = 0;
    nFiles     = length(dirInfoVis);
    
    for iFile = 1:nFiles
        %make sure we're looking at the same recording for all inputs. Will be
        %fewer vis files than others if also have spont recordings
        if isempty(strfind(dirInfoVis(iFile).name, '.mat')), continue,end
        
        cnt = cnt + 1;
        names{cnt}     = dirInfoVis(iFile).name;
        %force all to have the same name as vis recording
        fileNamesState{cnt} = fullfile(dataDirState, dirInfoVis(iFile).name);
        fileNamesVis{cnt} = fullfile(dataDirVis, dirInfoVis(iFile).name);
    end
    
    for iFile = 1:length(fileNamesVis)
        
        outputFilename = fullfile(outputDir,names{iFile}(1:end-4));
        if exist([outputFilename '.mat'], 'file') && overwrite==0
            fprintf('skipping %s file %s \n', info(iDir).dir,outputFilename), continue,end
        
        
        %check if State data files also exist
        if exist(fileNamesState{iFile}, 'file')==7, continue,
        elseif exist(fileNamesState{iFile}, 'file')~=2
            fprintf('Warning: %s does not exist.  Skipping \n', fileNamesState{iFile}), continue
        end
        
        % load the visual stim data
        load(fileNamesVis{iFile})
        
        fprintf('Processing %s\n', outputFilename);
        
        %define stim_axis
        stim_axis=dataVis.stim_axis;
        
        % load the state data
        load(fileNamesState{iFile});
        
        %find indices of visual stim that are 100% in running and sitting
        %bouts AND have F0time s preceding also in that same state
        
        statenum=0; stateVis=[];
        Lind=find(ismember(cfgStateLabel,'L'));
        Qind=find(ismember(cfgStateLabel,'Q'));
        for stateType=[Lind,Qind]   %running and sitting ind in cfgStateTs/Lfp
            statenum=statenum+1;
            stateVis{statenum}.label=cfgStateLabel{stateType};  %store the type of state (e.g. 'L') in .label
            stateLength=size(cfgStateTs{stateType}.trl,1); %how many trials you have of that state type
            startInd=zeros(1,stateLength);         endInd=zeros(1,stateLength); %for each state trial, indicate the start and end ind of vis stim that fit into those trials
            for stateInd=1:stateLength
                [startind,~]=find(dataVis.visTime(:,1)-F0time>=cfgStateTs{stateType}.trl(stateInd,1),1,'first'); %first one fully in state
                [endind,~]=find(dataVis.visTime(:,2)<=cfgStateTs{stateType}.trl(stateInd,2),1,'last');  %last one fully in state
                if ~isempty(startind)&& ~isempty(endind)
                    startInd(stateInd)=startind;
                    endInd(stateInd)=endind;
                end
            end
            valid=(endInd>=startInd);
            
            %StateVis visInd stores the state ind and the indices of the start and end visual
            %trials within that.  NOT the indices wrt Ca.
            stateVis{statenum}.visInd=[(valid.*startInd)' (valid.*endInd)'];
            rm=stateVis{statenum}.visInd(:,1)==0; %remove state trials where no vis stim
            stateVis{statenum}.visInd(rm,:)=[];
            
            %the ind and time of the state transitions that have vis stim in them
            stateVis{statenum}.stateInd=cfgStateLfp{stateType}.trl;
            stateVis{statenum}.stateTimes=cfgStateTs{stateType}.trl;
            stateVis{statenum}.stateInd(rm,:)=[]; stateVis{statenum}.stateTimes(rm,:)=[];
            
            %initialize times, stim, etc.
            stateVis{statenum}.stimTimes=[];
            stateVis{statenum}.stimValue=[];
            stateVis{statenum}.stimInd=[];
            stateVis{statenum}.stimTrialNum=[];
            
            for stimNum=1:size(stateVis{statenum}.visInd,1)
                stateVis{statenum}.stimTimes=cat(1,stateVis{statenum}.stimTimes,dataVis.visTime(stateVis{statenum}.visInd(stimNum,1):stateVis{statenum}.visInd(stimNum,2),:)); %times of vis stim from stim ind at start of trial to end
                stateVis{statenum}.stimValue=cat(1,stateVis{statenum}.stimValue,dataVis.visStim(stateVis{statenum}.visInd(stimNum,1):stateVis{statenum}.visInd(stimNum,2),:));
                stateVis{statenum}.stimInd=cat(1,stateVis{statenum}.stimInd,dataVis.visInd(stateVis{statenum}.visInd(stimNum,1):stateVis{statenum}.visInd(stimNum,2),:));
                tempVisLength=size(dataVis.visStim(stateVis{statenum}.visInd(stimNum,1):stateVis{statenum}.visInd(stimNum,2),:),1);
                for stimNum2=tempVisLength-1:-1:0
                    stateVis{statenum}.stimTrialNum=[stateVis{statenum}.stimTrialNum; numel(find(ismember(stateVis{statenum}.stimValue,stateVis{statenum}.stimValue(end-stimNum2,:),'rows')))];
                end
            end
            
            dataVis.stimDur= mean(dataVis.visTime(:,2)-dataVis.visTime(:,1));
            dataVis.interStimDur=mean(dataVis.visTime(2:end,1)-dataVis.visTime(1:end-1,2));
            
            stateVis{statenum}.stimAxis=unique(stateVis{statenum}.stimValue,'rows');
            stateVis{statenum}.expType=dataVis.expType;
            stateVis{statenum}.F0time=F0time;
            stateVis{statenum}.stimDur=dataVis.stimDur;
            stateVis{statenum}.interStimDur=dataVis.interStimDur;
            clear valid startInd endInd stimind
        end
        save(outputFilename, 'stateVis');
    end
end








