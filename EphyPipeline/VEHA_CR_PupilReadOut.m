function [db2Output] = VEHA_CR_PupilReadOut(sCFG) %Identical to VEHA_CR_PupilReadOut
%Core routine (CR) for the readout of pupil video. To a large extend it is
%identical to the script Cardin_lev0_pupilreadout_followlast_6 written by
%Martin Vinck. The main differences are:
%   -Smoothing has been replaced by a two step of closure by reconstruction
%   interleaved with on step of adaptive histogram normalization
%   -clustering is now performed based on luminance AND on the distance to
%   the center of the image. The algorithm looks for 5-7 clusters and takes
%   the closest to the center.
%   -Fuzzy clustering is now optional as regular k-means clustering is
%   faster and tends to yield better results
%   -Instead of fitting and elispe the two roundest objects in the cluster, 
%   the routine now fits the object having the most pixels
%   -the pre-fit checkpoints for removal of ouliers have been made optional
%The function requires two subroutine: edge_local and fit_ellipse which
%must be added to the path
%
%QP 2016-08-18   


%Initialize parameters
if ~isfield(sCFG, 'chPathToFile'), error('sCFG.chPathToFile should be specified'), end
if ~isfield(sCFG, 'in1XL'), sCFG.in1XL = []; end
if ~isfield(sCFG, 'in1YL'), sCFG.in1YL = []; end
if ~isfield(sCFG, 'dbMaxPixValForSegmentation'), sCFG.dbMaxPixValForSegmentation = 100; end
if ~isfield(sCFG, 'blFuzzyClustering'), sCFG.blFuzzyClustering = 0; end
if sCFG.blFuzzyClustering
    if ~isfield(sCFG, 'dbFuzzyCutOff'), sCFG.dbFuzzyCutOff = 0.7; end
end
if ~isfield(sCFG, 'blRemLinearFitOutliers'), sCFG.blRemLinearFitOutliers = 0; end
if ~isfield(sCFG, 'blRemHighLumEdges'), sCFG.blRemHighLumEdges = 1; end
if sCFG.blRemHighLumEdges
    if ~isfield(sCFG, 'inMaxPixFromHighLum'), sCFG.inMaxPixFromHighLum = 10; end
    if ~isfield(sCFG, 'dbQuantileOfHighLum'), sCFG.dbQuantileOfHighLum = 0.85; end
end
if ~isfield(sCFG, 'inFramesPerRead'), sCFG.inFramesPerRead = 500; end
if ~isfield(sCFG, 'blWriteVid'), sCFG.blWriteVid = false; end
if sCFG.blWriteVid
    if ~isfield(sCFG, 'chOutputDir'), error('sCFG.chOutputDir should be specified'), end
end
if ~isfield(sCFG, 'inVidFrameInterval'), sCFG.inVidFrameInterval= 10; end


%Test that the input file exists and is readable
fprintf('Checking video file\r')
if ~exist(sCFG.chPathToFile, 'file'), error('Could not locate %s', sCFG.chPathToFile), end
try
    sMMREAD_OUTPUT = mmread(sCFG.chPathToFile, [], [0 4]);
catch
    fprintf('Could not read %s', sCFG.chPathToFile)
    db2Output = [];
    return
end

%Initialize the output file if required
if sCFG.blWriteVid
    [chPath, chFileName] = fileparts(sCFG.chPathToFile);
    chPathToVidOutput = fullfile(sCFG.chOutputDir, [chFileName '.avi']);
    if exist(chPathToVidOutput, 'file'), delete(chPathToVidOutput); end
    oVID_OUTPUT = VideoWriter(chPathToVidOutput);
    oVID_OUTPUT.FrameRate = 10;
    open(oVID_OUTPUT);
end


%Initialize the main loop
dbTotalDuration = sMMREAD_OUTPUT.totalDuration;
dbFrameRate = median(1./diff(sMMREAD_OUTPUT.times));
inNFrame = round(dbTotalDuration * dbFrameRate);
inFrameCount  = 0; % the counter for all the frames
db2Output    = nan(inNFrame, 61); % the output matrix
blFirstFrame = 1;


