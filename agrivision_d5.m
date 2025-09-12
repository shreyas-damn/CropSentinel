%loading and storing as a 3d array
load("Indian_pines_corrected.mat");
cube=double(indian_pines_corrected);
[H,W,B]=size(cube);
wavelengths=linspace(400,2500,B);
hcube=imhypercube(cube,wavelengths);
%using zscaling
%removal of extreme noise normalizing to 0 and 1
%ncube=cube;
%for b=1:B
    %band=cube(:,:,b);
    %mu=mean(band(:));
    %std_dev=std(band(:));
    %ncube(:,:,b)=(band-mu)/(std_dev+eps);
%end

%perceentile scaling
%ncube = cube;
%for b = 1:B
    %band = cube(:,:,b);
    %lo = prctile(band(:), 1);
    %hi = prctile(band(:), 99);
    %ncube(:,:,b) = min(max((band - lo) / (hi - lo + eps), 0), 1);
%end

ncube = cube; 
for b = 1:B
    band = cube(:,:,b);
    lo = min(band(:));
    hi = max(band(:));
    ncube(:,:,b) = (band - lo) / (hi - lo + eps);  % scale to [0,1]
end

wavelengths=linspace(400,2500,B);
nearestband=@(target)find(abs(wavelengths-target)==min(abs(wavelengths-target)),1);

%finding band equivilant index value for wavelength
idx_red=nearestband(650); 
idx_rededge=nearestband(720);
idx_NIR=nearestband(850);
idx_SWIR=nearestband(1250);

red_band=ncube(:,:,idx_red);
rededge_band=ncube(:,:,idx_rededge);
NIR_band=ncube(:,:,idx_NIR);
SWIR_band=ncube(:,:,idx_SWIR);


NDVI=(NIR_band-red_band)./(NIR_band+red_band);

%{
L = zeros(size(NDVI));
L(NDVI >= 0.6) = 1;              % Dense
L(NDVI >= 0.4 & NDVI < 0.6) = 2;  % Moderate
L(NDVI >= 0.2 & NDVI < 0.4) = 3;  % Sparse
L(NDVI < 0.2) = 4;               % No vegetation
rgbimg=colorize(hcube,Method="rgb",ContrastStretching=true);
cmap = [0 1 0; 0 0 1; 1 1 0; 1 0 0];
figure;
imagesc(L);
colormap(cmap);           
colorbar('Ticks',1:4, 'TickLabels',{'Dense','Moderate','Sparse','None'});
title('Vegetation Classification (NDVI Thresholds)');
axis image;
%}

NDWI = (NIR_band - SWIR_band) ./ (NIR_band + SWIR_band + eps);

%{
figure;
imagesc(NDWI);
colormap(winter);        % nice blue gradient
colorbar;
title('NDWI Map');
axis image;
clim([-1 1])
%}

CIRE=((NIR_band)./(rededge_band+eps))-1;

%{
figure;
imagesc(CIRE);
colormap("autumn");
title("CIRE MAP");
axis image;
clim([0 5])
%}

labels = (NDVI > 0.3 & NDWI > -0.1 & CIRE > 1.5);

%{
img=double(labels);
figure;
imagesc(labels);
cmap=[1 0 0 ; 0 1 0];
colormap(cmap);
%}

y=categorical(labels);


patch_size=11;
pad=floor(patch_size/2);
padded_cube=padarray(cube,[pad pad 0],'symmetric');
num_pixels=H*W;
xpatch=zeros(patch_size,patch_size,B,num_pixels);
ypatch=zeros(num_pixels,1);

idx=1;
for i=1:H
    for j=1:W
        patch=padded_cube(i:i+patch_size-1,j:j+patch_size-1,:);
        xpatch(:,:,:,idx)=patch;
        ypatch(idx)=labels(i,j);
        idx=idx+1;
    end
end
ypatch=categorical(ypatch);

xseq=cell(num_pixels,1);
for n=1:num_pixels
    seq=squeeze(xpatch(:,:,:,n));
    seq=reshape(seq,[],B);
    xseq{n}=seq;
end

cv=cvpartition(ypatch,'HoldOut',0.2);
xtrain=xseq(training(cv));
ytrain=ypatch(training(cv));
xtest=xseq(test(cv));
ytest=ypatch(test(cv));

inputsize=patch_size^2;
numclasses=2;

layers=[
    sequenceInputLayer(inputsize);
    fullyConnectedLayer(64);
    reluLayer
    lstmLayer(64,'OutputMode','last');
    fullyConnectedLayer(numclasses);
    softmaxLayer
    classificationLayer;
];
options = trainingOptions('adam', ...
    'MaxEpochs',5, ...
    'MiniBatchSize',128, ...
    'Plots','training-progress', ...
    'Verbose',false, ...
    'ValidationData',{xtest,ytest});
net=trainNetwork(xtrain,ytrain,layers,options);

ypred=classify(net,xtest);
accuracy=mean(ypred==ytest);
disp('Test accuracy='+accuracy)

