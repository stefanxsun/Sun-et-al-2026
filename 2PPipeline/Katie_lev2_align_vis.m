function Katie_lev2_align_vis(dirsel,overwrite)
% KATIE_LEV2_ALIGN_VIS aligns visual stim with Ca, removing visual stim between videos
% output is dataVis now aligned.

% Katie Ferguson, Yale University, 2016

global info
global outputDirCardin
inputCa    =  'lev1_align_caframes';
inputVis   = 'lev0_readvis';
analysis = 'lev2_align_vis';
nDirs = length(info);

if nargin<2
    dirsel = 1:nDirs;
end

for iDir = dirsel
    exptag = info(iDir).dir;
    mouse = exptag(1:6);
    outputDir = fullfile(outputDirCardin, analysis, mouse, exptag);
    mkdir(outputDir);
    
    dataDirCa       = fullfile(outputDirCardin, inputCa, mouse, exptag);
    dataDirVis       = fullfile(outputDirCardin, inputVis, mouse, exptag);
    dirInfoCa      = dir(dataDirCa);
    dirInfoVis      = dir(dataDirVis);
    fileNamesCa    = {}; fileNamesVis    = {}; names = {};
    cnt = 0;
    nFiles     = min(length(dirInfoVis),length(dirInfoCa));
    
    for iFile = 1:nFiles
        %need both Ca and Vis data for this, so skip if empty
        if isempty(strfind(dirInfoVis(iFile).name, '.mat')), continue,end
        if isempty(strfind(dirInfoCa(iFile).name, '.mat')), continue,end
        if strcmp(dirInfoCa(iFile).name,dirInfoVis(iFile).name)==0
            fprintf('Warning: File names do not match up for %s and %s.  Skipping \n', dirInfoCa(iFile).name,dirInfoVis(iFile).name), continue, end  %must be the same recording
        cnt = cnt + 1;
        names{cnt}     = dirInfoVis(iFile).name;
        fileNamesCa{cnt} = fullfile(dataDirCa, dirInfoCa(iFile).name);
        fileNamesVis{cnt} = fullfile(dataDirVis, dirInfoVis(iFile).name);
    end
    
    for iFile = 1:length(fileNamesVis)
        
        outputFilename = fullfile(outputDir,names{iFile}(1:end-4));
        if exist([outputFilename '.mat'], 'file') && overwrite==0
            fprintf('skipping %s file %s \n', info(iDir).dir,outputFilename), continue,end
        
        %check if Ca and Vis data files exist
        if ~exist(fileNamesCa{iFile}, 'file')
            fprintf('Warning: %s does not exist.  Skipping \n', fileNamesCa{iFile}), continue,end
        if ~exist(fileNamesVis{iFile}, 'file')
            fprintf('Warning: %s does not exist.  Skipping \n', fileNamesVis{iFile}), continue,end
        
        
        % load the visual stim data
        load(fileNamesVis{iFile})
        
        fprintf('Processing %s\n', outputFilename);
        %load the Ca data
        load(fileNamesCa{iFile})
        
        %%%%remove stim between videos%%%
        
        %for first video:
        if isempty(dataVis.visInd), continue, end
        
        numVideos=length(datadFF.imageInd(:,1));
        if numVideos>1
            %check middle ranges
            for videoInd=1:numVideos-1
                notvalid=datadFF.frameIntervalInd(videoInd+1,1); %start ind of next movie ('videoInd +1')
                checkInd=find(dataVis.visTime(:,2)<datadFF.time(datadFF.frameIntervalInd(videoInd,4)),1,'last'); %last stim end ind in that video
                if (isempty(checkInd) || checkInd>=length(dataVis.visInd)), continue, end  %no frames in this videol, or last cfg index < last frame index your absolute last cfg index
                rm=[];
                checkInd=checkInd+1; % first startInd after last endInd in video
                if checkInd>=size(dataVis.visInd,1),continue, end
                while dataVis.visInd(checkInd,1)<=notvalid  %does next stim fall before next video
                    rm=[rm checkInd]; %remove
                    checkInd=checkInd+1;  %go to next ind
                    if (checkInd)>=size(dataVis.visInd,1), continue, end
                end
                dataVis.visInd(rm,:)=[];
                dataVis.visTime(rm,:)=[];
                dataVis.visStim(rm,:)=[];
            end
        end
        
        %make in terms of Ca indices
        ind1=resampleVis(dataVis.visTime(:,1)',datadFF.time);
        ind2=resampleVis(dataVis.visTime(:,2)',datadFF.time);
        dataVis.visTime=[datadFF.time(ind1)' datadFF.time(ind2)'];
        dataVis.visInd=[ind1' ind2'];
        
        save(outputFilename, 'dataVis');
    end
end
end

function [ib]=resampleVis(a,b)
% resamples vis stim times (a) so in terms of Ca times (b)
% returns indices for these stim times
m = size(a,2); n = size(b,2);
[~,p] = sort([a,b]);
q = 1:m+n; q(p) = q;
t = cumsum(p>m);
r = 1:n; r(t(q(m+1:m+n))) = r;
s = t(q(1:m));
id = r(max(s,1));
iu = r(min(s+1,n));
[~,it] = min([abs(a-b(id));abs(b(iu)-a)]);
ib = id+(it-1).*(iu-id);
end
