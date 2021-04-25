%%select video
[FileName, Path]=uigetfile({'*.avi;*.mp4;*.wmv','Video Files';...
          '*.*','All Files' },'Abrir Video');
      pathToFile = fullfile(Path,FileName);
%% Read Video
videoReader = vision.VideoFileReader(pathToFile);
framesExploracion=0;
%% Create Video Player
videoPlayer = vision.VideoPlayer;
fgPlayer = vision.VideoPlayer;

%% Create Foreground Detector (Background Substraction)
foregroundDetector = vision.ForegroundDetector('NumGaussians', 3, ...
    'NumTrainingFrames', 50);
% Run on first 50 frames to learn background
%%
%Region de Interes
videoFrame = imcrop(step(videoReader),[120 84.5 375 366.9]);

%Circulos
rgb = rgb2gray(videoFrame);
[centers2, radii2,metric] = imfindcircles(rgb,[12 15], 'ObjectPolarity','bright', ...
          'Sensitivity',0.974);

%Tomar inicio
step(videoPlayer,videoFrame);
uiwait(msgbox('Por favor cierre el video desde el momento en que el ratón comienza el recorrido','','modal'));
while isOpen(videoPlayer)
    videoFrame = imcrop(step(videoReader),[120 84.5 375 366.9]);
    step(videoPlayer,videoFrame);
end
framesExploracion=framesExploracion+1;
%%
for i=1:60
    videoFrame = imcrop(step(videoReader),[120 84.5 375 366.9]);
    foreground = step(foregroundDetector,videoFrame);
    framesExploracion=framesExploracion+1;
end
%inputFigure=figure;imshow(videoFrame);title('Input Frame');
%foregroundFigure=figure;imshow(foreground);title('Foreground');

%% Perform morphology to clean up foreground
cleanForeground = imopen(foreground, strel('Octagon',3));
%morphlogyFigure=figure;
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
        agujerosVisitados=0;
        visitado=0;
        ultimox=0;
        ultimoy=0;
        Distx=19;
        Disty=8;
        iiii=0;
        framesPrimerAgujero=0;
        videoFrame = imcrop(step(videoReader),[120 84.5 375 366.9]);
        framesExploracion=framesExploracion+1;
        [tamx tamy capas]=size(videoFrame);
        limitcenters2=size(centers2);
    for i=1:limitcenters2(1)
        centers2(i)=(centers2(i)-(tamx/2))-15;
        centers2(i,2)=-((centers2(i,2)-(tamy/2)-7));
    end
    
    foreground = step(foregroundDetector,videoFrame);
    cleanForeground =imopen(foreground, strel('Octagon',3));
    
    %% Detect the connected components with the specified minimum area, and compute their bounding boxes
    bbox = step(blobAnalysis, cleanForeground);
     x = [x (bbox(1)-(tamx/2))];
     y = [y -(bbox(2)-(tamy/2))];
     antx=x(1);
    %% Draw bounding boxes around the detected cars
    result = insertShape(videoFrame,'Rectangle', bbox,'Color','green');
    
    %% Count number of objects
        numObjects = size(bbox,1);
