function [Y,Ynoisy,Mask,M,N] = homographyStitchFOR2(VIDEOPATH,isRGB,scale,noise,noise_level)

filename = VIDEOPATH;
imagefiles = dir(filename);
nfiles = 60;
nfiles = min(nfiles+2, length(imagefiles)-2);
%nfiles = length(imagefiles);    % Number of files found

SURFthresh = 10;

%PERFORM HOMOGRAPHY REGISTRATION
frameidx = 1;

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
if(noise)
    store_frame = single(imnoise(uint8(store_frame),'salt & pepper',noise_level));
end
store_frame = double(store_frame) / 255;

%Storing in Ynoisy
Ynoisy(:,:,:,frameidx) = store_frame;

%Select points to track
points1 = detectSURFFeatures(uint8(frameGray),'MetricThreshold',SURFthresh);

%Extract neighborhoods features
[pastfeatures,pastvpts] = extractFeatures(uint8(frameGray),points1);

%Perform homography registration and creating struct
frameidx = 1;
pastIt.image = store_frame;
pastIt.tform = eye(3,3);


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
    if(noise)
        store_frame = single(imnoise(uint8(store_frame),'salt & pepper',noise_level));
    end
    store_frame = double(store_frame) / 255;
    
    %Storing in Ynoisy
    Ynoisy(:,:,:,frameidx) = store_frame;
    
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
    
    %Form changed frame
    [ccFrame] = stitchImages2FOR2(pastIt, currentIt);
    ccFrame(isnan(ccFrame)) = 0;
    
    %Make grayscale copy
    ccFrame = imresize(ccFrame, [size(currentIt.image,1), size(currentIt.image,2)]);
    ccFrameGray = single(rgb2gray(ccFrame));
    
    if(isRGB)
        store_frame = ccFrame;
    else
        store_frame = ccFrameGray;
    end
    %figure(6),imagesc(changedcurrFrame);  axis image
    
    %Select points to track
    ccpoints = detectSURFFeatures(uint8(ccFrameGray),'MetricThreshold',SURFthresh);
    
    %Extract neighborhoods features
    [ccfeatures, ccvpts] = extractFeatures(uint8(ccFrameGray),ccpoints);
    
    %Match features
    indexPairs = matchFeatures(currentfeatures,ccfeatures,'Unique',true);
    
    %Retrieve locations of corresponding points for both images
    matchedPoints1 = currentvpts(indexPairs(:,1));
    matchedPoints2 = ccvpts(indexPairs(:,2));
    
    %Mapping inliers in matchedPoints1 to inliers in matchPoints2
    tform = estimateGeometricTransform(matchedPoints1,matchedPoints2,'projective','Confidence',99.9,'MaxNumTrials',2000);
    
    %Constructing struct
    ccIt.image = store_frame;
    ccIt.tform = currentIt.tform*inv(tform);
    
    %Set variables for next iteration
    pastfeatures = ccfeatures;
    pastvpts = ccvpts;
    pastIt = ccIt;
    
end

%PLAY THE NORMAL VIDEO
% for i=1:frameidx-1
%     figure(1),imagesc(images{i}); axis image
% end

%CONSTRUCT THE STITCHING STRUCTURE
% for i=1:length(H_global)
%     It(i).image = images{i};
%     It(i).tform = H_global{i};
% end

%COMPUTE STITCHED VIDEO
[frames] = stitchImages2(It);

[M,N,c] = size(frames{1});

%PLAY SITCHED VIDEO, PREPARE THE FRAMES AND CONSTRUCT OBSERVATION MATRIX
t = length(H_global);

Y = zeros(M*N*c,t);
for i=1:t
    im = frames{i};
    figure(6),imagesc((im));  axis image
    Y(:,i) = im(:);
end

Mask = ~isnan(Y);
Y(isnan(Y)) = 0;

end
