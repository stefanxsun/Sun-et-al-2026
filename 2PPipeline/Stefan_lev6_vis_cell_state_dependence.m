function Stefan_lev6_vis_cell_state_dependence(dirsel,overwrite,reorder)

global info
global infoSummary
global outputDirCardin
input     = 'lev5_vis_trial_state_dependence'; %'lev5_vis_trial_state_dependence';
analysis = 'lev6_vis_cell_state_dependence'; %'lev6_vis_cell_state_dependence';
nDirs = length(info);

mouseCol=find(strcmp(infoSummary.numbersLabel,'Mouse'));   %we later assume that files are in same order as infoSummary.numbersLabel

expID=unique(infoSummary.numbers(:,mouseCol),'rows'); %unique exp based on mouse
mouseTot=expID(:,1);

cellIDLabel={'Day','FoV','Cell','CellType'};
cellIDFoVCol=find(strcmp(cellIDLabel,'FoV'));
cellIDCellCol=find(strcmp(cellIDLabel,'Cell'));

for iDir = dirsel
    
    exptag = info(iDir).dir;
    mouse = exptag(1:6);
    outputDir = fullfile(outputDirCardin, analysis, mouse);
    mkdir(outputDir);
    
    dataDir       = fullfile(outputDirCardin, input, mouse, exptag);
    dirInfo      = dir(dataDir);
    
    mouseID=infoSummary.numbers(iDir,2);
    dayID=infoSummary.numbers(iDir,3);
    FoVID=infoSummary.numbers(iDir,4);
    
    cellID=zeros(size(cellIDLabel));  %initialize details of mouse
    
    outputFilename = fullfile(outputDir, exptag);
    if exist([outputFilename '.mat'], 'file') && overwrite==0,
        fprintf('skipping %s file %s \n', outputFilename), continue,end
    
    
    fovNum=0;cellNumTot=0;
    
    fileNames{1} = fullfile(dataDir, [info(iDir).dir,'.mat']);
    if ~exist(fileNames{1}), continue, end
    
    fprintf('Processing Mouse Number %d, File %s \n',mouseID,info(iDir).dir);
    load(fileNames{1});
    
    firstCaTrial=0;
    numCell=size(CaTrial,2);
    %if we haven't checked this fov for this mouse yet...
    if isempty(find(ismember(cellID(:,cellIDFoVCol),FoVID)))
        cellNum = (1:numCell)';
        cellType=ones(numCell,1);
        
        if ~exist('CaCellTrial')   %first fov we've dealt with
            CaCellTrial=CaTrial;
            CaCellPre=CaTrialPre;
            CaCellWhole=CaTrialWhole;
            CaCellRaw=CaTrialRaw;
            firstCaTrial=1;
        end
        
        CaCellMean=[];
        
        if length(cellNum) ~= size(CaTrial,2)
            fprintf('Warning: Number of cells in %s do not match with those given in Info file! \n ', info(iDir).dir);
        end
        numStates=size(CaTrial,1);
        for state=1:numStates
            stimVal=CaTrialInfo.stimValue{state};
            %do stimAxis at end once have all together - need to do for each indiv cell
            for cellInd=1:length(cellNum)
                if firstCaTrial~=1  %not first trial
                    CaCellTrial{state,size(cellID,1)+cellInd}=CaTrial{state,cellInd};
                    CaCellPre{state,size(cellID,1)+cellInd}=CaTrialPre{state,cellInd};
                    CaCellWhole{state,size(cellID,1)+cellInd}=CaTrialWhole{state,cellInd};
                    CaCellRaw{state,size(cellID,1)+cellInd}=CaTrialRaw{state,cellInd};
                    CaCellInfo.stimValue{state,size(cellID,1)+cellInd}=stimVal;
                else
                    CaCellInfo.stimValue{state,cellInd}=stimVal;
                    %%% calculate zscore traces
                    for trialind = 1:size(CaCellRaw{state,cellInd},2)
                        CaCell.Zscore{state,cellInd}(:,trialind)=...
                            (CaCellRaw{state,cellInd}(:,trialind)-mean(CaCellRaw{state,cellInd}(1:60,trialind)))./...
                            (std(CaCellRaw{state,cellInd}(1:60,trialind)));
                    end
                    
                    for trialind=1:size(CaCellWhole{state,cellInd},2)
                        CaCellMean.CV{state,cellInd}(:,trialind) = std(CaCellWhole{state,cellInd}(1:59,trialind))/mean(CaCellWhole{state,cellInd}(1:59,trialind));
                    end
                end
            end
        end
        
        
        cellID=[cellID; [dayID*ones(length(cellNum),1) , FoVID*ones(length(cellNum),1), cellNum, cellType]];
        cellID = cellID(any(cellID,2),:);   %remove initial row of zeros
        
        
    end
    
    
    
    
    %%%% inherit from last step
    
    CaCellMean.preInd=CaTrialMean.preInd;
    CaCellMean.Ind=CaTrialMean.ind;
    
    
    
    % do some averaging
    if ~exist('CaCellTrial')
        fprintf('No CaCellTrial exists for averaging'),
    else
        numStates=size(CaCellTrial,1);
        cellNumTot=size(cellID,1);
        %check that cellID has logged cell numbers appropriately
        if cellNumTot ~= size(CaCellTrial,2)
            fprintf('Warning: Number of cells in mouse %d (%d) do not match with those given in CellID (%d) \n', mouseID,size(CaCellTrial,2),cellNumTot);
        end
        for state=1:numStates
            for cellInd=1:cellNumTot
                CaCellMean.IndddFF{state,cellInd}=max(CaCellWhole{state,cellInd}(61:150,:),[],1)-mean(CaCellWhole{state,cellInd}(1:60,:));
                %                     CaCellMean.IndZscore{state,cellInd}=max(CaCell.Zscore{state,cellInd}(61:150,:),[],1);  %%use max
                CaCellMean.IndZscore{state,cellInd}=mean(CaCell.Zscore{state,cellInd}(61:120,:));    %%use mean
                %                     CaCellMean.IndZscore{state,cellInd}=trapz(1:90,CaCell.Zscore{state,cellInd}(61:150,:));  %% use area under the curve
                stimVal=CaCellInfo.stimValue{state,cellInd};
                
                [stimAxis,~,idx]=unique(stimVal,'rows','stable');
                CaCellInfo.stimAxis{state,cellInd}=stimAxis;
                for indNum=1:size(CaCellTrial{state,cellInd},1)
                    CaCellMean.Trial{state,cellInd}(indNum,:) = accumarray(idx,CaCellTrial{state,cellInd}(indNum,:),[],@mean);
                end
                
                for indNum=1:size(CaCellPre{state,cellInd},1)
                    CaCellMean.PreTrial{state,cellInd}(indNum,:) = accumarray(idx,CaCellPre{state,cellInd}(indNum,:),[],@mean);
                end
                
                for indNum=1:size(CaCellWhole{state,cellInd},1)
                    CaCellMean.WholeTrial{state,cellInd}(indNum,:) = accumarray(idx,CaCellWhole{state,cellInd}(indNum,:),[],@mean);
                end
                
                for indNum=1:size(CaCell.Zscore{state,cellInd},1)
                    CaCellMean.ZscoreTrial{state,cellInd}(indNum,:) = accumarray(idx,CaCell.Zscore{state,cellInd}(indNum,:),[],@mean);
                end
                
                
                CaCellMean.IndTrial{state,cellInd}=mean(CaCellMean.Trial{state,cellInd},1);
                CaCellMean.IndTrialddFF{state,cellInd}=accumarray(idx,CaCellMean.IndddFF{state,cellInd}',[],@mean);
                CaCellMean.IndTrialZscore{state,cellInd}=accumarray(idx,CaCellMean.IndZscore{state,cellInd}',[],@mean);
            end
        end
    end
    
    CaCellInfo.struct1={'CRF','ORT','SF'};
    CaCellInfo.struct2={'state','cell'};
    CaCellInfo.mat={'ind of single stim','visual stim'};
    CaCellInfo.numStates=numStates;
    CaCellInfo.cellID=cellID;
    CaCellInfo.cellIDLabel={'Day','FoV','Cell','CellType'};
    CaCellInfo.goodCells=CaTrialInfo.goodCells;
    CaCell.Trial=CaCellTrial;
    CaCell.Pre=CaCellPre;
    CaCell.Whole=CaCellWhole;
    CaCell.Raw=CaCellRaw;
    if reorder
        InitialDir  = fullfile('F:\suite2pMatFile',mouse,'*.mat');
        [CaCell, CaCellMean] = reorder_cells(CaCell,CaCellMean,InitialDir);
    end
    save(outputFilename, 'CaCell','CaCellInfo','CaCellMean');
    
    clear CaCell CaCellInfo CaCellMean CaCellTrial
    %     end
end
end

function [CaCell,CaCellMean] = reorder_cells(CaCell,CaCellMean,InitialDir)
% Create a GUI window to select and load a file
[file, path] = uigetfile(InitialDir, 'Select a file');

% Check if a file was selected
if isequal(file, 0)
    disp('No file selected. Not reordering');
else
    % Construct the full file path
    fullFilePath = fullfile(path, file);
    
    % Load the file
    try
        load(fullFilePath,'roiMatchData');
        reorderMatrix = roiMatchData.allSessionMapping;
        Column = inputdlg('Enter which day from the mapping matrix:', 'Number Input', 1);
        Column = str2double(Column);
        if Column ==0
            disp('Not reordering');   % if not reordering this session
            return
        end
        
        % Process the loaded data as needed
        disp(['reordering base on: ',file]);
        % reorder CaCell and CaCellMean
        CaCell = reorderStruct(CaCell,reorderMatrix(:,Column));
        CaCellMean = reorderStruct (CaCellMean,reorderMatrix(:,Column));
    catch ME
        disp('Error');
        disp(ME.message);
    end
end
end


function newStruct = reorderStruct(oldStruct,index)

fieldNames = fieldnames(oldStruct);
cellNum = length(oldStruct.(fieldNames{1}));
indexRest = setdiff(1:cellNum, index');
ReorderIndex = [index' indexRest];

for i = 1:length(fieldNames)
    newStruct.(fieldNames{i})   = oldStruct.(fieldNames{i})(:,ReorderIndex);
end
end







