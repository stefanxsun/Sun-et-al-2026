%% use to plot each mouse, VEHA beta power specific

%Defines the info file and get the sessions for which the protocol exist
for j=1:7                                       %%%%%%%%%%% speical edited line 02/02/2025
    clearvars -except j
    close all
    cd 'E:\Ephy\VisExpHighAll';
    chSessionDir 	= 'VEHA_L5_Hilbert_SFrCtrSSz';
    chFileName 		= [chSessionDir '.mat'];
    chFigDir 		= fullfile('Figure', chSessionDir); if ~exist(chFigDir, 'dir'); mkdir('Figure', chSessionDir); end
    chFigDir = fullfile(chFigDir,['mouse' num2str(j)]); %%%%%%%%%%% speical edited line 02/02/2025

    blVisible 		= 1;
    sDIR 			= dir(chSessionDir);
    
    %Sets the bands
    cBAND 		= {'15-30Hz', '30-80Hz'};
    inNBnd 		= length(cBAND);
    
    sINFO 		= VEHA_DefineINFO();
    sINFO.sREC=sINFO.sREC((j-1)*7+1:j*7);   %%%%%%%%%%% speical edited line 02/02/2025
    
    in1Session  = find(~isnan(VEHA_U_FindSessionIndex(sINFO, {sDIR(:).name})));
    in1InfoIdx  = VEHA_U_FindSessionIndex(sINFO, {sDIR(in1Session).name});
    in1Day      = VEHA_U_FindSessionDayNum(sINFO, chSessionDir);
    in1Day      = in1Day(in1InfoIdx);
    in1Mouse    = [sINFO.sREC.inMouseID];
    in1Mouse    = in1Mouse(in1InfoIdx);
    [MouseNum,~,MouseSeq] = unique(in1Mouse);
    
    % Initializes sCOND
    [db2SesCond, db3Power, db3Z_Power, in1SesDay, in1SesMouse] = deal([]);
    [PowerCndQLf, PowerCndQHf, PowerCndL, ZPowerCndQLf, ZPowerCndQHf, ZPowerCndL] = deal([]); %% ADDED by STEFAN
    PowerAllTrial={}; ZPowerAllTrial={};
    % Aggregates the data
    fprintf('Aggregating data... ')
    
    alltrace=cell(in1Day(end),MouseSeq(end));
    chanLayer = cell(in1Day(end),MouseSeq(end));
    
    for iSes = 1:length(in1Session)
        %     try
        sLD = load(fullfile(chSessionDir, sDIR(in1Session(iSes)).name, chFileName)); % loads the file
        fns = fieldnames(sLD.sBAND(1).sCONDState);
        for iCnd = 1:size(sLD.db2Cond, 2)
            % Aggregates pulse rate for each condition
            db2SesCond     	= cat(1, db2SesCond, sLD.db2Cond(:, iCnd)');
            [db2Power, db2Z_Power] = deal(nan(1, inNBnd));
            repNum = length(sLD.sBAND(1).sCONDTrial(1).dbPower);  %% ADDED by STEFAN
            
            PowerAllTrialCnd = cell(1,2);          %%%%%%%%% Stefan added 11/14/2023 for all trials
            ZPowerAllTrialCnd = cell(1,2);
            
            [PowerState, ZPowerState] = deal(nan(3, inNBnd)); %%%%%%% Stefan added, state dependent, 11/27/2022
            
            for iBnd = 1:inNBnd
                bl1Bnd = ismember({sLD.sBAND(1, :).chBandLabel}, cBAND(iBnd));
                if ~any(bl1Bnd), continue; end
                db2Power(bl1Bnd) 	= sLD.sBAND(bl1Bnd).sCOND(iCnd).dbPower;
                db2Z_Power(bl1Bnd) 	= sLD.sBAND(bl1Bnd).sCOND(iCnd).dbZ_Power;
                
                %%%%%%%%% Stefan added 11/14/2023 for all trials
                PowerAllTrialCnd{1,bl1Bnd} = sLD.sBAND(bl1Bnd).sCONDTrial(iCnd).dbPower;
                ZPowerAllTrialCnd{1,bl1Bnd} = sLD.sBAND(bl1Bnd).sCONDTrial(iCnd).dbZ_Power;
                
                %%%%%%%%%%%%%% Stefan added, state dependent, 11/27/2022
                for istate =1:3
                    PowerState(istate,bl1Bnd) 	= sLD.sBAND(bl1Bnd).sCONDState(iCnd).(fns{istate*2-1});
                    ZPowerState(istate,bl1Bnd) 	= sLD.sBAND(bl1Bnd).sCONDState(iCnd).(fns{istate*2});
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
            db3Power 		= cat(3, db3Power, db2Power);
            db3Z_Power 		= cat(3, db3Z_Power, db2Z_Power);
            PowerAllTrial   = cat(1, PowerAllTrial, PowerAllTrialCnd);%%%%%%%%% Stefan added 11/14/2023 for all trials
            ZPowerAllTrial  = cat(1, ZPowerAllTrial, ZPowerAllTrialCnd);%%%%%%%%% Stefan added 11/14/2023 for all trials
            PowerCndQLf 	= cat(3, PowerCndQLf, PowerState(1,:));%%%%%%% Stefan added, state dependent, 11/27/2022
            PowerCndQHf 	= cat(3, PowerCndQHf, PowerState(2,:));%%%%%%% Stefan added, state dependent, 12/16/2022
            PowerCndL    	= cat(3, PowerCndL, PowerState(3,:));%%%%%%% Stefan added, state dependent, 11/27/2022
            ZPowerCndQLf 	= cat(3, ZPowerCndQLf, ZPowerState(1,:));%%%%%%% Stefan added, state dependent, 11/27/2022
            ZPowerCndQHf 	= cat(3, ZPowerCndQHf, ZPowerState(2,:));%%%%%%% Stefan added, state dependent, 12/16/2022
            ZPowerCndL 	    = cat(3, ZPowerCndL, ZPowerState(3,:));%%%%%%% Stefan added, state dependent, 11/27/2022
            in1SesDay       = cat(1, in1SesDay, in1Day(iSes));
            in1SesMouse     = cat(1, in1SesMouse, in1Mouse(iSes));
        end
        
        % Aggregates pulse rate for baseline
        db2SesCond     	= cat(1, db2SesCond, nan(1, size(db2SesCond, 2)));
        db2Power = deal(nan(1, inNBnd));
        for iBnd = 1:inNBnd
            bl1Bnd = ismember({sLD.sBAND(1, :).chBandLabel}, cBAND(iBnd));
            if ~any(bl1Bnd), continue; end
            db2Power(bl1Bnd) 	= sLD.sBAND(bl1Bnd).dbBasPower;
        end
        db3Power 		= cat(3, db3Power, db2Power);
        db3Z_Power 		= cat(3, db3Z_Power, zeros(1, inNBnd));
        in1SesDay   	= cat(1, in1SesDay, in1Day(iSes));
        in1SesMouse     = cat(1, in1SesMouse, in1Mouse(iSes));
        %%%%%%% Stefan added, state dependent, 11/27/2022, edited 12/16/2022
        PowerCndQLf    = cat(3, PowerCndQLf, db2Power);
        PowerCndQHf    = cat(3, PowerCndQHf, db2Power);
        PowerCndL      = cat(3, PowerCndL, db2Power);
        ZPowerCndQLf   = cat(3, ZPowerCndQLf, zeros(1, inNBnd));
        ZPowerCndQHf   = cat(3, ZPowerCndQHf, zeros(1, inNBnd));
        ZPowerCndL     = cat(3, ZPowerCndL, zeros(1, inNBnd));
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        alltrace{in1Day(iSes),MouseSeq(iSes)}= sLD.alltrace;  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       ADDED by STEFAN
        chanLayer{in1Day(iSes),MouseSeq(iSes)}= sLD.chanLayer;  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       ADDED by STEFAN
        
        %%%%%%%%%%%%
        PowerAllTrialCnd{1,1} = ones(1,repNum)*db2Power(1);
        PowerAllTrialCnd{1,2} = ones(1,repNum)*db2Power(2);
        ZPowerAllTrialCnd{1,1} = zeros(1,repNum);
        ZPowerAllTrialCnd{1,2} = zeros(1,repNum);
        PowerAllTrial   = cat(1, PowerAllTrial, PowerAllTrialCnd);%%%%%%%%% Stefan added 11/14/2023 for all trials, might worth double check
        ZPowerAllTrial  = cat(1, ZPowerAllTrial, ZPowerAllTrialCnd);%%%%%%%%% Stefan added 11/14/2023 for all trials
        
        
        %     catch ME
        %         getReport(ME)
        %     end
    end
    
    stateFolder = 'Allstate';
    NS_L5_Hilbert_SFrCtrSSz_Plot(in1SesDay, in1SesMouse, db2SesCond, ...
        db3Power, db3Z_Power, cBAND, blVisible, chFigDir, stateFolder);
end