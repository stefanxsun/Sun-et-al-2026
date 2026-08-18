function Stefan_lev0_face(dirsel, overwrite)

global outputDirCardin
global spike2Dir
global info

%load CED lib
cedpath='C:\CEDMATLAB\CEDS64ML'; %location of cedpath
CEDS64LoadLib(cedpath);

% the analysis type, string to find data directories and name files
analysis  = 'lev0_face';

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
        if isempty(strfind(dirInfo(iFile).name, '.smrx')), continue,end  %spk2 file
        cnt = cnt + 1;
        names{cnt}     = dirInfo(iFile).name;
        fileNames{cnt} = fullfile(dataDir, dirInfo(iFile).name);
    end
    
    dataAll = [];
    for iFile = 1:length(fileNames)
        fprintf('Processing %s\n', fileNames{iFile});
        outputFilename = fullfile(outputDir,names{iFile}(1:end-5));
        if exist([outputFilename '.mat'], 'file') && overwrite==0
            fprintf('skipping %s file %s \n', info(iDir).dir,outputFilename), continue,end
               
        fhand = CEDS64Open(fileNames{iFile});
        ichan = str2double(erase(info(iDir).pupilCam,'chan')); %convert channel string from iDir into a number
        maxTimeTicks = CEDS64ChanMaxTime(fhand,1);
        dsec=CEDS64TimeBase(fhand); % sec per time tick, don't know if need
        [fRead,fVals,fTime] = CEDS64ReadWaveF(fhand,ichan,maxTimeTicks,0,maxTimeTicks); %don't know if need fRead and fTime yet
        data=fVals';
        time=linspace(0,length(data)/info(iDir).fsample,length(data)); %copied from Katie's code to calculate times

        % find start and end indx and times
        %data_thresh=1000; 
%         data_thresh = max(data)/2.25; %Really important, can result in +-2 frames different, need to pay attention 
        data_thresh1= max(data)/5;%added by Stefan, 08/25/2021, to avoid wrong number of frame, not sure if is suitable for all situation
        data_thresh2 = 1; %added by Stefan, 08/25/2021, to avoid wrong number of frame, not sure if is suitable for all situation
     
        
       % frameInd=[intersect(find(data<data_thresh),find(diff(data)>data_thresh))]+1;
        faceInd=[intersect(find(data>data_thresh2),find(diff([0 data])>data_thresh1))];%Edited by Stefan, 08/25/2021
        faceInd(find(diff(faceInd)==1)+1)=[]; %added by Stefan, 09/14/2021, to avoid consecutive frames.

        %WHY 2 frame more than the video??????  
        faceInd(1)=[];
        faceInd(end)=[];
        
        %initialize dataFrame
        dataFace=[];
        
        dataFace.pupilInd=faceInd;
        dataFace.Timestamp=time(faceInd);
        dataFace.time{1}=time;
        
        % save the data to the disk
        save([outputFilename,'.mat'], 'dataFace','-v7.3');
    end
    
end
CEDS64CloseAll();
end




