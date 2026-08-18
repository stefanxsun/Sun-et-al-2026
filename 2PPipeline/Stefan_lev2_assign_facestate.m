function Stefan_lev2_assign_facestate(dirsel,overwrite)
%%%%%% This code is for assigning each trial into one of the quartiles
%%%%%% based on facemap behavioral state. 
%%%%%% Need input: lev0_face, lev0_readvis, lev3_vis_state_visdFF, facemap data
%%%%%% Wrote by Stefan Sun, 2021/09/15
global outputDirCardin
global info

inputFace    = 'lev0_face';
inputState    =  'lev3_vis_state_visdFF';
inputVis   = 'lev0_readvis';
inputFacemap = 'facemapoutput';
analysis = 'lev2_assign_facestate';

for iDir = dirsel
    exptag = info(iDir).dir;
    mouse = exptag(1:6);
    outputDir = fullfile(outputDirCardin, analysis, mouse, exptag);
    mkdir(outputDir);
    outputFilename = fullfile(outputDir,exptag);
    if exist([outputFilename '.mat'], 'file') && overwrite==0
        fprintf('skipping %s file %s \n', info(iDir).dir,outputFilename), continue,end
    fprintf('Processing %s\n', outputFilename);
    
    dataDirFace = fullfile(outputDirCardin, inputFace, mouse, exptag);
    dataDirState = fullfile(outputDirCardin, inputState, mouse, exptag);
    dataDirVis = fullfile(outputDirCardin, inputVis, mouse, exptag);
    dataDirFacemap = fullfile('F:\face', inputFacemap, mouse);
    
    load(fullfile(dataDirFace, exptag))
    load(fullfile(dataDirState, exptag))
    load(fullfile(dataDirVis, exptag))
    facedir = dir(dataDirFacemap);
    for i=3:length(facedir)
        if strcmp(facedir(i).name(1:14),exptag)
            break
        end
    end
    facemap = load(fullfile(dataDirFacemap, facedir(i).name),'motSVD_1');
    facemapSVD = facemap.motSVD_1;
    facemapSVDmean = mean(facemapSVD(:,1:5),2);  %% arbiturary taking the first 5 SVD
    facemapMovStd = movstd(facemapSVDmean,5);  %%after testing, this is the best, Stefan Edited 06/24/2025
    
    facetime=dataPupil.Timestamp;
    quart=quantile(facemapMovStd,3);
    %% Calculate z score by bottom 10% and get quartile threshhold (old way )
    
%     % get the baseline   
%     sortface=sort(facemap);
%     baseline=sortface(1:round(0.1*length(sortface)));
%     zface=(facemap-mean(baseline))/std(baseline);
%     
%     quart=quantile(zface,3);
    
    %% Calculate the mean in stimulus on 2 seconds, of all trials
    
    faceTrial=zeros(length(dataVis.visTime),60);
    
    for i =1:length(dataVis.visTime)
        ind=find(facetime>dataVis.visTime(i,1),1);
        faceTrial(i,:)=facemapMovStd(ind-20:ind+39);  %% this would be 6 seconds?
    end
    
    %% Calculate the mean in stimulus on 2 seconds, of only quiescense trials
    
    faceTrialQ=zeros(length(stateVis{1, 2}.stimTimes),60);
    
    for i =1:length(faceTrialQ)
        ind=find(facetime>stateVis{1, 2}.stimTimes (i,1),1);
        faceTrialQ(i,:)=facemapMovStd(ind-20:ind+39);
    end
    
    
    %% Divide the trials
    % try out multiple methods
    
    faceTrialmean=mean(faceTrial(:,21:40),2);            % mean facemap value of the 20 frames during stim onset
    faceTrialmeanQ=mean(faceTrialQ(:,21:40),2);          % for quiescence state
    
    qt(:,1)= arrayfun(@(x)quar(x,quart),faceTrialmean);         % the quartile assigned based on the mean of facemap within 20 frames of stim onset
    qtQ = arrayfun(@(x)quar(x,quart),faceTrialmeanQ);    % for quiescence state
    
    faceTrialq = arrayfun(@(x)quar(x,quart),faceTrial);     % the quartile assigned for each frame
    qt(:,2)=mean(faceTrialq,2);        % the mean of the quartile of 20 frames during stim onset
    
    qt(:,3)=mode(faceTrialq,2);        % the mode of the quartile of 20 frames during stim onset
    
    
    %% save
    stimtime=dataVis.visTime;
    save(outputFilename,'qt','qtQ', 'faceTrial','faceTrialQ', 'facetime','facemapMovStd','stimtime');
    
end
end


%%  function for assigning each trial into a quartile 
function y = quar(x,quart)
if x<= quart(1); y=1; end
if x>quart(1)&& x<=quart(2); y=2; end
if x>quart(2)&& x<=quart(3); y=3; end
if x>quart(3); y=4;end
end




        