figure;
while numObjects<4
    % get the next frame and cut it
    videoFrame = imcrop(step(videoReader),[120 84.5 375 366.9]);
    framesExploracion=framesExploracion+1;
    % Video Processing Code Goes Here
    foreground = step(foregroundDetector,videoFrame);
    cleanForeground =imopen(foreground, strel('Octagon',3));
    
    %% Detect the connected components with the specified minimum area, and compute their bounding boxes
    bbox = step(blobAnalysis, cleanForeground);
    
    %% Draw bounding boxes around the detected rat
    result = insertShape(videoFrame,'Rectangle', bbox,'Color','green');
    % Count number of objects
    numObjects = size(bbox,1);
    if numObjects==1 
        %% Draw the Rat's path
        if( (abs(antx-(bbox(1)-(tamx/2)))<10) )
            posx=(bbox(1)-(tamx/2));
            posy=-(bbox(2)-(tamy/2));
           x = [x posx];
           y = [y posy];
           plot(x,y)
           axis([-(tamx/2) (tamx/2) -(tamy/2) (tamy/2)]);
           iiii=iiii+1;
           hold on
           %% Incert circles
           if iiii == 1
              viscircles(centers2,radii2);
           end
            %Put circle numbers
            %for i=1:limitcenters2(1)  
            %text(centers2(i),centers2(i,2),num2str(i),'HorizontalAlignment','center');    
            %end  
            
            %% Detect Exploration and count it
            for i=1:limitcenters2(1)
                visitado=visitado+1;
                if(abs(posx-centers2(i))<20 && abs(posy-centers2(i,2))<15 )
                    if(visitado == 1)
                        if(agujerosVisitados>3)
                            Distx=11;
                            if (agujerosVisitados>4)
                                Disty=6;
                            end
                        end
                        if(abs(posx-ultimox)>Distx && abs(posy-ultimoy)>Disty)
                            agujerosVisitados=agujerosVisitados+1;
                            text(centers2(i),centers2(i,2),'Exploracion','HorizontalAlignment','center');
                            if(agujerosVisitados == 1)
                                framesPrimerAgujero=framesExploracion;
                            end
                        end
                    end
                    ultimox=centers2(i);
                    ultimoy=centers2(i,2);
                else
                    visitado=0;
                end
                
            end
            if(abs(posx-ultimox)<50 && abs(posy-ultimoy)<35 )
                visitado=0;
            end
            
        end
    end

    %end of video processing code
    %% Display output
    step(videoPlayer,result);
    
    %step(fgPlayer,cleanForeground);
    if (numObjects==1 && ((abs(antx-(bbox(1)-(tamx/2)))<10)))    
        antx=bbox(1)-(tamx/2);
    end
end
    %% Polt en polares - No es necesario
    %figure;
    %[theta,rho]=cart2pol(double(x),double(y));
    %polar(theta,rho);
    
    %% Data for Analysis
    % Distancia cm
    tammx=size(x);
    dist=0;
    for ij=2:tammx(2)
        dist=dist+sqrt(double(((x(ij))-(x(ij-1)))^2+((y(ij))-(y(ij-1)))^2));
    end
    distReal=((dist*(9.5))/26)/3;    
    %%
    display(strcat('Distancia total recorrida: ',num2str(distReal,'  %10.2f '),' cm'));
    %% 
    %Latencia de escape / Tiempo de exploracion segs
    tiempoExploracion=framesExploracion/videoReader.info.VideoFrameRate;
    %%
    display(strcat('Latencia de escape: ',num2str(tiempoExploracion,'  %10.2f '),' seg'));
    %% 
    %Latencia al primer agujero / Tiempo al primer agujero segs
    latenciaPrimerAgujero=framesPrimerAgujero/videoReader.info.VideoFrameRate;
    %%
    display(strcat('Latencia primer agujero: ',num2str(latenciaPrimerAgujero,'  %10.2f '),' seg'));
    %% 
    %Agujeros Errados
    agujerosErrados=agujerosVisitados-1;
    %%
     display(strcat('Agujeros errados: ',num2str(agujerosErrados)));
    %% 
    %Velocidad media cm/seg
    velocidadMedia=distReal/tiempoExploracion;
    %%
     display(strcat('Velocidad media: ',num2str(velocidadMedia,'  %10.2f '),' cm/seg'));
    %% 
    %Exploraciones totales
    agujerosVisitados;
    %%
     display(strcat('Frecuencia de exploraciones totales: ',num2str(agujerosVisitados)));
    %% 
    %Distancia media a meta
    distanciaMediaAMeta= distReal/agujerosVisitados;
    %%
     display(strcat('Distancia media a meta: ',num2str(distanciaMediaAMeta,'  %10.2f '),' cm'));
    %% Datos finales
    text(double(ultimox+80),double(ultimoy),'\leftarrow Escape','HorizontalAlignment','right');
    text(0,(tamy/2)-13,strcat('Distancia recorrida:_',num2str(distReal,'  %10.2f '),'cm  ','___Tiempo total de exploración:_',num2str(tiempoExploracion,'%10.2f'),' seg'),'HorizontalAlignment','center');  
%% release video reader and writer
release(videoPlayer);
release(videoReader);
delete(videoPlayer);