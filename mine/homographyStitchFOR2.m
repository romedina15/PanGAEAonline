function [Y,Mask,M,N] = homographyStitchFOR2(VIDEOPATH,isRGB,scale)
filename = VIDEOPATH;
imagefiles = dir(filename);
nfiles = 50;
nfiles = min(nfiles+2, length(imagefiles)-2);
%nfiles = length(imagefiles);    % Number of files found

SURFthresh = 10;

%SETTING UP FIRST ITERATION

%Read frame
currentfilename = imagefiles(3).name;
currentimage = imread(strcat(filename,currentfilename));

%Make grayscale copy of frame and scale it by 'scale'
frameGray = single(rgb2gray(currentimage));
frameGray = imresize(frameGray,scale);

%Storing original frame
if(isRGB)
    store_frame = single(imresize(currentimage,scale));
else
    store_frame = frameGray;
end
    
%Storing noisy version of frame
store_frame = double(store_frame) / 255;

%Select points to track
points1 = detectSURFFeatures(uint8(frameGray),'MetricThreshold',SURFthresh);

%Extract neighborhoods features
[pastfeatures,pastvpts] = extractFeatures(uint8(frameGray),points1);

%Perform homography registration and creating struct
frameidx = 1;
pastIt.image = store_frame;
pastIt.tform = eye(3,3);

%Global lims
gxlim = [inf, -inf];
gylim = [inf, -inf];



ctmre = 0;
%For each frame do
for ii=4:nfiles    
    %Next iteration
    frameidx = frameidx + 1;
    
    %Read next frame
    currentfilename = imagefiles(ii).name;
    currentimage = imread(strcat(filename,currentfilename));
    
    %Make grayscale copy of next frame and scale it by 'scale'
    frameGray = single(rgb2gray(currentimage));
    frameGray = imresize(frameGray,scale);
    
    %Storing original frame
    if(isRGB)
        store_frame = single(imresize(currentimage,scale));
    else
        store_frame = frameGray;
    end
    
    %Storing noisy version of frame
    store_frame = double(store_frame) / 255;
    
    %Select points to track
    points = detectSURFFeatures(uint8(frameGray),'MetricThreshold',SURFthresh);
    
    %Extract neighborhoods features
    [currentfeatures,currentvpts] = extractFeatures(uint8(frameGray),points);
    
    %Match features
    indexPairs = matchFeatures(pastfeatures,currentfeatures,'Unique',true);
    
    %Retrieve locations of corresponding points for both images
    matchedPoints1 = pastvpts(indexPairs(:,1));
    matchedPoints2 = currentvpts(indexPairs(:,2));
    
    %Mapping inliers in matchedPoints1 to inliers in matchPoints2
    tform = estimateGeometricTransform(matchedPoints1,matchedPoints2,'projective','Confidence',99.9,'MaxNumTrials',2000);
    
    %Creating struct
    currentIt.image = store_frame;
    currentIt.tform = pastIt.tform*inv(tform.T);
    
    %Update global limits
    [ccFrame, gxlim, gylim] = stitchImages2FOR2(pastIt, currentIt, gxlim, gylim);
    temp = uint8(ccFrame*255);
    figure(6),imagesc(temp);  axis image
    
    %Calling PanGAEA
    [M, N, c] = size(ccFrame);
    Y = ccFrame(:);
    Mask = ~isnan(Y);
    Y(isnan(Y)) = 0;
    
    dim = size(Y,1);
    r = 5;
    if ctmre == 0
        %U = Y;
        U = orth(randn(dim,r));
        ctmre = 1;
    end
    
    %Need to compute U' by resizing current U
    U = imresize(U, [dim, r]);
    
    %Need to use PanGAEA to update U'
    %First set of varaibles
    opts = struct();

    opts.lambdaZ = 1;
    opts.lambdaS = 0.5;
    opts.lambdaE = 1;

    opts.cleanLS = false;
    opts.max_cycles = 7;

    opts.mask = Mask;
    opts.height = M;
    opts.width = N;
    opts.startStep = 1;
    
   
    
    [U, pano, L_tvgrasta, E_tvgrasta, S_tvgrasta, S_tvgrasta_disp, Lreg_tvgrasta, Ereg_tvgrasta, Sreg_tvgrasta] = run_pangaeaH(U, Y, c,opts);
    figure(7),imagesc(pano);  axis image
    %Saving struct
    pastIt = currentIt;
    pastfeatures = currentfeatures;
    pastvpts = currentvpts;
    
end
Y = 0;
Mask = 0;
M = 0;
N = 0;
end