%Precomputes morphological elements outside the loops as they are going to
%be reused
if ~isempty(sCFG.in1XL) || ~isempty(sCFG.in1YL)
    in1ImDim = [range(sCFG.in1XL) range(sCFG.in1YL)];
else
    in1ImDim = size(sMMREAD_OUTPUT(end).frames(end).cdata(:,:,1));
end
oSE_1 = strel('disk', round(min(min(in1ImDim))/7)); 
oSE_2 = strel('disk', round(min(min(in1ImDim))/20)); 

warning off
%Loops through chuncks of the movie
while inFrameCount < 1 + (sCFG.inFramesPerRead*floor(inNFrame/sCFG.inFramesPerRead)) 
    
    %Reads chuncks of the Video
    in1FrameToRead = inFrameCount + 1 : inFrameCount + sCFG.inFramesPerRead;
    try
        sMMREAD_OUTPUT = mmread(sCFG.chPathToFile, in1FrameToRead);
    catch
        fprintf('Breaking off at frame %d. Could not read the video\n', inFrameCount, inNFrame);
    end
    
    %The fact that no frame is loaded, might indicate that the estimated
    %number of frame exeeds that actual number of frame. If it is the case
    %rectifies this to avoid getting stuck in an infinite loop.s
    inNFrameInRead   = length(sMMREAD_OUTPUT(end).frames);
    if inNFrameInRead == 0; inNFrame = inFrameCount; end
    
    % Zoom in the appropriate area
    if ~isempty(sCFG.in1XL) || ~isempty(sCFG.in1YL)
        for iFrame = 1:inNFrameInRead
            sMMREAD_OUTPUT.frames(iFrame).cdata = sMMREAD_OUTPUT.frames(iFrame).cdata(sCFG.in1YL(1):sCFG.in1YL(2), sCFG.in1XL(1):sCFG.in1XL(2),:);
        end
    end
    
    %Detects pupil on each frame of the chunck
    for iFrame = 1:inNFrameInRead
        inFrameCount = inFrameCount + 1;
        if mod(inFrameCount, 10) == 1
            fprintf('Processing frame %d of %d for %s\n', inFrameCount, inNFrame, sCFG.chPathToFile);
        end         
        
        %Extract the frame and resizes it according to parameters
        db3ImBase = sMMREAD_OUTPUT.frames(iFrame).cdata;
        db2Im = double(db3ImBase(:,:,1));
        
        %Smooth the image through closure by reconstruction and enhances contrast with adaptive histogram equalization 
        db2ImClose = db2Im; 
        db2ImClose = imreconstruct(imerode(db2ImClose, oSE_1), db2Im); 
        db2ImClose = double(adapthisteq(uint8(db2ImClose), 'Distribution', 'rayleigh')); 
        db2ImClose = imreconstruct(imerode(db2ImClose, oSE_1), db2Im); 


        %Constructs the parameter matrix for clusterings
        db1ImClust = db2ImClose; 
        
            %Computes an image whos value is the distance to the center
        [inYMax, inXmax] = size(db2Im); inYmid = round(inYMax/2); inXmid = round(inXmax/2);
        [xx, yy] = meshgrid((1:inXmax) - inXmid, (1:inYMax) - inYmid);
        db1ImDist = sqrt(xx.^2 + yy.^2);
        
            %Removes the pixels whose value is too high
        db1ImClust(db2Im>sCFG.dbMaxPixValForSegmentation) = NaN;
        db1ImDist(db2Im>sCFG.dbMaxPixValForSegmentation) = NaN;
        
            %Construct the matrix
        db1ImClust = db1ImClust(:); db1ImDist = db1ImDist(:);
        in1ImIdx = 1:length(db1ImClust); bl1IsUsed = ~isnan(db1ImClust);
        in1ImIdx = in1ImIdx(bl1IsUsed); db1ImClust = db1ImClust(bl1IsUsed); db1ImDist = db1ImDist(bl1IsUsed);
        db2CMat = zscore([db1ImClust db1ImDist])*([2 0; 0 1]);
        
        %Clusters the Points
        try
            if sCFG.blFuzzyClustering
                db1Option = [2;	% exponent for the partition matrix U
                    100;	% max. number of iteration
                    1e-5;	% min. amount of improvement
                    0];	% info display during iteration
                [db2Centroid,db2Membership] = fcm(db2CMat, 5, db1Option);
                [ignore, inPupilClustIdx] = min(db2Centroid(:, 2)); % Cluster closest to the center of the image
                in1PupilIdx = db2Membership(inPupilClustIdx,:) > sCFG.dbFuzzyCutOff; % Keeps the points superior to fuzzy cuttof
            else
                if blFirstFrame == 1  %Initialize the centroids to the quantiles of the sum of db2CMat
                    inNClust = 7;
                    db1QSumCMat = quantile(sum(db2CMat, 2), linspace(0, 1, inNClust));
                    in1CStartIdx = zeros(inNClust, 1);
                    for iQ = 1:inNClust
                        [ignore, in1CStartIdx(iQ)] = min(abs(sum(db2CMat, 2) - db1QSumCMat(iQ)));
                    end
                    db2Centroid= db2CMat(in1CStartIdx, :);
                    blFirstFrame = 0;
                end
                [in2CIdx, db2Centroid] = kmeans(db2CMat, inNClust, 'start', db2Centroid);
                [ignore, inPupilClustIdx] = min(db2Centroid(:, 2)); % Cluster closest to the center of the image
                in1PupilIdx = in2CIdx == inPupilClustIdx;
            end
        catch
            if mod(inFrameCount,sCFG.inVidFrameInterval)==0 && sCFG.blWriteVid==1
                oFRAME = im2frame(db3ImBase);
                writeVideo(oVID_OUTPUT,oFRAME);
            end
            continue,
        end
        
        %create a binary image and fill the holes
        bl2BinIm = zeros(size(db2Im));
        bl2BinIm(in1ImIdx(in1PupilIdx)) = 1;
