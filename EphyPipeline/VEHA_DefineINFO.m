function sINFO = VEHA_DefineINFO()

% global sINFO 
% clc; clear;
sINFO = struct();
sINFO.chBaseDirectory = 'E:\Ephy\VisExpHighAll';
sINFO.sREC = struct();
datamainDir = '\\kermit.med.yale.internal\kermit\Stefan\rawdata\Ephy';
visualfolder = '\\mind.med.yale.internal\mind-expansion\Data\Imaging\Stefan\visstim';
facefolder = 'E:\data\data\pupil';
idx=0;

%% automatic filling

dataFolderName  = 'VisExpHighAll';
dirInfo  = dir(fullfile(datamainDir,dataFolderName));  dirInfo([1 2],:)=[];
mouse= {dirInfo(:).name};
totalday = length(dir(fullfile(datamainDir,dataFolderName,mouse{1})))-2;
%same for all animals all sessions
for idx= 1:length(mouse)*totalday
    sINFO.sREC(idx).dbLFPChanSpacingMicron = 50;
    sINFO.sREC(idx).cLFPCHAN = {'CSC1.ncs', 'CSC2.ncs', 'CSC3.ncs', 'CSC4.ncs', ...
        'CSC5.ncs', 'CSC6.ncs', 'CSC7.ncs', 'CSC8.ncs', 'CSC9.ncs', 'CSC10.ncs', ...
        'CSC11.ncs', 'CSC12.ncs', 'CSC13.ncs', 'CSC14.ncs', 'CSC15.ncs', 'CSC16.ncs'};
    sINFO.sREC(idx).cLFPDEADCHAN = {};
    sINFO.sREC(idx).cMUACHAN = {'MUA1.ncs', 'MUA2.ncs', 'MUA3.ncs', 'MUA4.ncs', ...
        'MUA5.ncs', 'MUA6.ncs', 'MUA7.ncs', 'MUA8.ncs', 'MUA9.ncs', 'MUA10.ncs', ...
        'MUA11.ncs', 'MUA12.ncs', 'MUA13.ncs', 'MUA14.ncs', 'MUA15.ncs', 'MUA16.ncs'};
    sINFO.sREC(idx).cMUADEADCHAN = {};
    sINFO.sREC(idx).chWheelChan = 'WheelRotation.ncs';
    sINFO.sREC(idx).chWheelDirection = 'forward';
    sINFO.sREC(idx).chPupilCameraTrigChan = 'Camera.ncs';
    sINFO.sREC(idx).chPupilMovieSessionPath = 'E:\data\data\pupil';
    sINFO.sREC(idx).blPupilMovieTrigComplete = 1;
    sINFO.sREC(idx).chPupilMovieTrigType = 'rising';
    sINFO.sREC(idx).cVISUALCHAN = {'VisAnalog.ncs', 'VisTrig.ncs'};
    sINFO.sREC(idx).chDisplayScreenLuminance = 'low';
    sINFO.sREC(idx).chVisualStimSessionPath = '\\mind.med.yale.internal\mind-expansion\Data\Imaging\Stefan\visstim';
end


idx=0;
for mousecnt = 1:length(mouse)
    mousedir = fullfile(datamainDir,dataFolderName,mouse{mousecnt});
    mousedata = dir(mousedir);  mousedata([1 2],:)=[];
%     visualdir = dir(fullfile(visualfolder, mouse{mousecnt}));
%     visidx = contains({visualdir.name},mouse(mousecnt))&contains({visualdir.name},'.csv'); 
%     visualname = {visualdir(visidx).name};
    facedir = dir(fullfile(facefolder, mouse{mousecnt}));
    faceidx = contains({facedir.name},mouse(mousecnt))&contains({facedir.name},'.mp4')&~contains({facedir.name},'_m');
    facename = {facedir(faceidx).name};
    
    for day=1:totalday
        idx=idx+1;
        % same for one mouse in all sessions
        sINFO.sREC(idx).chNlxSessionPath = mousedir;
        sINFO.sREC(idx).inRecNum = 1;
        sINFO.sREC(idx).chState = 'Awake';
        sINFO.sREC(idx).chSex = 'Male';
        sINFO.sREC(idx).chBirthDate = '20-SEP-2019';
        sINFO.sREC(idx).chMouseCage = mouse{mousecnt};
        sINFO.sREC(idx).inMouseID = str2num(mouse{mousecnt}(3:end));
        
        % different for one mouse in different sessions
        sINFO.sREC(idx).chNlxSessionDir = mousedata(day).name;
%         sINFO.sREC(idx).cVISUALSTIMPROTOCOL = {visualname{day}(1:end-4)};
%         if contains(facename{day},visualname{day}(1:end-4))
%             if ~strcmp(facename{day}(1:end-4),visualname{day}(1:end-4))
%                 movefile(fullfile('E:\data\data\pupil', mouse{mousecnt}, facename{day}), fullfile('E:\data\data\pupil',  mouse{mousecnt}, [visualname{day}(1:end-4) '.mp4']),'f');
%             end
%             sINFO.sREC(idx).chFaceMovieFile = facename{day};
%         else
%             error('face and visual donnot match')
%         end
    end
end



%% select the mouse and days want to include   %%% By Stefan 02/05/2025
% mouse list: [qp126 qp130 qp131 qp132 ss110 ss111 ss112
% day: 8 days for the first 9 mice, 14 days for 144, total 86 days/sessions

miceList = [126 130 131 132 110 111 112];
sessionsPerMouse = [7 7 7 7 7 7 7];

selectedMice = [126 130 131 132 110 111 112];
% selectedMice = [110];
numDays = 7;             % Number of sessions per mouse

sessionStartIndices = cumsum([0, sessionsPerMouse]); % Starting indices of each mouse
boolArray = false(1, sum(sessionsPerMouse)); % Initialize boolean array

[~, mouseIndices] = ismember(selectedMice, miceList);

% Compute start and end indices for all selected mice
startIndices = sessionStartIndices(mouseIndices) + 1;
endIndices = sessionStartIndices(mouseIndices) + numDays;

sessionRanges = arrayfun(@(s, e) s:e, startIndices, endIndices, 'UniformOutput', false);
boolArray([sessionRanges{:}]) = true;

sINFO.sREC=sINFO.sREC(boolArray);
end


