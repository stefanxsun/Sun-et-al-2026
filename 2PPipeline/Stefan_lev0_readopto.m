function Stefan_readopto(dirsel, overwrite)
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
analysis  = 'lev0_readopto';

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
    
    for iFile = 1:length(fileNames)
        fprintf('Processing %s\n', fileNames{iFile});
        
        outputFilename = fullfile(outputDir,names{iFile}(1:end-4));
        
        if exist([outputFilename 'mat'], 'file') && overwrite==0
            fprintf('skipping %s file %s \n', info(iDir).dir,outputFilename), continue,end
        
        
        %Begin Calvin's code using CED library
        fhand = CEDS64Open(fileNames{iFile});
        %ichannum = min(CEDS64MaxChan(fhand),4);
        ichan = str2double(erase(info(iDir).opto,'chan')); %convert channel string from iDir into a number
        maxTimeTicks = CEDS64ChanMaxTime(fhand,1);
        dsec=CEDS64TimeBase(fhand); % sec per time tick, don't know if need
        [fRead,fVals,fTime] = CEDS64ReadWaveF(fhand,ichan,maxTimeTicks,0,maxTimeTicks); %don't know if need fRead and fTime yet
        data=double(fVals');
        time=linspace(0,length(data)/info(iDir).fsample,length(data));
        %end Calvin's code using CED lib
        
        %initialize
        dataOpto=[];
                
        optoThreshold=mean([max(data),min(data)]);
        idx=find(data>optoThreshold);
        if idx(1)==1, idx=idx(2:end); end
        
        optoIndStart=idx(data(idx-1)<optoThreshold);
        if idx(end)+1>length(data), idx=idx(1:end-1); end
        optoIndEnd=idx(data(idx+1)<optoThreshold);
        %starts with on, ends with off
        if optoIndEnd(1)<optoIndStart(1), optoIndEnd=optoIndEnd(2:end); end
        if optoIndStart(end)>optoIndEnd(end), optoIndStart=optoIndStart(1:end-1); end
        
        if length(optoIndStart)~=length(optoIndEnd)
            fprintf('Warning: Start and end of stim vector are of different lengths \n'), continue,end
  
        
        dataOpto.trial{1}=data;
        dataOpto.fsample=info(iDir).fsample;
        dataOpto.time{1}=time;
        dataOpto.label={names(1:end-4)};
        dataOpto.optoInd(:,1)=optoIndStart;
        dataOpto.optoInd(:,2)=optoIndEnd;
        dataOpto.optoTime(:,1)=dataOpto.time{1}(optoIndStart);
        dataOpto.optoTime(:,2)=dataOpto.time{1}(optoIndEnd);
        dataOpto.optoIndLabel={'Start Index','End Index'};
        dataOpto.optoTimeLabel={'Start Time','End Time'};
        dataOpto.stimDur= mean(dataOpto.optoTime(:,2)-dataOpto.optoTime(:,1));
        dataOpto.interStimDur=mean(dataOpto.optoTime(2:end,1)-dataOpto.optoTime(1:end-1,2));
        %end
        
        save([outputFilename,'mat'],'dataOpto','-v7.3');
        
    end
end