%         bl2BinIm = ~activecontour(db2ImClose, bl2BinIm, 5 , 'Chan-Vese', 1); 
        bl2BinIm = imclose(bl2BinIm, oSE_2);
        bl2BinIm = imfill(bl2BinIm,'holes');
        
        
        %Extracts the proporties of the pixel groups (there is sometime more than one) 
        sREGION_PROPS = regionprops(logical(bl2BinIm), 'PixelIdxList', 'Centroid', 'Perimeter') ;
        inNRegion = length(sREGION_PROPS);

        %Exit loop if there is no region identified
        if inNRegion==0,
            if mod(inFrameCount,sCFG.inVidFrameInterval)==0 && sCFG.blWriteVid==1
                oFRAME = im2frame(db3ImBase);
                writeVideo(oVID_OUTPUT,oFRAME);
            end
            continue,
        end

        %Selects the region having the most pixels
        in1NumPix = zeros(1, inNRegion);
        for iReg = 1:inNRegion
            in1NumPix = length(sREGION_PROPS(iReg).PixelIdxList);
        end
        [arVal,arSort] = sort(in1NumPix,'descend'); %
        inSelRegIdx = arSort(1); %Cluster closest to the center of the image 
        
        
        %Detects the edges of the region
        bl2Mask = false(size(bl2BinIm)); 
        bl2Mask(sREGION_PROPS(inSelRegIdx).PixelIdxList) = true; %Add QP: 2016-07-21
        bl1Edges = double(edge_local(bl2Mask));
        in1EdgeIdx = find(bl1Edges);
        [in1REdges,in1CEdges] = ind2sub(size(db2Im),in1EdgeIdx); % column and rows of edges
        
        
        %Performs a linear fit on the distance to the center of the region
        %and eliminates outliers
        if sCFG.blRemLinearFitOutliers
            inRCntr = round(mean(in1REdges)); inCCntr = round(mean(in1CEdges));
            db1DtCntr = sqrt(((in1REdges - inRCntr).^2) + ((in1CEdges - inCCntr).^2));
            [yy, in1DIdx] = sort(db1DtCntr);
            xx = (1:length(yy))';
            
            in1QBound = round(quantile(xx, [0.2 0.8]));
            in1BdIdx = in1QBound(1):in1QBound(2);
            phat = polyfit(xx(in1BdIdx), yy(in1BdIdx), 1);
            yhat = polyval(phat, xx);
            db1FitErr = yhat - yy;
            
            db1AvErr = mean(db1FitErr(in1BdIdx)); db1SdErr = std(db1FitErr(in1BdIdx));
            db1ZErr = (db1FitErr - db1AvErr)/db1SdErr;
            inOutliersIdx = abs(db1ZErr) > 2;
            
            in1EdgeIdx(in1DIdx(inOutliersIdx)) = [];
            [in1REdges,in1CEdges] = ind2sub(size(im),in1EdgeIdx);
            bl1Edges = false(size(bl1Edges)); bl1Edges(in1EdgeIdx) = true;
            
