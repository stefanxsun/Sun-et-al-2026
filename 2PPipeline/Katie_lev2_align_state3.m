function Katie_lev2_align_state3(cfgMaster,dirsel,overwrite)

%aligns states with Ca, removing states between videos

global info
global outputDirCardin
inputCa    = 'lev1_align_caframes';
inputState   = 'lev1_wheel_changepoints';
analysis = 'lev2_align_state';
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
    dataDirState       = fullfile(outputDirCardin, inputState, mouse, exptag); 
    dirInfoCa      = dir(dataDirCa);
    dirInfoState      = dir(dataDirState);
    fileNamesCa    = {}; fileNamesState    = {}; names = {};
    cnt = 0;
    nFiles     = length(dirInfoCa);
    
    for iFile = 1:nFiles
        if isempty(strfind(dirInfoCa(iFile).name, '.mat')), continue,end  %spk2 file
        cnt = cnt + 1;
        names{cnt}     = dirInfoCa(iFile).name;
        fileNamesCa{cnt} = fullfile(dataDirCa, dirInfoCa(iFile).name);
        fileNamesState{cnt} = fullfile(dataDirState, dirInfoState(iFile).name);
    end
    
    for iFile = 1:length(fileNamesCa)
        
        outputFilename = fullfile(outputDir,names{iFile}(1:end-4));
        if exist([outputFilename '.mat'], 'file') && overwrite==0
            fprintf('skipping %s file %s \n', info(iDir).dir,outputFilename), continue,end
        
        fprintf('Processing %s\n', outputFilename);
        
        %load the Ca data
        load(fileNamesCa{iFile})
        
        % load the changepoint data
        load(fileNamesState{iFile})
        
        % refine the transition points to remove sitting<2s
        dt=1/info(iDir).fsample;
        [cfgTs, cfgLfp] = Katie_util_removewheeltrials(cfgTs, cfgLfp,dt); %, dataWheelClean2);
        
        %make in terms of Ca indices
        ind1=resampleState(cfgTs.trl(:,1)',datadFF.time);
        ind2=resampleState(cfgTs.trl(:,2)',datadFF.time);
        cfgTs.trl=[datadFF.time(ind1)' datadFF.time(ind2)' cfgTs.trl(:,3:5)]; %is cfgTs.trl supposed to be 5 columns instead of 6 now?
        cfgLfp.trl=[ind1' ind2' cfgLfp.trl(:,3:5)];
        
        %for first video:
        %     rm=find(cfgLfp.trl(:,1)<=1);
        %     cfgLfp.trl(rm,:)=[];  cfgTs.trl(rm,:)=[];
        if isempty(cfgLfp.trl), continue, end
        
        numVideos=length(datadFF.imageInd(:,1));
        
        %check end point
        rm=[];
        lastsitting=find(cfgLfp.trl(:,4)==0 & cfgLfp.trl(:,2)<datadFF.imageInd(end,2),1,'last');
        if lastsitting<size(cfgLfp.trl,1)
            rm=lastsitting+1:size(cfgLfp.trl,1);
        end
        cfgLfp.trl(rm,:)=[];
        cfgTs.trl(rm,:)=[];
        save(outputFilename, 'cfgTs', 'cfgLfp');
    end
end
end

function [ib]=resampleState(a,b)
% resamples state times (a) so in terms of Ca times (b)
% returns indices for these state times
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
