function Stefan_lev0_readvis_psychtoolbox(dirsel, overwrite)
% KATIE_LEV0_READVIS_PSYCHTOOLBOX reads in stim data from smr file and psychtoolbox 
% .mat file, and outputs a struct called dataVis
% dataVis has all info about stim, including vis stim times, stim values, 
% stim_axis (unique values), stim duration, etc. 

% Katie Ferguson, Yale University, 2016

% 1/14/20 Calvin edited code to allow for smrx files to be read using the
% CED library

global outputDirCardin
global spike2Dir
global info


%load CED lib
cedpath='C:\CEDMATLAB\CEDS64ML'; %location of cedpath
CEDS64LoadLib(cedpath);

% the analysis type, string to find data directories and name files
analysis  = 'lev0_readvis';

% loop over the various directories and read in the spike files
nDirs = length(info);
if nargin<1
    dirsel = 1:nDirs;
end
for iDir = dirsel
    exptag = info(iDir).dir;
    mouse = exptag(1:6);
    outputDir = fullfile(outputDirCardin, analysis, mouse, exptag);
    mkdir(outputDir);
    
    dataDir       = fullfile(spike2Dir, mouse, exptag);
    dirInfo      = dir(dataDir);
    fileNames    = {}; names = {};
    cnt = 0;
    nFiles     = length(dirInfo);
    
    for iFile = 1:nFiles
        if isempty(strfind(dirInfo(iFile).name, '.smr'))&&isempty(strfind(dirInfo(iFile).name, '.smrx')), continue,end  %spk2 files only
        cnt = cnt + 1;
        names{cnt}     = dirInfo(iFile).name;
        fileNames{cnt} = fullfile(dataDir, dirInfo(iFile).name);
    end
    
    indx   = strfind(names{1},'_');
    fileinfo=[];
    fileinfo.mouseNum=str2num(names{1}(indx(1)-3:indx(1)-1));
    fileinfo.fov=str2num(names{1}(indx(1)-3:indx(1)-1));
    
    dataAll = [];
    for iFile = 1:length(fileNames)
        fprintf('Processing %s\n', fileNames{iFile});
        
        outputFilename = fullfile(outputDir,names{iFile}(1:end-4));
        
        if exist([outputFilename 'mat'], 'file') && overwrite==0
            fprintf('skipping %s file %s \n', info(iDir).dir,outputFilename), continue,end
        
        fhand = CEDS64Open(fileNames{iFile});
        %ichannum = min(CEDS64MaxChan(fhand),4);
        ichan = str2double(erase(info(iDir).trig,'chan')); %convert channel string from iDir into a number
        maxTimeTicks = CEDS64ChanMaxTime(fhand,1);
        dsec=CEDS64TimeBase(fhand); % sec per time tick, don't know if need
        [fRead,fVals,fTime] = CEDS64ReadWaveF(fhand,ichan,maxTimeTicks,0,maxTimeTicks); %don't know if need fRead and fTime yet
        data_raw=double(fVals');
        time=linspace(0,length(data_raw)/info(iDir).fsample,length(data_raw));
        
        %initialize
        dataVis=[];
        
        dataVis.fileNames = fullfile('\\kermit.med.yale.internal\kermit\Stefan\visstim', mouse, exptag);
        
        %filter signal
        filterOrder=1000;
        bandpassLow=0.01; %in Hz
        bandpassHigh=100; %in Hz - used 20Hz when detecting multiple peaks
        fs=info(iDir).fsample;   %sampling freq
        filterVisStim = fir1(filterOrder,[bandpassLow/(fs/2) bandpassHigh/(fs/2)]);
        data=filtfilt(filterVisStim,1,data_raw);
        data=-data;  %%%%%%%%%%%%%%%%%%% edited for visual stimulus indication from photodiode is downward, SS,08/01/2022
                
        artifactTs=0.5; %0.5 s
        artifactInd=floor(artifactTs*info(iDir).fsample);
       
        %%%%%%%%%%%%%%%%Stefan edited 05/01/2024, now this is a good way of finding the vStimThresh, and it won't be affected by the decrease over time             
        data = detrend(data);
        vStimThresh = 0.005;     
        %%%%%%%%%%%%%%%%%%
        
        idx=find(data>vStimThresh);
        if idx(1)==1, idx=idx(2:end); end
        
        vStimIndStartEst=idx(data(idx-1)<vStimThresh);
        if idx(end)+1>length(data), idx=idx(1:end-1); end
        vStimIndEndEst=idx(data(idx+1)<vStimThresh);
        %starts with on, ends with off
        if vStimIndEndEst(1)<vStimIndStartEst(1), vStimIndEndEst=vStimIndEndEst(2:end); end
        if vStimIndStartEst(end)>vStimIndEndEst(end), vStimIndStartEst=vStimIndStartEst(1:end-1); end
        
        rmStart=[]; rmEnd=[];  rmtrial=[];
        %disregard artifact at beginning and end
        % added by Stefan, remove artifact that start and End is too close
        rmStart=vStimIndStartEst<artifactInd | vStimIndStartEst>length(data)-artifactInd;
        rmEnd=vStimIndEndEst<artifactInd | vStimIndEndEst>length(data)-artifactInd;
        vStimIndEndEst(rmEnd)=[]; vStimIndStartEst(rmStart)=[];
        rmtrial= vStimIndEndEst-vStimIndStartEst < 1*info(iDir).fsample; %remove trials that is too short, can modify
        vStimIndEndEst(rmtrial)=[]; vStimIndStartEst(rmtrial)=[];
        if length(vStimIndStartEst)~=length(vStimIndEndEst)
            fprintf('Warning: Start and end of stim vector are of different lengths \n'), continue,end
        
        %Look in window around estimate for precise stim point
        windowTs=0.01; % 10ms
        windowInd=floor(windowTs*info(iDir).fsample);
        vStimIndStart=[];
        vStimIndEnd=[];
        for stimNum=1:length(vStimIndStartEst)
            vIndStart=(vStimIndStartEst(stimNum)-windowInd:vStimIndStartEst(stimNum)+windowInd);
            vIndEnd=(vStimIndEndEst(stimNum)-windowInd:vStimIndEndEst(stimNum)+windowInd);
            [~,startInd]=max(data(vIndStart)); vStimIndStart(stimNum)=vIndStart(startInd);
            [~,endInd]=max(data(vIndEnd)); vStimIndEnd(stimNum)=vIndEnd(endInd);
        end
        
        
        if exist([dataVis.fileNames,'.csv'], 'file')
            csvFile=load([dataVis.fileNames,'.csv']); %grouped by columns from contrast, orientation, TF, SF, ISI, size diameter
            %reorganizing into same ordre as Katie's stim matrix
            %ORT,'SF','TF','CRF','radius' grouped in rows
            StimStruct=[];
            StimStruct.StimMatrix(1,:) = csvFile(:,2)'; %ORT
            StimStruct.StimMatrix(2,:) = csvFile(:,4)'; %SF
            StimStruct.StimMatrix(3,:) = csvFile(:,3)'; %TF
            StimStruct.StimMatrix(4,:) = csvFile(:,1)'/100; %CRF
            StimStruct.StimMatrix(5,:) = csvFile(:,5)/2'; %radius
            stimFilename=([dataVis.fileNames,'.mat']);
            save([dataVis.fileNames,'.mat'],'StimStruct');
        else
            fprintf('Warning: No .csv file for visual stim in file %s \n', fileNames{iFile});
            dataVis.expType='Unknown'; stimFilename='';
        end
        
        %read in stim file and match indices with stim value
        if ~exist(stimFilename, 'file')
            fprintf('Warning: %s does not exist \n', stimFilename), continue,end
        
        load(stimFilename);  %as StimStruct
        StimStruct.stimOrder=info(iDir).stimStructOrder; %{'ORT','SF','TF','CRF','radius'};
        
        %find which stim are varying
        stim_ind=[];
        for stimTypeInd=1:size(StimStruct.StimMatrix,1)
            if length(unique(StimStruct.StimMatrix(stimTypeInd,:)))>1
                stim_ind=[stim_ind; stimTypeInd];
            end
        end

        stim=StimStruct.StimMatrix(stim_ind,:)';
        stimType=StimStruct.stimOrder(stim_ind);

        dataVis.trial{1}=data;
        dataVis.stimStruct=StimStruct;
        dataVis.stimStructOrder=StimStruct.stimOrder;
        dataVis.fsample=info(iDir).fsample;
        dataVis.time{1}=time;
        dataVis.label={names(1:end-4)};
        dataVis.visInd(:,1)=vStimIndStart;
        dataVis.visInd(:,2)=vStimIndEnd;
        dataVis.visStim=stim;
        dataVis.stimType=stimType;
        dataVis.stim_axis=unique(stim,'rows');
        dataVis.visTime(:,1)=dataVis.time{1}(vStimIndStart);
        dataVis.visTime(:,2)=dataVis.time{1}(vStimIndEnd);
        dataVis.visIndLabel={'Start Index','End Index'};
        dataVis.visTimeLabel={'Start Time','End Time'};
        dataVis.stimDur= mean(dataVis.visTime(:,2)-dataVis.visTime(:,1));
        dataVis.interStimDur=mean(dataVis.visTime(2:end,1)-dataVis.visTime(1:end-1,2));
        %end
        
        save([outputFilename,'mat'],'dataVis','-v7.3');
        
    end
end



