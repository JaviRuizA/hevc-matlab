function [fRad,csfMat,csfWeights,fMaxCyDg]=GetDCTWeights(ppi,vd,nbins,maxWeight,flat)
if ~exist('flat','var') || isempty(flat)
  flat=false;
else
    flat=true;
end

%[fMaxPxDg,fMaxCyDg,vdCm]=GetFMax(ppi,vd);
[~,fMaxCyDg,~]=GetFMax(ppi,vd);

%step=fMaxCyDg/2^nbins;
faxis=[0:0.01:fMaxCyDg];
numbins=size(faxis,2);

%Ploteamos la curva CSF escalada por SF
Hf = zeros(1,numbins);
for fq=1:numbins
    %         Hf(fq)=H(faxis(fq),umbral+delta);
    Hf(fq)=H(faxis(fq));
end

%figure; plot(faxis,Hf,'b');
%xlabel('Cycles/degree');
%ylabel('Normalized Contrast Sensitivity');
%hold on; 

%fqMax=faxis(find(Hf==max(Hf(:))));
fqMax=faxis(Hf==max(Hf(:)));

%f_max_hvs=max(Hf);

%Saturamos la curva si flat
if flat
    maxCSF=max(Hf);
    fq=1;
    while Hf(fq)<maxCSF
        Hf(fq)=maxCSF;
        fq=fq+1;
    end
end

%plot(faxis,Hf,'r');
%hold off; 

%Distancia visual en metros.
%v=(vd*0.0254);

%Frecuencia lineal máxima para corresponder con la radial
f_lin_max=fMaxCyDg/sqrt(2);

%Frecuencias por bin
f_lin_bin=f_lin_max/nbins;

%El valor de frecuencia asignado a cada bin es el minimo del bin.
%Calculamos con ello la matriz de frequencias espaciales para nbins x nbins
%rFr=[];
%cFr=[];
fRad=zeros(nbins,nbins);
for r=1:nbins
    for c=1:nbins
        fr=(r-1)*f_lin_bin;
        fc=(c-1)*f_lin_bin;
        fRad(r,c)=sqrt(fr^2+fc^2);
    end
end

%Saturamos la curva si flat
if flat
    fOverMax=find(fRad>fqMax);
    ixfRadMax=fOverMax(1);
    fRadMax=fRad(ixfRadMax);
    fRad(fRad<fRadMax)=fRadMax;
end


%Calculamos la matriz csf 
csfMat=zeros(nbins,nbins);
for r=1:nbins
    for c=1:nbins
        csfMat(r,c)=H(fRad(r,c));
    end
end

%Calculamos el valor normalizado entre 0 y 1 de csfMat
%csfNorm=ScaleMatrix(csfMat,0,1);

%Calculamos el valor escaladao entre entre 1 y maxWeight para csfNorm
csfScaled=ScaleMatrix(csfMat,1,maxWeight);
csfWeights=csfScaled;
end