function Katie_lev1_wheel_changepoints(dirsel,overwrite)

% Katie_lev1_wheel_changepoints finds the wheel transitions based on the
% standard deviation of the speed.

% inputs: dirsel, vector of integers from 1:length(number of directories)
%         overwrite, 0 or 1 indicating if you want to overwrite previously done analysis
%
% output: saves the struct dataChpt with the following fields in a folder with the same name as your input directory:
%
%         time,  all timepoints based on sampling frequnecy and wheel trace
%         wheel, wheel trace (from lev0_read_wheel)
%         dist,  unwrapped wheel = distance travelled
%         spd,   the speed of the wheel
%         movSDSpd,  the standard deviation of the speed
%         wOn,   the indices of the wheel on transition points
%         wOff,  the indices of the wheel off transition points
%         trl_label, cell array labeling the columns of cfgTs.trl and cfgLfp.trl
%         params, the parameters used for analysis
%
%         it also saves the separate variables:
%         cfgLfp.trl, matrix of indices for total number of transition points(n), size= n x 5. Each col: 'beg', 'end', 'offset', 'on_off', 'mean_speed'
%         cfgTs.trl,  same as cfgLfp but in time.   on_off = 1 for L, 0 for Q

% Katie Ferguson, Yale University, 2020


tic

global info
global outputDirCardin
input    = 'lev0_readwheel';
analysis = 'lev1_wheel_changepoints';
nDirs = length(info);

% threshold parameters for detection of wheel
% movSDthresh = 0.1;   % moving standard deviation of speed threshold (default)
% mnSpdThresh = 0.4;   % mean speed threshold  (default)

movSDthresh = 0.1; %Stefan's trying to figure out better threshold
mnSpdThresh = 0.5; %Stefan's trying to figure out better threshold

% min length of running (L) or sitting (Q) bouts
minLlen = 1;  % seconds
minQlen = 2;  % seconds

diameter = 15.24; % diameter of wheel
gaussWinSz = 0.5; % seconds

% artifact detection parameters
artThresh = 50;
artWin = 1;

if nargin<2
    dirsel = 1:nDirs;
end