%             pouet = zeros(size(im)); for ii = 1:length(in1CEdges), pouet(in1REdges(ii), in1CEdges(ii)) = 1; end, figure, imagesc(pouet)
        end
        
        
        %Removes points close to a high luminance source such as the
        %reflection of the IR light source on the eye
        if sCFG.blRemHighLumEdges
            npx = sCFG.inMaxPixFromHighLum;
            thl = sCFG.dbMaxPixValForSegmentation;
            qtl = sCFG.dbQuantileOfHighLum;
            try
                for iEdge = 1:length(in1EdgeIdx)
                    db2SurIm = db2Im(in1REdges(iEdge)-npx:in1REdges(iEdge)+npx,in1CEdges(iEdge)-npx:in1CEdges(iEdge)+npx);
                    bl2SurMask = bl2Mask(in1REdges(iEdge)-npx:in1REdges(iEdge)+npx,in1CEdges(iEdge)-npx:in1CEdges(iEdge)+npx);
                    if quantile(db2SurIm(bl2SurMask), qtl)> thl
                        bl1Edges(in1REdges(iEdge),in1CEdges(iEdge)) = 0;
                    end
                end
            catch ME
                getReport(ME)
            end
            in1EdgeIdx = find(bl1Edges);
            [in1REdges,in1CEdges] = ind2sub(size(db2Im),in1EdgeIdx);
            
