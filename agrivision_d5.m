load("Indian_pines_corrected.mat");
cube=double(indian_pines_corrected);
[H,W,B]=size(cube);
wavelengths=linspace(400,2500,B);
hcube=imhypercube(cube,wavelengths);

ncube=cube;
for b=1:B;
    band=cube(:,:,b);
    lo=prctile(band(:),1);
    hi=prctile(band(:),99);
    ncube(:,:,b) = min(max((band-lo)/(hi-lo+eps),0),1);

end

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
%saveas(gca,'NDVI heatmap.png');

figure;
imagesc(NDWI,[-1 1]);
colormap(gca,jet);
colorbar; 
axis image;
title('NDWI Heatmap');
%saveas(gca,'NDWI heatmap.png');

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

sum(healthy_mask)
sum(moderate_mask)
sum(unhealthy_mask)

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
%saveas(gca,'HEALTH MONITOR.png');






