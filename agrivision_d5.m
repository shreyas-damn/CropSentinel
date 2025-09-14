%loading the hyperspectral images
load("Indian_pines_corrected.mat");
cube=double(indian_pines_corrected);
[H,W,B]=size(cube);
wavelengths=linspace(400,2500,B);
hcube=imhypercube(cube,wavelengths);

%normalizing using percentage scaling 
ncube=cube;
for b=1:B;
    band=cube(:,:,b);
    lo=prctile(band(:),1);
    hi=prctile(band(:),99);
    ncube(:,:,b) = min(max((band-lo)/(hi-lo+eps),0),1);

end

%extracting indices of NDVI NDWI CIRE etc.
nearestband=@(target)find(abs(wavelengths-target)==min(abs(wavelengths-target)),1);

idx_red=nearestband(670);
idx_rededge=nearestband(740);
idx_NIR=nearestband(860);
idx_SWIR=nearestband(1240);

redband=ncube(:,:,idx_red);
rededgeband=ncube(:,:,idx_rededge);
NIR_band=ncube(:,:,idx_NIR);
SWIR_band=ncube(:,:,idx_SWIR);

NDVI=(NIR_band-redband)./(NIR_band+redband+eps);
NDWI=(NIR_band-SWIR_band)./(NIR_band+SWIR_band+eps);
CIRE=(NIR_band./(rededgeband+eps))-1;

%PLOTTING IMAGES
%figure using subplots
%{
figure;
subplot(1,3,1);
imagesc(ndvi); axis image; colorbar;
title('NDVI (NIR - Red / NIR + Red)'); colormap(gca, jet);
    
subplot(1,3,2);
imagesc(ndwi); axis image; colorbar;
title('NDWI (NIR - SWIR / NIR + SWIR)'); colormap(gca, jet);
    
subplot(1,3,3);
imagesc(cire); axis image; colorbar;
title('CIRE (NIR / RedEdge-1)'); colormap(gca, jet);
%}

figure;
imagesc(NDVI,[-1 1]);
colormap(gca,jet);
colorbar; 
axis image;
title('NDVI Heatmap');
saveas(gca,'NDVI heatmap.png');

figure;
imagesc(NDWI,[-1 1]);
colormap(gca,jet);
colorbar; 
axis image;
title('NDWI Heatmap');
saveas(gca,'NDWI heatmap.png');

figure;
imagesc(CIRE,[0 3]);
colormap(gca,jet);
colorbar; 
axis image;
title('CIRE Heatmap');
%saveas(gca,'CIRE heatmap.png');

healthy_mask=(NDVI>0.5 & NDWI>0 & CIRE>2);
moderate_mask=(NDVI<0.5 & NDVI>0.2 & NDWI<0 & NDWI>-0.2 & CIRE<2 & CIRE>0.5);
unhealthy_mask=(NDVI<0.2 & NDWI<-0.2 & CIRE<0.5);

%{
sum(healthy_mask);
sum(moderate_mask);
sum(unhealthy_mask);
%}

labels=zeros(H,W);
labels(unhealthy_mask)=0;
labels(moderate_mask)=1;
labels(healthy_mask)=2;

figure;
imagesc(labels);
cmap=[1 0 0;0 0 1;0 1 0];
colormap(cmap);
caxis([0 2]);
axis image;

%CNN 
patch_size=7;
pad=floor(patch_size/2);
padded_cube=padarray(ncube,[pad pad 0],'symmetric');
num_pixels=H*W;

xpatch=zeros(patch_size,patch_size,B,num_pixels);
ypatch=zeros(num_pixels,1);

%extracting 7*7*200 patches
index=1;
for i=1:H
    for j=1:W
        patch=padded_cube(i:i+patch_size-1,j:j+patch_size-1,:);
        xpatch(:,:,:,index)=patch;
        ypatch(index)=labels(i,j);
        index=index+1;
    end
end

%training/testing split
ypatch=categorical(ypatch(:));
cv=cvpartition(ypatch,'HoldOut',0.2);
xtrain=xpatch(:,:,:,training(cv));
ytrain=ypatch(training(cv));
xtest=xpatch(:,:,:,test(cv));
ytest=ypatch(test(cv));

xtrain=reshape(xtrain,patch_size,patch_size,B,1,[]);
xtest=reshape(xtest,patch_size,patch_size,B,1,[]);

inputSize=[patch_size patch_size B 1];
numclasses=numel(categories(ytrain));


%llm generated 3d cnn model
layers = [
    image3dInputLayer(inputSize,'Name','input')
    
    convolution3dLayer([3 3 3],16,'Padding','same','Name','conv1')
    batchNormalizationLayer('Name','bn1')
    reluLayer('Name','relu1')
    maxPooling3dLayer(2,'Stride',2,'Name','pool1')

    convolution3dLayer([3 3 3],32,'Padding','same','Name','conv2')
    batchNormalizationLayer('Name','bn2')
    reluLayer('Name','relu2')
    maxPooling3dLayer(2,'Stride',2,'Name','pool2')

    fullyConnectedLayer(64,'Name','fc1')
    reluLayer('Name','relu3')
    fullyConnectedLayer(numclasses,'Name','fc2')
    softmaxLayer('Name','softmax')
    classificationLayer('Name','classoutput')
];

options = trainingOptions('adam', ...
    'MaxEpochs',10, ...
    'MiniBatchSize',128, ...
    'Shuffle','every-epoch', ...
    'ValidationData',{xtest,ytest}, ...
    'Plots','training-progress', ...
    'Verbose',true);

net = trainNetwork(xtrain,ytrain,layers,options);

ymap=zeros(H,W);
pad_cube=padarray(ncube,[pad pad],'symmetric');
for i=1:H
    for j=1:W
        patch=pad_cube(i:i+patch_size-1,j:j+patch_size-1,:);
        patch=reshape(patch, patch_size,patch_size,B,1);
        pred=classify(net,patch);
        ymap(i,j)=double(pred);
    end
end

figure;
imagesc(ymap);
colormap([1 0 0;0 0 1;0 1 0]);
colorbar;
axis image;
saveas(gca,'Predicted health_map.png');


