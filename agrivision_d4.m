load("Indian_pines_corrected.mat");
cube=double(indian_pines_corrected);
[H,W,B]=size(cube);
ncube=cube;
for b =1:B
    band=cube(:,:,b);
    lo=prctile(band(:),1);
    hi=prctile(band(:),99);
    ncube(:,:,b)=min(max((band-lo)/max(hi-lo,eps),0),1);
end

wavelengths=linespace(:,:,B);
nearestband=@(target) find(abs(wavelengths-target)==...
    min(abs(wavelengths)),1);
i670=nearestband(670);
i860=nearestband(860);
i1240=nearestband(1240);
r670=ncube(:,:,i670);
r860=ncube(:,:,i860);
r1240=ncube(:,:,i1240);
ndvi=(r860-r670)./(r680+r860+eps);
ndwi=(r680=r1240)./(r1240+r860+eps);
