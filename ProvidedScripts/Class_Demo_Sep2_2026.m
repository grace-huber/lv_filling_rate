%% Getting started

% set the directories in advance
addpath("scripts")
addpath("datasets")


dataset = resampleDicom("datasets\002A.dcm");

frame1 = dataset.data(:,:,:,1);
sz = size(frame1);

mids = floor(sz/2);


%% Extract three orthogonal slices

slice1 = squeeze(frame1(mids(1),:,:));
slice2 = squeeze(frame1(:,mids(2),:));
slice3 = squeeze(frame1(:,:,mids(3)));

figure(1)
imshow(slice1', []);

figure(2)
imshow(slice2', [min(min(slice2)) max(max(slice2))]);

figure(3)
imshow(slice3, []);


%% Loop through one spatial dimension

for i = 1:sz(1)
    im = squeeze(dataset.data(i,:,:,1));
    imshow(im);
    title(sprintf("Slice index: %d",i));
end

%% create Loop in Time (generate AVI)

v = VideoWriter("ExampleVideo.mp4", 'MPEG-4');
v.FrameRate = 15;
v.open();

for i = 1:dataset.NumVolumes
  frame = dataset.data(mids(1),:,:,i);
  v.writeVideo(squeeze(frame)');
end

v.close();
%% translate the image
xlatedImage = imtranslate(frame1,[0 0 50],"cubic","OutputView","same");

img1 = squeeze(frame1(mids(1),:,:));
img2 = squeeze(xlatedImage(mids(1),:,:));

figure(1)
subplot(1,2,1)
imshow(img1,[]);
subplot(1,2,2)
imshow(img2, []);


%% rotate the image

rotated = imrotate3(frame1,90,[0 0 1],"cubic","crop");

img1 = squeeze(frame1(mids(1),:,:));
img2 = squeeze(rotated(mids(1),:,:));

figure(1)
subplot(1,2,1)
imshow(img1, []);
subplot(1,2,2)
imshow(img2, []);

%% get coordinates/interact with image
img1 = squeeze(frame1(mids(1),:,:));
sz  = size(img1);

figure(1)
imshow(img1,[]);
title(sprintf("Image dimensions: %i x %i",sz(1),sz(2)));

[x, y] = ginput(1);

msgbox(sprintf("You clicked point: %f, %f",x,y));

%% Use input to reorient the image
% task the user to click two points.

figure(1)

img1 = squeeze(frame1(mids(1),:,:));
imshow(img1, []);
title("please click the apex and base of the heart");

[x, y] = ginput(2);

title("Thank you for your clicks!")

% calculate the midpoint of the line
cx = (x(2) + x(1))/2
cy = (y(2) + y(1))/2

centerImg = size(img1)/2;

delta = -[cx-centerImg(2) cy-centerImg(1)];

xlatedImg = imtranslate(img1,delta,"cubic","OutputView","same");
imshow(xlatedImg, []);

theta = atand((x(2)-x(1))/(y(2)-y(1)));

rotatedImg = imrotate(xlatedImg, theta, "bicubic");
figure(1);
imshow(rotatedImg,[]);

%% Get user input (drawfreehand)
roi = drawfreehand();


%% 
mask = roi.createMask();
imshow(mask);

count = sum(mask(:));

dx = dataset.widthspan/dataset.width;
dy = dataset.heightspan/dataset.height;
dz = dataset.depthspan/dataset.depth;

dA = dy*dz;

area = count * dA;
sprintf("Area of this cut of the LV: %2.2f cm^2",area)