function Katie_lev0_readwheel(dirsel, overwrite)
% KATIE_LEV0_READWHEEL reads in wheel data from .smr and outputs struct 
% called dataWheel with time series data

% Katie Ferguson, Yale University, 2016
%1/14/2020, Calvin made changes so can read in smrx files... I think? lol

global outputDirCardin
global spike2Dir
global info

%load CED lib
cedpath='C:\CEDMATLAB\CEDS64ML'; %location of cedpath
CEDS64LoadLib(cedpath);

% the analysis type, string to find data directories and name files
analysis  = 'lev0_readwheel';

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
    if isempty(strfind(dirInfo(iFile).name, '.smr'))&&isempty(strfind(dirInfo(iFile).name, '.smrx')), continue,end  %spk2 file
    cnt = cnt + 1;
    names{cnt}     = dirInfo(iFile).name;
    fileNames{cnt} = fullfile(dataDir, dirInfo(iFile).name);
  end
  
  dataAll = [];
  for iFile = 1:length(fileNames)
    fprintf('Processing %s\n', fileNames{iFile});
    outputFilename = fullfile(outputDir,names{iFile}(1:end-4));
    if exist([outputFilename 'mat'], 'file') & overwrite==0
        fprintf('skipping %s file %s \n', info(iDir).dir,outputFilename), continue,end
    %pull data from .smr using ced library, taken from it_quickrfmap code
    fhand = CEDS64Open(fileNames{iFile});
    %ichannum = min(CEDS64MaxChan(fhand),4);
    ichan = str2double(erase(info(iDir).wheel,'chan')); %convert channel string from iDir into a number
    maxTimeTicks = CEDS64ChanMaxTime(fhand,1);
    dsec=CEDS64TimeBase(fhand); % sec per time tick, don't know if need
    [fRead,fVals,fTime] = CEDS64ReadWaveF(fhand,ichan,maxTimeTicks,0,maxTimeTicks); %don't know if need fRead and fTime yet
%   data(fTime+1:fRead+fTime,ichan)=fVals; really only need the fVals I think
%   need to ask Katie why she inverts the wheel data; looks like without
%   inversion the wheel changepoints go negative distances?

    data=fVals;
    data=-data+(max(data)-max(-data));

    dataWheel.trial{1}=double(data'); %only thing changed from katie's old code to mines to read smrx files
    dataWheel.fsample=info(iDir).fsample; %fcasample; 
    dataWheel.time{1}=linspace(0,length(dataWheel.trial{1})/dataWheel.fsample,length(dataWheel.trial{1})); %maximum value in this array matches maxTimeTicks * dsec     
    dataWheel.label={names{iFile}(1:end-4)}; 
    dataWheel.cfg=[];
    dataWheel.time_timestamp{1}=dataWheel.time{1};
    % save the data to the disk
    save([outputFilename,'mat'], 'dataWheel','-v7.3');      
  end
  
CEDS64CloseAll();
   
end
  
  

  
  
  