%             pouet = zeros(size(db2Im)); for ii = 1:length(in1CEdges), pouet(in1REdges(ii), in1CEdges(ii)) = 1; end, figure, imagesc(pouet)
%             title(sprintf('%d and %d\r', thl, qtl))
        end
 

        %Fit an ellipsee to the edges skip if the fit does not work

        try
            sELLIPSE = fit_ellipse(in1CEdges,in1REdges);
        catch
            if mod(inFrameCount,sCFG.inVidFrameInterval)==0 && sCFG.blWriteVid==1
                oFRAME = im2frame(db3ImBase);
                writeVideo(oVID_OUTPUT,oFRAME);
            end
            continue,
        end

        if isempty(sELLIPSE) || isempty(sELLIPSE.short_axis) || isnan(sELLIPSE.Y0_in)
            if mod(inFrameCount,sCFG.inVidFrameInterval)==0 && sCFG.blWriteVid==1
                oFRAME = im2frame(db3ImBase);
                writeVideo(oVID_OUTPUT,oFRAME);
            end
            continue,
        end

        
        cMin = sREGION_PROPS(inSelRegIdx).Centroid(1); rMin = sREGION_PROPS(inSelRegIdx).Centroid(2);
        d1 = sqrt((sELLIPSE.rotel(1,:)-sELLIPSE.X0_in).^2 + (sELLIPSE.rotel(2,:)-sELLIPSE.Y0_in).^2);
        d2 =  sqrt((sELLIPSE.X0_in-cMin).^2 + (sELLIPSE.Y0_in-rMin).^2);
        if all(d1<d2)
            if mod(inFrameCount,sCFG.inVidFrameInterval)==0 && sCFG.blWriteVid==1
                oFRAME = im2frame(db3ImBase);
                writeVideo(oVID_OUTPUT,oFRAME);
            end
            continue,
        end
        
     
        %Writes the output
        db2Output(inFrameCount,1)  = sELLIPSE.long_axis;
        db2Output(inFrameCount,2)  = sELLIPSE.short_axis;
        db2Output(inFrameCount,3)  = sELLIPSE.long_axis/2.*sELLIPSE.short_axis/2.*pi;
        db2Output(inFrameCount,4)  = sMMREAD_OUTPUT(end).times(iFrame);
        db2Output(inFrameCount,5)  = sELLIPSE.X0_in;
        db2Output(inFrameCount,6)  = sELLIPSE.Y0_in;
        db2Output(inFrameCount,7)  = sELLIPSE.a;
        db2Output(inFrameCount,8)  = sELLIPSE.b;
        db2Output(inFrameCount,9)  = sELLIPSE.phi;
        db2Output(inFrameCount,10) = sELLIPSE.X0;
        db2Output(inFrameCount,11) = sELLIPSE.Y0;
        db2Output(inFrameCount,12:61) = histc(db2Im(:),linspace(0,255,50));
%         dimord = 'long_axis__short_axis__area__time__centerX__centerY__a__b__phi__X0__Y0';
        
           
        %-----------------------------------------------------------------
        
        % Draws the ellipse on the image and stores the output
        if mod (inFrameCount, sCFG.inVidFrameInterval) == 0 && sCFG.blWriteVid == 1
            
            in1Color = [0 255 0];
            for j = -5:5
                for k = -5:5
                    if (round(db2Output(inFrameCount,6))-j)>size(db3ImBase,1) || (round(db2Output(inFrameCount,6))-j)<1, continue,end
                    if (round(db2Output(inFrameCount,5))-k)>size(db3ImBase,2) || (round(db2Output(inFrameCount,5))-k)<1, continue,end
                    db3ImBase(round(db2Output(inFrameCount,6))-j, round(db2Output(inFrameCount,5))-k,:) = in1Color;
                end
            end
            theta_r         = linspace(0,2*pi);
            ellipse_x_r     = db2Output(inFrameCount,10) + db2Output(inFrameCount,7)*cos( theta_r );
            ellipse_y_r     = db2Output(inFrameCount,11) + db2Output(inFrameCount,8)*sin( theta_r );
            cos_phi         = cos(db2Output(inFrameCount,9));
            sin_phi         = sin(db2Output(inFrameCount,9));
            R               = [ cos_phi sin_phi; -sin_phi cos_phi ];
            rotated_ellipse = R * [ellipse_x_r;ellipse_y_r];
            
            for j = 1:size(rotated_ellipse,2)
                if (round(db2Output(inFrameCount,13) + rotated_ellipse(2,j)))>size(db3ImBase,1) || (round(db2Output(inFrameCount,13) + rotated_ellipse(2,j)))<1, continue,end
                if (round(db2Output(inFrameCount,12) + rotated_ellipse(1,j)))>size(db3ImBase,2) || (round(db2Output(inFrameCount,12) + rotated_ellipse(1,j)))<1, continue,end
                db3ImBase(round(db2Output(inFrameCount,13) + rotated_ellipse(2,j)), round(db2Output(inFrameCount,12) + rotated_ellipse(1,j)),:) = in1Color;
            end
            
            oFRAME = im2frame(db3ImBase);
            writeVideo(oVID_OUTPUT,oFRAME);
        end
    end 
end
warning on

if sCFG.blWriteVid == 1
    close(oVID_OUTPUT)
end