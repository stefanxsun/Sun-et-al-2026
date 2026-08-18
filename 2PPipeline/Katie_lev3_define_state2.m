function Katie_lev3_define_state2(cfgMaster,dirsel,overwrite)
% KATIE_LEV2_DEFINE_STATE2 creates time bounds for what is acceptable to define
% the quiet and locomotion states. Breaks into six states based on original
% definitions: 'LE','LL','QE','QM','QL','A'.  Will redo.

% Katie Ferguson, Yale University, 2016


global info
global outputDirCardin
%inputAir    = 'lev0_readair';
inputCa    = 'lev1_align_caframes';
inputState    = 'lev2_align_state';
analysis = 'lev3_define_state';
nDirs = length(info);

LEmax=30;%5;
Qmin=5; %must be at least Qmin seconds in quiescence
QEmax=40;
QMmax=45;
A=5; %anticipatory window (-A seconds from Lon). Only exists if Q>QMmax

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
    dirList = {dirInfoCa,dirInfoState};
    dirLength = [length(dirInfoCa),length(dirInfoState)];
    [nFiles,smallDirInd]  = min(dirLength);
    
    for iFile = 1:nFiles
        if isempty(strfind(dirList{smallDirInd}(iFile).name, '.mat')), continue,end  %spk2 file
        cnt = cnt + 1;
        names{cnt}     = dirList{smallDirInd}(iFile).name;
        fileNamesCa{cnt} = fullfile(dataDirCa, dirList{smallDirInd}(iFile).name);
        fileNamesState{cnt} = fullfile(dataDirState, dirList{smallDirInd}(iFile).name);
    end
    
    for iFile = 1:length(fileNamesCa)
        fprintf('Processing %s\n', fileNamesCa{iFile});
        
        outputFilename = fullfile(outputDir,names{iFile}(1:end-4));
        if exist([outputFilename '.mat'], 'file') && overwrite==0
            fprintf('skipping %s file %s \n', info(iDir).dir,outputFilename), continue,end
        
        %load the Ca data
        load(fileNamesCa{iFile})
        
        %load the Ca-aligned state data
        load(fileNamesState{iFile})
        
        %LE
        L_IndStart=find(cfgTs.trl(:,4)==1,1,'first');
        if isempty(L_IndStart)
            fprintf('No locomotion states in %s. Skipping. \n',outputFilename);
            continue,
        end
        
        
        dur=(cfgTs.trl(:,2)-cfgTs.trl(:,1));
        
        %LE is first LEmax seconds
        LEStartInd=cfgLfp.trl(L_IndStart:2:end,1);
        LEEndInd=cfgLfp.trl(L_IndStart:2:end,1)+round(LEmax*info(iDir).fcasample);
        LEcfgLfp.trl=[LEStartInd LEEndInd];
        
        %except if there are fewer than LEmax seconds in L
        if ~isempty(dur(L_IndStart:2:end)<=LEmax)
            durInd=find(dur(L_IndStart:2:end)<=LEmax);
            fulldurInd=(durInd*2)-1+(L_IndStart-1);
            for i=1:length(durInd)
                LEcfgLfp.trl(durInd(i),2)=cfgLfp.trl(fulldurInd(i),2);
            end
        end
        
        LEcfgTs.trl=datadFF.time(LEcfgLfp.trl);
        
        
        %LL
        LLcfgLfp.trl=[LEcfgLfp.trl(:,2)+1 cfgLfp.trl(L_IndStart:2:end,2)];
        LLcfgLfp.trl(LLcfgLfp.trl(:,2)<=LLcfgLfp.trl(:,1),:)=1; %trials with no LL set to 1 as placeholder
        LLcfgTs.trl=datadFF.time(LLcfgLfp.trl);
        LLcfgTs.trl(LLcfgLfp.trl(:,2)<=LLcfgLfp.trl(:,1),:)=0;  %set to time 0 when no LL
        
        %QE
        QEStartInd=cfgLfp.trl(L_IndStart+1:2:end,1);
        QEEndInd=cfgLfp.trl(L_IndStart+1:2:end,1)+round(QEmax*info(iDir).fcasample);
        QEcfgLfp.trl=[QEStartInd QEEndInd];
        
        %except if there are fewer in quiescence than QEmax
        if ~isempty(dur(L_IndStart+1:2:end)<=QEmax)
            durInd=find(dur(L_IndStart+1:2:end)<=QEmax);
            fulldurInd=(durInd*2)-1+(L_IndStart);
            for i=1:length(durInd)
                QEcfgLfp.trl(durInd(i),2)=cfgLfp.trl(fulldurInd(i),2);
            end
        end
        
        if isempty(QEcfgLfp.trl)
            fprintf('Q is empty in %s. Skipping. \n',outputFilename);
            continue
        end
        
        
        QEcfgLfp.trl(end,2)=min(QEcfgLfp.trl(end,2),max(cfgLfp.trl(:,2)));
        
        QEcfgTs.trl=datadFF.time(QEcfgLfp.trl);
        
        %QM
        QMStartInd=QEcfgLfp.trl(:,2)+1;
        QMEndInd=QMStartInd+round(QMmax*info(iDir).fcasample);
        QMcfgLfp.trl=[QMStartInd QMEndInd];
        
        %except if <QMmax but >QEmax, then just use end point
        durInd2=find(dur(L_IndStart+1:2:end)<=QMmax & dur(L_IndStart+1:2:end)>QEmax);
        fulldurInd2=(durInd2*2)-1+(L_IndStart);
        
        for i=1:length(durInd2)
            QMcfgLfp.trl(durInd2(i),2)=cfgLfp.trl(fulldurInd2(i),2);
        end
        
        QMcfgLfp.trl(end,2)=min(QMcfgLfp.trl(end,2),max(cfgLfp.trl(L_IndStart+1:2:end,2)));
        
        %QL
        QLStartInd=QMcfgLfp.trl(:,2)+1;
        QLEndInd=cfgLfp.trl(L_IndStart+1:2:end,2)-round(A*info(iDir).fcasample);  %end of q trial
        QLcfgLfp.trl=[QLStartInd QLEndInd];
        
        %define A and "remove" QL if <A seconds in QL (room for anticipatory)
        AStartInd=QLcfgLfp.trl(:,2)+1;
        AEndInd=cfgLfp.trl(L_IndStart+1:2:end,2);  %end of q trial
        AcfgLfp.trl=[AStartInd AEndInd];
        %if <A seconds, A ranges from QMmax to end
        Ashort=find(AcfgLfp.trl(:,1)>=AcfgLfp.trl(:,2));
        AcfgLfp.trl(Ashort,2)=cfgLfp.trl((Ashort*2)-1+(L_IndStart),2); %try endpt
        AcfgLfp.trl(AcfgLfp.trl(:,1)>=AcfgLfp.trl(:,2),:)=1;  %if still too short, "remove"
        AcfgLfp.trl([durInd;durInd2],:)=1;  %only have anticipatory if go to QMax
        AcfgTs.trl=datadFF.time(AcfgLfp.trl);
        AcfgTs.trl(AcfgLfp.trl==1)=0; %"remove"
        
        %remove if <QEmax
        QMcfgLfp.trl(durInd,:)=1;
        QMcfgLfp.trl(QMcfgLfp.trl>length(datadFF.time))=length(datadFF.time);
        QMcfgTs.trl=datadFF.time(QMcfgLfp.trl);
        QMcfgTs.trl(QMcfgLfp.trl==1)=0;
        
        %must also be at least Qmin seconds of Q
        QShortInd=find((QEcfgTs.trl(:,2)-QEcfgTs.trl(:,1))<Qmin);
        QEcfgTs.trl(QShortInd,:)=0; QEcfgLfp.trl(QShortInd,:)=1;
        
        QLcfgLfp.trl(QLStartInd>=QLEndInd,:)=1;
        QLcfgTs.trl=datadFF.time(QLcfgLfp.trl);
        QLcfgTs.trl(QLcfgLfp.trl==1)=0;
        
        %put into more usable structure
        cfgStateTs{1}=LEcfgTs;
        cfgStateTs{2}=LLcfgTs;
        cfgStateTs{3}=QEcfgTs;
        cfgStateTs{4}=QMcfgTs;
        cfgStateTs{5}=QLcfgTs;
        cfgStateTs{6}=AcfgTs;
        
        %or to access the whole running/quiet trace easily..
        cfgStateTs{7}.trl=(cfgTs.trl(cfgTs.trl(:,4)==1,1:2));
        cfgStateTs{8}.trl=(cfgTs.trl(cfgTs.trl(:,4)==0,1:2));
        
        cfgStateLfp{1}=LEcfgLfp;
        cfgStateLfp{2}=LLcfgLfp;
        cfgStateLfp{3}=QEcfgLfp;
        cfgStateLfp{4}=QMcfgLfp;
        cfgStateLfp{5}=QLcfgLfp;
        cfgStateLfp{6}=AcfgLfp;
        
        %or to access the whole running/quiet trace easily..
        cfgStateLfp{7}.trl=(cfgLfp.trl(cfgLfp.trl(:,4)==1,1:2));
        cfgStateLfp{8}.trl=(cfgLfp.trl(cfgLfp.trl(:,4)==0,1:2));
        
        cfgStateLabel={'LE','LL','QE','QM','QL','A','L','Q'};
        cfgStateDefn=[LEmax,QEmax,QMmax,Qmin,A];
        cfgStateDefnLabel={'LEmax','QEmax','QMmax','Qmin','A'};
        
        save(outputFilename, 'cfgStateTs','cfgStateLfp','cfgStateLabel','cfgStateDefn','cfgStateDefnLabel');
        clear cfgStateTs cfgStateLfp cfgStateLabel cfgStateDefn cfgStateDefnLabel
    end
end

