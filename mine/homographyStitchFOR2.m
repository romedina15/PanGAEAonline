function [Y,Mask,M,N] = homographyStitchFOR2(VIDEOPATH,isRGB,scale)

filename = VIDEOPATH;
imagefiles = dir(filename);
nfiles = 70;
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
    %[gxlim, gylim] = updateGlobal(pastIt, currentIt, gxlim, gylim);
    [ccFrame, gxlim, gylim] = stitchImages2FOR2(pastIt, currentIt, gxlim, gylim);
    ccFrame = uint8(ccFrame*255);
    figure(6),imagesc(ccFrame);  axis image
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