for iDir = dirsel
    exptag = info(iDir).dir;
    mouse = exptag(1:6);
    outputDir = fullfile(outputDirCardin, analysis, mouse, exptag);
    mkdir(outputDir);
    dataDir       = fullfile(outputDirCardin, input, mouse, exptag);
    outputFilename = fullfile(outputDir,exptag);
    if exist([outputFilename '.mat'], 'file') && overwrite==0
        fprintf('skipping %s file %s \n', info(iDir).dir,outputFilename), continue,end
    
    fprintf('Processing %s\n', outputFilename);
    
    % load the wheel data
    load(fullfile(dataDir, exptag), 'dataWheel')
    
    fs = info(iDir).fsample;    % sampling frequency
    mx = nanmax(dataWheel.trial{1});
    mn = nanmin(dataWheel.trial{1});
    
    dataWheel.trial{1} = dataWheel.trial{1} - mn;
    wheel  = 2*pi*dataWheel.trial{1}./(mx-mn) - pi;
    time = dataWheel.time{1};
    
    
    % wheel sampled at transition will give artifact because of high sampling
    % rate. Eliminate
    rev = abs(diff(wheel)) > 1;
    artStart = find(diff(rev) == 1); artEnd = find(diff(rev) == -1);
    
    % makes sure than beginning are always followed by an end
    if ~isempty(artStart)
        if artStart(1) > artEnd(1); artEnd(1) = []; end
        if artStart(end) > artEnd(end); artStart(end) = []; end
    end
    
    
    
    % window around wheel rotation
    artStartPre = max(artStart - round(0.025 * fs),1);
    artEndPost  = min(artEnd + round(0.025 * fs),length(wheel));
    [~,startidx]= arrayfun(@(x,y) max(wheel(x:y)),artStartPre,artStart);   % in our window, the ind of the actual max and min
    [~,endidx]  = arrayfun(@(x,y) min(wheel(x:y)),artEnd,artEndPost);
    artStart    = artStartPre + startidx - 1 ;   % max pt ind
    artEnd      = artEnd  + endidx - 1 ;   %  min pt ind
    
    artMid      = round(mean([artStart; artEnd]));
    
    % set all the middle values to pi or -pi
    for iChgPt = 1:length(artStart)
        wheel(artStart(iChgPt):artMid(iChgPt)) = pi*sign(wheel(artStart(iChgPt)));
        wheel(artMid(iChgPt)+1:artEnd(iChgPt)) = pi*sign(wheel(artEnd(iChgPt)));
    end
    
    
    dist = unwrap(wheel);
    dist = (dist - dist(1))*diameter/4;   % dist in cm.  2 rot from -pi:pi = 1 wheel rotation
    
    % Invert if sensor is backward
    if dist(end) < dist(1)
        dist = - dist;
    end
    
    % find speed with moving gaussian
    gwin = gausswin(fs*gaussWinSz);
    spd = conv(diff([dist(1), dist])*fs, gwin, 'same')./sum(gwin);     % in cm/s
    
    
    % remove obvious artifacts
    [pks,locs] = findpeaks(spd,'MinPeakProminence',artThresh);
    a = find(pks>1);
    pks = -pks(a);
    locs = locs(a);
    
    for ii = 1:length(locs)
        mnLocs = max(1,locs(ii)-round(artWin*fs));
        mxLocs = min(length(time),locs(ii)+round(artWin*fs));
        spd(mnLocs : mxLocs) = medfilt1(spd(mnLocs : mxLocs),fs);
    end
    
    % moving standard deviation of speed
    
    movSDSpd = movstd(spd,fs*gaussWinSz);
    
    chgPt = abs(movSDSpd) > movSDthresh;
    wOn   = find(diff(chgPt) == 1);
    wOff  = find(diff(chgPt) == -1);
    
    if ~isempty(wOn) && ~isempty(wOff)
        % make same length
        if wOff(1) <= wOn(1)
            wOn = [1 wOn];
        end
        if wOff(end) <= wOn(end)
            wOff = [wOff length(wheel)];
        end
        
        
        %Removes transitions that are too short
        rm = find(wOff - wOn <= minLlen*fs);
        wOn(rm) = [];
        wOff(rm) = [];
        rm = find(wOn(2:end)- wOff(1:end-1) <= minQlen*fs);
        wOn(rm+1) = [];
        wOff(rm) = [];
        
    end
    
    % removes transitions that don't pass mean speed test
    rm = []; mnSpd = zeros(size(wOn)); mnSpdQ = zeros(size(wOn));
    for ichpt = 1:length(wOn)
        mnSpd(ichpt) = mean(spd(wOn(ichpt):wOff(ichpt)));
        if mnSpd (ichpt)< mnSpdThresh
            rm = [rm ichpt];
        end
        if ichpt < length(wOn)
            mnSpdQ(ichpt) = mean(spd(wOff(ichpt):wOn(ichpt+1)));
        end
    end
    
    wOn(rm) = [];          wOff(rm) = [];          mnSpd(rm) = [];           mnSpdQ(rm) = [];
    
    
    % stateInd indicates which state
    if ~isempty(wOn) && ~isempty(wOff)
        if wOn(1)<wOff(1)
            stateInd = [ones(1,length(wOn));zeros(1,length(wOff))];
            mnSpdTot = [mnSpd; mnSpdQ];
        else
            stateInd = [zeros(1,length(wOff));ones(1,length(wOn)),];
            mnSpdTot = [mnSpdQ,mnSpd];
        end
        
        stateInd = reshape(stateInd,1,[])';
        mnSpdTot = reshape(mnSpdTot,1,[])'; % mean speed
        
        cfgLfp.trl = zeros(length(wOn)*2, 5);
        
        wTrans = [wOn; wOff];
        cfgLfp.trl(:,1) = wTrans(:);
        
        %cfgLfp.trl(cfgLfp.trl(:,1)>=length(wheel),:)=[]; %find if wTrans somehow goes past the length of Wheel
        
        
        cfgLfp.trl(1:end-1,2) = cfgLfp.trl(2:end,1)+1;
        cfgLfp.trl(end,2) = length(wheel);
        
        cfgLfp.trl(:,4:5) = [stateInd, mnSpdTot];
        
        
        %get an error when wTrans(:) ends with same value as length(wheel)
        %made solution currently to prevent either column going past length(wheel)
        cfgLfp.trl(cfgLfp.trl(:,1)>=length(wheel),:)=[]; %solution part 1 is remove any rows where 1st column past length(wheel)
        cfgLfp.trl(cfgLfp.trl(:,2)>length(wheel),2)=length(wheel); %solution part 2 is then to make sure end of column 2 is length(wheel)
        
        cfgTs.trl = cfgLfp.trl;
        
        cfgTs.trl(:,1:2) = [time(cfgLfp.trl(:,1))', time(cfgLfp.trl(:,2))']; %where error would occur
    else
        cfgLfp.trl = [1 length(wheel) 0 0 0];
        cfgTs.trl = [time(1) time(end) 0 0 0];
    end
    
    cfgLfp.trl_label = {'beg', 'end', 'offset', 'on_off', 'mean_speed'};
    
    dataChpt.time  = time;
    dataChpt.wheel = wheel;
    dataChpt.dist  = dist;
    dataChpt.spd   = spd;
    dataChpt.movSDspd = movSDSpd;
    dataChpt.wOn   = wOn;
    dataChpt.wOff  = wOff;
    dataChpt.trl_label = cfgLfp.trl_label;
    
    dataChpt.params.movSDthresh = movSDthresh;
    dataChpt.params.mnSpdThresh = mnSpdThresh;
    dataChpt.params.minLlen = minLlen;
    dataChpt.params.minQlen = minQlen;
    dataChpt.params.diameter = diameter;
    dataChpt.params.gaussWinSz = gaussWinSz;
    dataChpt.params.artThresh = artThresh;
    dataChpt.params.artWin = artWin;
    
    % save the output
    save(outputFilename, 'cfgTs', 'cfgLfp', 'dataChpt');
    
    clear time wheel dist spd movSDSpd wOn wOff cfgLfp cfgTs dataWheel dataChpt
    
    
