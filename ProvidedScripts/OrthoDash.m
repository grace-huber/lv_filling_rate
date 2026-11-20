function [h, imgW, imgH, imgD] = OrthoDash(vol,windex,hindex,dindex)
%ORTHODASH Presents the orthogonal images from a 3D dataset
% NB: images returned will NOT be transposed as they are in the display
% If any errors are found, imgX return values will all be set to -1.
% Inputs:
%   - vol: the 3D dataset of interest. Will be squeezed in case it is
%   larger
%   - windex: index in width of interest
%   - hindex: index in height of interest
%   - dindex: index in depth of interest
%
% Outputs:
%   - h: handle to the figure.
%   - imgW: the image presented in the Width dimension
%   - imgH: the image presented in the Height dimension
%   - imgD: the image presented in the Depth dimension

% check vol to make sure it's actually three dimensional
vol = squeeze(vol);
sz = size(vol);
windex = floor(windex);
hindex = floor(hindex);
dindex = floor(dindex);

szCheck = size(sz);
if szCheck(2) ~= 3
    disp('OrthoDash Error: vol argument not a 3D dataset')
    imgW = -1;
    imgH = -1;
    imgD = -1;
    return
end % exit in error if vol was not a real 3D dataset.

% Now to do boundary checks
if windex < 1 || windex > sz(1)
    disp('OrthoDash Error: Width index exceeds bounds')
    imgW = -1;
    imgH = -1;
    imgD = -1;
    return
end

if hindex < 1 || hindex > sz(2)
    disp('OrthoDash Error: Height index exceeds bounds')
    imgW = -1;
    imgH = -1;
    imgD = -1;
    return
end

if dindex < 1 || dindex > sz(3)
    disp('OrthoDash Error: Depth index exceeds bounds')
    imgW = -1;
    imgH = -1;
    imgD = -1;
    return
end

% error checking complete.
% Now, let's start the display
imgW = squeeze(vol(windex,:,:));
imgH = squeeze(vol(:,hindex,:));
imgD = squeeze(vol(:,:,dindex));

h = figure;
% "width" dimension
sp1 = subplot(2,2,1);
imshow(imgW',[]);
title('blue')
line([hindex hindex],[1 sz(3)],'Color','red','LineWidth',2);
line([1 sz(2)],[dindex dindex],'Color','green','LineWidth',2);
addborder(sp1,'blue',2);

%height dimension
sp2 = subplot(2,2,2);
imshow(imgH',[]);
title('red')
line([windex windex],[1 sz(3)],'Color','blue','LineWidth',2);
line([1 sz(1)],[dindex dindex],'Color','green','LineWidth',2);
addborder(sp2,'red',2);

% depth dimension
sp3 = subplot(2,2,3);
imshow(imgD',[]);
title('green')
line([windex windex],[1 sz(2)],'Color','blue','LineWidth',2);
line([1 sz(1)],[hindex hindex],'Color','red','LineWidth',2);
addborder(sp3,'green',2);

sgtitle('Orthogonal Image Dashboard v 1.0');
end

