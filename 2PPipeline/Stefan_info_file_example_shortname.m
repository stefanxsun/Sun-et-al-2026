function [info,infoSummary] = Stefan_info_file_example_shortname()

% we assume that all directories have all the info inside them, including the pupil video 

global info
global infoSummary
global outputDirCardin
global figureDirCardin
global caDirCardin
global spike2Dir


% these are the data directories used to locate the data 
info = []; 
expSummary=[]; 
dirBase       = 'E:\data\data';
serverBase = '\\kermit.med.yale.internal\kermit\Stefan';
outputDirCardin  = fullfile(dirBase,'Analysis'); 
figureDirCardin  = fullfile(dirBase,'Test_Figures'); 
caDirCardin      = fullfile(dirBase,'ROI'); 
spike2Dir = fullfile(serverBase,'rawdata\2P'); 

% % % % % % % % %

info = []; 

info(end+1).dir         = 'ss0160_d251030';
info(end).session       = 1;
info(end).fcasample     = 29.97;

info(end+1).dir         = 'ss0160_d251106';
info(end).session       = 8;
info(end).fcasample     = 29.97;

[info(:).root]          = deal(dirBase);
[info(:).fsample]       = deal(5000);
[info(:).framesPerMovie] = deal(3500);
[info(:).frame]         = deal('chan1');
[info(:).trig]          = deal('chan2');  %visual stim
[info(:).pupilCam]     = deal('chan3');
[info(:).wheel]         = deal('chan4');
[info(:).opto]           = deal('chan5');
[info(:).numPop]        = deal(1);
[info(:).popLabel]      = deal({'SOM'});
[info(:).stimStructOrder] = deal({'ORT','SF','TF','CRF','radius'});


%read out experiment info from file name into "numbers".  exp number, Mouse number,
%day number, fov number.
numbers=zeros(length(info),4);  % make it 5 if we add imaging field
for iFile=1:length(info)
      fileInfo         =   regexp(info(iFile).dir,'\d*','match'); 
      numbers(iFile,1) =   str2num(fileInfo{1});   % cageNum
      numbers(iFile,2) =   str2num(fileInfo{1});   % msNum
      numbers(iFile,3) =   str2num(fileInfo{2});   % day
      numbers(iFile,4) =   1;   % fov
end

mice = unique(numbers(:,2));
nMice       = length(mice);

infoSummary.numbers=numbers;
infoSummary.numbersLabel={'Cage', 'Mouse' , 'Day' , 'FoV'}; % add this if we extract imaging field here: ,'Imaging Field'};
infoSummary.nMice=nMice;
infoSummary.mouseNum=mice;
