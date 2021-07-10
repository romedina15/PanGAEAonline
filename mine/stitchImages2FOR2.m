function [frames, gxlim, gylim] = stitchImages2FOR2(pastIt, currentIt, gxlim, gylim)
    
    % Parse mandatory inputs
    Nc = size(pastIt.image,3);
    
    % Default values
    dim = [];
    
    % Compute stitched image limits
    [currentIt, xlim, ylim] = computeStitchedLimits(pastIt, currentIt);
    gxlim(1) = min(xlim(1), gxlim(1));
    gxlim(2) = max(xlim(2), gxlim(2));
    gylim(1) = min(ylim(1), gylim(1));
    gylim(2) = max(ylim(2), gylim(2));
    
    % Get sample points
    [x, y, w, h] = getSamplePoints(gxlim,gylim,dim);
    % Stitch images
    empty = nan(h,w,Nc);
    [frames] = overlayImage(empty,currentIt,x,y);
    
    

%--------------------------------------------------------------------------
function [currentIt, xlim, ylim] = computeStitchedLimits(pastIt, currentIt)
    % Compute limits
    [pastxlimi, pastylimi] = getOutputLimits(pastIt.image,pastIt.tform);
    [currentxlimi, currentylimi] = getOutputLimits(currentIt.image,currentIt.tform);
    currentIt.xlim = currentxlimi;
    currentIt.ylim = currentylimi;
    minx = min(pastxlimi(1), currentxlimi(1));
    maxx = max(pastxlimi(2), currentxlimi(2));
    miny = min(pastylimi(1), currentylimi(1));
    maxy = max(pastylimi(2), currentylimi(2));

    xlim = [floor(minx), ceil(maxx)];
    ylim = [floor(miny), ceil(maxy)];
    

%--------------------------------------------------------------------------
function [xlim, ylim] = getOutputLimits(I,H)
    % Compute limits of transformed image
    [Ny, Nx, ~] = size(I);
    X = [1 Nx Nx 1];
    Y = [1 1 Ny Ny];
    [Xt, Yt] = applyTransform(X,Y,H);
    xlim = [min(Xt), max(Xt)];
    ylim = [min(Yt), max(Yt)];

%--------------------------------------------------------------------------
function [Xt, Yt] = applyTransform(X,Y,H)
    % Apply transformation
    sz = size(X);
    n = numel(X);
    tmp = [X(:), Y(:), ones(n,1)] * H;
    Xt = reshape(tmp(:,1) ./ tmp(:,3),sz);
    Yt = reshape(tmp(:,2) ./ tmp(:,3),sz);

%--------------------------------------------------------------------------
function [X, Y] = applyInverseTransform(Xt,Yt,H)
    % Apply inverse transformation
    sz = size(Xt);
    n = numel(Xt);
    tmp = [Xt(:), Yt(:), ones(n,1)] / H;
    X = reshape(tmp(:,1) ./ tmp(:,3),sz);
    Y = reshape(tmp(:,2) ./ tmp(:,3),sz);

%--------------------------------------------------------------------------
function [x, y, w, h] = getSamplePoints(xlim,ylim,dim)
    % Get sample dimensions
    if isempty(dim)
        w = diff(xlim) + 1;
        h = diff(ylim) + 1;
    else
        w = dim(2);
        h = dim(1);
    end
    
    % Limit resolution to a reasonable value, if necessary
    MAX_PIXELS = 2000 * 2000;
    [w, h] = limitRes(w,h,MAX_PIXELS);
    
    % Compute sample points
    x = linspace(xlim(1),xlim(2),w);
    y = linspace(ylim(1),ylim(2),h);

%--------------------------------------------------------------------------
function [w, h] = limitRes(w,h,lim)
    if w * h <= lim
        % No rescaling needed
        return;
    end
    
    % Rescale to meet limit
    kappa = w / h;
    w = round(sqrt(lim * kappa));
    h = round(sqrt(lim / kappa));
    warning('Output resolution too large, rescaling to %i x %i',h,w);

%--------------------------------------------------------------------------
function [Is] = overlayImage(Is,It,x,y)
    % Overlay image
    Nc = size(Is,3);
    [If] = fillImage(It,x,y);
    mask = ~any(isnan(If),3);
    for j = 1:Nc
        Isj = Is(:,:,j);
        Ifj = If(:,:,j);
        Isj(mask) = Ifj(mask);
        Is(:,:,j) = Isj;
    end

%--------------------------------------------------------------------------
function [If]= fillImage(It,x,y)
    % Parse inputs
    Nc = size(It.image,3);
    w = numel(x);
    h = numel(y);
    
    % Get active coordinates
    [~, xIdx1] = find(x <= It.xlim(1),1,'last');
    [~, xIdx2] = find(x >= It.xlim(2),1,'first');
    [~, yIdx1] = find(y <= It.ylim(1),1,'last');
    [~, yIdx2] = find(y >= It.ylim(2),1,'first');
    wa = xIdx2 + 1 - xIdx1;
    ha = yIdx2 + 1 - yIdx1;
    
    % Compute inverse transformed coordinates
    [Xta, Yta] = meshgrid(x(xIdx1:xIdx2),y(yIdx1:yIdx2));
    [Xa, Ya] = applyInverseTransform(Xta,Yta,It.tform);
    
    % Compute active image
    Ia = zeros(ha,wa,Nc);
    for j = 1:Nc
        Ia(:,:,j) = interp2(double(It.image(:,:,j)),Xa,Ya);
    end
    
    % Embed into full image
    If = nan(h,w,Nc);
    If(yIdx1:yIdx2,xIdx1:xIdx2,:) = Ia;
    