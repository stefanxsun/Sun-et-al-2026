%% use to plot each mouse, VEHA MUA specific

%Defines the info file and get the sessions for which the protocol exist
for j=1:7                                       %%%%%%%%%%% speical edited line 02/02/2025
    clearvars -except j
    close all
    cd 'E:\Ephy\VisExpHighAll';
    chSessionDir 	= 'VEHA_L5_MUA_StimuliAverage';
    chFileName 		= [chSessionDir '.mat'];
    chFigDir 		= fullfile('Figure', chSessionDir); if ~exist(chFigDir, 'dir'); mkdir('Figure', chSessionDir); end
    blVisible 		= 1;
    sDIR 			= dir(chSessionDir);
    
    %Sets the bands
    cLyr = {'23','4','5','6','ALL'};
    inNLyr 		= length(cLyr);
    
    sINFO 		= VEHA_DefineINFO();
    sINFO.sREC=sINFO.sREC((j-1)*7+1:j*7);   %%%%%%%%%%% speical edited line 02/02/2025
    
    in1Session  = find(~isnan(VEHA_U_FindSessionIndex(sINFO, {sDIR(:).name})));
    in1InfoIdx  = VEHA_U_FindSessionIndex(sINFO, {sDIR(in1Session).name});
    in1Day      = VEHA_U_FindSessionDayNum(sINFO, chSessionDir);
    in1Day      = in1Day(in1InfoIdx);
    in1Mouse    = [sINFO.sREC.inMouseID];
    chFigDir = fullfile(chFigDir,['mouse' num2str(j)]); %%%%%%%%%%% speical edited line 02/02/2025
    in1Mouse    = in1Mouse(in1InfoIdx);
    [MouseNum,~,MouseSeq] = unique(in1Mouse);
    
    % Initializes sCOND
    [db2SesCond, db3FR, db3zFR, in1SesDay, in1SesMouse] = deal([]);
    [FRCndQLf, FRCndQHf, FRCndL, zFRCndQLf, zFRCndQHf, zFRCndL] = deal([]); %% ADDED by STEFAN
    FRAllTrial={}; zFRAllTrial={};
    % Aggregates the data
    fprintf('Aggregating data... ')
    
    alltrace=cell(in1Day(end),MouseSeq(end));
    chanLayer = cell(in1Day(end),MouseSeq(end));
    
    BasFR = cell(length(unique(in1Mouse)),length(unique(in1Day)));
    BasFR_SD= cell(length(unique(in1Mouse)),length(unique(in1Day)));
    
    for iSes = 1:length(in1Session)
        try
            sLD = load(fullfile(chSessionDir, sDIR(in1Session(iSes)).name, chFileName)); % loads the file
            fns = fieldnames(sLD.sLyr(1).sCONDState);
            
            %%% get the baseline firing rate
            for iLyr = 1:inNLyr
                BasFRtemp(iLyr)	= sLD.sLyr(iLyr).BasFR;  %#ok<*SAGROW>
                BasFR_SDtemp(iLyr) 	= sLD.sLyr(iLyr).BasFR_SD;
            end
            BasFR{MouseSeq(iSes),in1Day(iSes)}  =  BasFRtemp;
            BasFR_SD{MouseSeq(iSes),in1Day(iSes)}  =  BasFR_SDtemp;
            
            for iCnd = 1:size(sLD.db2Cond, 2)
                % Aggregates pulse rate for each condition
                db2SesCond     	= cat(1, db2SesCond, sLD.db2Cond(:, iCnd)');
                [db2FR, db2zFR] = deal(nan(1, inNLyr));
                repNum = length(sLD.sLyr(1).sCONDTrial(1).FR);  %% ADDED by STEFAN
                
                FRAllTrialCnd = cell(inNLyr,1);          %%%%%%%%% Stefan added 11/14/2023 for all trials
                zFRAllTrialCnd = cell(inNLyr,1);
                
                [FRState, zFRState] = deal(nan(3, inNLyr)); %%%%%%% Stefan added, state dependent, 11/27/2022
                
                for iLyr = 1:inNLyr
                    db2FR(iLyr) 	= sLD.sLyr(iLyr).sCOND(iCnd).FR;
                    db2zFR(iLyr) 	= sLD.sLyr(iLyr).sCOND(iCnd).Z_FR;
                    
                    FRAllTrialCnd{iLyr,1} = sLD.sLyr(iLyr).sCONDTrial(iCnd).FR;
                    zFRAllTrialCnd{iLyr,1} = sLD.sLyr(iLyr).sCONDTrial(iCnd).Z_FR;
                    
                    for istate =1:3
                        FRState(istate,iLyr) 	= sLD.sLyr(iLyr).sCONDState(iCnd).(fns{istate*2-1});
                        zFRState(istate,iLyr) 	= sLD.sLyr(iLyr).sCONDState(iCnd).(fns{istate*2});
                    end
                end
                
                Trialmatrix = cell2mat(FRAllTrialCnd);
                Trialmatrix = cell2mat(zFRAllTrialCnd);
                
                db3FR 		= cat(3, db3FR, db2FR);
                db3zFR 		= cat(3, db3zFR, db2zFR);
                FRAllTrial   = cat(1, FRAllTrial, FRAllTrialCnd);%%%%%%%%% Stefan added 11/14/2023 for all trials
                zFRAllTrial  = cat(1, zFRAllTrial, zFRAllTrialCnd);%%%%%%%%% Stefan added 11/14/2023 for all trials
                FRCndQLf 	= cat(3, FRCndQLf, FRState(1,:));%%%%%%% Stefan added, state dependent, 11/27/2022
                FRCndQHf 	= cat(3, FRCndQHf, FRState(2,:));%%%%%%% Stefan added, state dependent, 12/16/2022
                FRCndL    	= cat(3, FRCndL, FRState(3,:));%%%%%%% Stefan added, state dependent, 11/27/2022
                zFRCndQLf 	= cat(3, zFRCndQLf, zFRState(1,:));%%%%%%% Stefan added, state dependent, 11/27/2022
                zFRCndQHf 	= cat(3, zFRCndQHf, zFRState(2,:));%%%%%%% Stefan added, state dependent, 12/16/2022
                zFRCndL 	    = cat(3, zFRCndL, zFRState(3,:));%%%%%%% Stefan added, state dependent, 11/27/2022
                in1SesDay       = cat(1, in1SesDay, in1Day(iSes));
                in1SesMouse     = cat(1, in1SesMouse, in1Mouse(iSes));
            end
            
            % Aggregates pulse rate for baseline  %%%Not needed since it is not used anyway (Stefan) Also not fully edited
            %       db2SesCond     	= cat(1, db2SesCond, nan(1, size(db2SesCond, 2)));
            % 		db2FR = deal(nan(1, inNLyr));
            % 		for iLyr = 1:inNLyr
            % 			bl1Lyr = ismember({sLD.sLyr(1, :).LayerLabel}, cLyr(iLyr));
            % 			if ~any(bl1Lyr), continue; end
            % 			db2FR(bl1Lyr) 	= sLD.sLyr(bl1Lyr).BasFR;
            % 		end
            % 		db3FR 		= cat(3, db3FR, db2FR);
            % 		db3zFR 		= cat(3, db3zFR, zeros(1, inNLyr));
            %       in1SesDay   	= cat(1, in1SesDay, in1Day(iSes));
            %       in1SesMouse     = cat(1, in1SesMouse, in1Mouse(iSes));
            
            %%%%%%% Stefan added, state dependent, 11/27/2022, edited 12/16/2022
            %         FRCndQLf    = cat(3, FRCndQLf, db2FR);
            %         FRCndQHf    = cat(3, FRCndQHf, db2FR);
            %         FRCndL      = cat(3, FRCndL, db2FR);
            %         zFRCndQLf   = cat(3, zFRCndQLf, zeros(1, inNLyr));
            %         zFRCndQHf   = cat(3, zFRCndQHf, zeros(1, inNLyr));
            %         zFRCndL     = cat(3, zFRCndL, zeros(1, inNLyr));
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%three dimesions in the order of: SF, Sz, Ctr
            alltrace{in1Day(iSes),MouseSeq(iSes)}= sLD.alltrace;  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       ADDED by STEFAN
            
            chanLayer{in1Day(iSes),MouseSeq(iSes)}= sLD.chanLayer;  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       ADDED by STEFAN
            
            %%%%%%%%%%%%
            %         FRAllTrialCnd{1,1} = ones(1,repNum)*db2FR(1);
            %         FRAllTrialCnd{1,2} = ones(1,repNum)*db2FR(2);
            %         zFRAllTrialCnd{1,1} = zeros(1,repNum);
            %         zFRAllTrialCnd{1,2} = zeros(1,repNum);
            %         FRAllTrial   = cat(1, FRAllTrial, FRAllTrialCnd);%%%%%%%%% Stefan added 11/14/2023 for all trials, might worth double check
            %         zFRAllTrial  = cat(1, zFRAllTrial, zFRAllTrialCnd);%%%%%%%%% Stefan added 11/14/2023 for all trials
            
            
        catch ME
            getReport(ME)
        end
    end
    
    stateFolder = 'Allstate';
    NS_L5_MUA_StimuliAverage_Plot(in1SesDay, in1SesMouse, db2SesCond, ...
        db3FR, db3zFR, cLyr, blVisible, chFigDir, stateFolder);
end