end

toc

% plot
% figure, ax(1) = subplot(311); plot(wheel); hold on;
% plot([wOn; wOn],[-pi*ones(size(wOn)); pi*ones(size(wOn))],'c','linewidth',2)
% hold on;
% plot([wOff; wOff],[-pi*ones(size(wOff)); pi*ones(size(wOff))],'m','linewidth',2)

% ax(2) = subplot(312);
% plot(dist); hold on;
% plot([wOn; wOn],[min(dist)*ones(size(wOn)); max(dist)*ones(size(wOn))],'c','linewidth',2)
% hold on;
% plot([wOff; wOff],[min(dist)*ones(size(wOff)); max(dist)*ones(size(wOff))],'m','linewidth',2)
%
% ax(3) = subplot(313);  plot(spd); hold on;
% plot([wOn; wOn],[-10*ones(size(wOn)); 30*ones(size(wOn))],'c','linewidth',2)
% hold on;
% plot([wOff; wOff],[-10*ones(size(wOff)); 30*ones(size(wOff))],'m','linewidth',2)
%
% linkaxes(ax,'x');

% plot only first few data
% startTime = 600;
% EndTime = 700;
% v=movSDSpd;
%
% figure;
% plot(linspace(startTime,EndTime,(EndTime-startTime)*fs+1),v(startTime*fs:EndTime*fs)); hold on;
% wstart = find(wOn<startTime*fs,1,'last');
% wend = find(wOff>EndTime*fs,1);
% plot([wOn(wstart:wend)./5000; wOn(wstart:wend)./5000],[min(v(startTime*fs:EndTime*fs))*ones(1,wend-wstart+1); max(v(startTime*fs:EndTime*fs))*ones(1,wend-wstart+1)],'c','linewidth',2)
% hold on;
% plot([wOff(wstart:wend)./5000; wOff(wstart:wend)./5000],[min(v(startTime*fs:EndTime*fs))*ones(1,wend-wstart+1); max(v(startTime*fs:EndTime*fs))*ones(1,wend-wstart+1)],'m','linewidth',2)


%     figure
%     plot(db1Time, db1SpeedMpS, 'k'), db1YL = ylim;
%     hold on,
%     for ii = 1:length(in1OnIdx)
%         plot(db1Time([in1OnIdx(ii) in1OnIdx(ii)]), db1YL, 'g')
%     end
%     for ii = 1:length(in1OffIdx)
%         plot(db1Time([in1OffIdx(ii) in1OffIdx(ii)]), db1YL, 'r')
%     end



