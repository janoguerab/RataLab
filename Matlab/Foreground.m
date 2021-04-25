%% Read Video

videoReader = vision.VideoFileReader('Rata.avi');

%% Create Video Player
videoPlayer = vision.VideoPlayer;
fgPlayer = vision.VideoPlayer;

%% Create Foreground Detector (Background Substraction)

foregroundDetector = vision.ForegroundDetector('NumGaussians', 3, ...
    'NumTrainingFrames', 50);
% Run on first 200 frames to learn background
%%
videoFrame = step(videoReader);
step(videoPlayer,videoFrame);
while isOpen(videoPlayer)
    videoFrame = step(videoReader);
    step(videoPlayer,videoFrame);
end

for i=1:175
    videoFrame = step(videoReader);
    foreground = step(foregroundDetector,videoFrame);
end
%figure;imshow(videoFrame);title('Input Frame');
%figure;imshow(foreground);title('Foreground');

%% Perform morphology to clean up foreground
cleanForeground = imopen(foreground, strel('Octagon',3));
%figure;
%subplot(1,2,1);imshow(foreground);title('Original Foreground');
%subplot(1,2,2);imshow(cleanForeground);title('Clean Foreground');

%% Create blob analysis object
% Blob analysis object futher filters the detected foreground by rejecting
% blobs than 150 pixels.

blobAnalysis = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
    'AreaOutputPort', false, 'CentroidOutputPort', false,...
    'MinimumBlobArea', 150);

%% Loop through video
    show(videoPlayer);
        x=[];
        y=[];
        antx=33;
        videoFrame = step(videoReader);
    foreground = step(foregroundDetector,videoFrame);
    cleanForeground =imopen(foreground, strel('Octagon',3));
    
    % Detect the connected components with the specified minimum area, and
    % compute their bounding boxes
    bbox = step(blobAnalysis, cleanForeground);
    
    % Draw bounding boxes around the detected cars
    result = insertShape(videoFrame,'Rectangle', bbox,'Color','green');
    
    % Display the number of objects
    numObjects = size(bbox,1);

while numObjects<4
    %% get the next frame
    videoFrame = step(videoReader);
    %% Video Processing Code Goes Here
    foreground = step(foregroundDetector,videoFrame);
    cleanForeground =imopen(foreground, strel('Octagon',3));
    
    % Detect the connected components with the specified minimum area, and
    % compute their bounding boxes
    bbox = step(blobAnalysis, cleanForeground);
    
    % Draw bounding boxes around the detected cars
    result = insertShape(videoFrame,'Rectangle', bbox,'Color','green');
    % Display the number of objects
    numObjects = size(bbox,1);
    if numObjects==1 
        if(abs(antx-(bbox(1)-240))<15)
           x = [x (bbox(1)-240)];
           y = [y -(bbox(2)-320)];
           plot(x,y);
        end
    end

    %end of video processing code
    
    %% Display output
    step(videoPlayer,result);
    %step(fgPlayer,cleanForeground);
    if (numObjects==1 && abs(antx-(bbox(1)-240))<15)
        antx=bbox(1)-240;
    end
end
%%
    figure;
    [theta,rho]=cart2pol(double(x),double(y));
    polar(theta,rho)
%% release video reader and writer
release(videoPlayer);
release(videoReader);
delete(videoPlayer); %delete wil cause viewer to close


for i=1:100
    videoFrame = imcrop(step(videoReader),[120 84.5 375 366.9]);
end
y=rgb2gray(videoFrame);
figure;imshow(videoFrame);
figure;imshow(y);

A=zeros(1,720);
B=zeros(1,720);
for i=1:720
    videoFrame = imcrop(step(videoReader),[120 84.5 375 366.9]);
    y=rgb2gray(videoFrame);
    A(i) = y(157,178);
    B(i) = y(347,4);
end
figure;imshow(videoFrame);
figure;imshow(y);

figure
plot(1:720,A)
title('Punto dentro de la mesa')
xlabel('Frame')
ylabel('Valor(intensidad)');

figure
plot(1:720,B)
title('Punto fuera de la mesa')
xlabel('Frame')
ylabel('Valor(intensidad)');

tblA=tabulate(A);
tblB=tabulate(B);

figure
plot(tblA(:,1),tblA(:,2))
title('Punto dentro de la mesa')
xlabel('Valor(intensidad)')
ylabel('Freuencia');

figure
plot(tblB(:,1),tblB(:,2))
title('Punto fuera de la mesa')
xlabel('Valor(intensidad)')
ylabel('Frecuencia');

%promedio A
promA=sum(A)/720;

%promedio B
promB=sum(B)/720;