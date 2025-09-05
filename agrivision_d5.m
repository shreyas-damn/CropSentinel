load("Indian_pines_corrected.mat");
cube=double(indian_pines_corrected);
[H,W,B]=size(cube);
ncube=cube;
for b=1:B
    band=cube(:,:,b);
    lo=prctile(band(:),1);
    hi=prctile(band(:),99);
    ncube(:,:,b)=min(max((band-lo)/max(hi-lo+eps),0),1);
end

wavelengths=linspace(400,2500,B);
nearestband=@(target)find(abs(wavelengths-target)==min(abs(wavelengths-target)),1);
i470=nearestband(470);
i550=nearestband(550);
i670=nearestband(670);
i740=nearestband(740);
i860=nearestband(860);
i1240=nearestband(1240);
i1600=nearestband(1600);

r470=cube(:,:,i470);
r550=cube(:,:,i550);
r670=cube(:,:,i670);
r740=cube(:,:,i740);
r860=cube(:,:,i860);
r1240=cube(:,:,i1240);
r1600=cube(:,:,i1600);

ndvi=(r860-r670)./(r860+r670+eps);
ndwi=(r860-r1240)./(r860+r1240+eps);
cire=(r860./(r740+eps))-1;
msi=(r1600./(r860+eps));
psri=(r670-r550)./(r740+eps);
L=0.5;
savi=((r860-r550)./(r860+r670+eps));

figure;
subplot(2,3,1);
imagesc(ndvi); axis image; colorbar;
title('NDVI (NIR - Red / NIR + Red)'); colormap(gca, jet);

subplot(2,3,2);
imagesc(ndwi); axis image; colorbar;
title('NDWI (NIR - SWIR / NIR + SWIR)'); colormap(gca, jet);

subplot(2,3,3);
imagesc(cire); axis image; colorbar;
title('CIRE (NIR / RedEdge - 1)'); colormap(gca, jet);

subplot(2,3,4);
imagesc(msi); axis image; colorbar;
title('MSI (SWIR / NIR)'); colormap(gca, jet);

subplot(2,3,5);
imagesc(psri); axis image; colorbar;
title('PSRI ((Red - Green) / RedEdge)'); colormap(gca, jet);

subplot(2,3,6);
imagesc(savi); axis image; colorbar;
title('SAVI ((NIR-Red)/(NIR+Red+L))'); colormap(gca, jet);

