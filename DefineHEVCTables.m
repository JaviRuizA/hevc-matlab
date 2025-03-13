M_Mat = cell(4,1);      % To hold the HEVC transform tables
Quant_Mat = cell(4,1);  % To hold the HEVC direct  Quantization tables
IQuant_Mat = cell(4,1); % To hold the HEVC inverse Quantization tables

M4_Mat = [64, 64, 64, 64; 83, 36, -36, -83; 64, -64, -64, 64; 36, -83, 83, -36];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% HEVC Transform Tables
%%%%%%%%%%% 4, 8, 16, 32 sizes

M8_Mat = [64, 64, 64, 64, 64, 64, 64, 64;...
    89, 75, 50, 18, -18, -50, -75, -89;...
    83, 36, -36, -83, -83, -36, 36, 83;...
    75, -18, -89, -50, 50, 89, 18, -75;...
    64, -64, -64, 64, 64, -64, -64, 64;...
    50, -89, 18, 75, -75, -18, 89, -50;...
    36, -83, 83, -36, -36, 83, -83, 36;...
    18, -50, 75, -89, 89, -75, 50, -18];

M16_Mat = [64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64;...
     90, 87, 80, 70, 57, 43, 25, 9, -9, -25, -43, -57, -70, -80, -87, -90;...
     89, 75, 50, 18, -18, -50, -75, -89, -89, -75, -50, -18, 18, 50, 75, 89;...
     87, 57, 9, -43, -80, -90, -70, -25, 25, 70, 90, 80, 43, -9, -57, -87;...
     83, 36, -36, -83, -83, -36, 36, 83, 83, 36, -36, -83, -83, -36, 36, 83;...
     80, 9, -70, -87, -25, 57, 90, 43, -43, -90, -57, 25, 87, 70, -9, -80;...
     75, -18, -89, -50, 50, 89, 18, -75, -75, 18, 89, 50, -50, -89, -18, 75;...
     70, -43, -87, 9, 90, 25, -80, -57, 57, 80, -25, -90, -9, 87, 43, -70;...
     64, -64, -64, 64, 64, -64, -64, 64, 64, -64, -64, 64, 64, -64, -64, 64;...
     57, -80, -25, 90, -9, -87, 43, 70, -70, -43, 87, 9, -90, 25, 80, -57;...
     50, -89, 18, 75, -75, -18, 89, -50, -50, 89, -18, -75, 75, 18, -89, 50;...
     43, -90, 57, 25, -87, 70, 9, -80, 80, -9, -70, 87, -25, -57, 90, -43;...
     36, -83, 83, -36, -36, 83, -83, 36, 36, -83, 83, -36, -36, 83, -83, 36;...
     25, -70, 90, -80, 43, 9, -57, 87, -87, 57, -9, -43, 80, -90, 70, -25;...
     18, -50, 75, -89, 89, -75, 50, -18, -18, 50, -75, 89, -89, 75, -50, 18;...
     9, -25, 43, -57, 70, -80, 87, -90, 90, -87, 80, -70, 57, -43, 25, -9];
 
 M32_Mat = [64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64;...
     90, 90, 88, 85, 82, 78, 73, 67, 61, 54, 46, 38, 31, 22, 13, 4, -4, -13, -22, -31, -38, -46, -54, -61, -67, -73, -78, -82, -85, -88, -90, -90;...
     90, 87, 80, 70, 57, 43, 25, 9, -9, -25, -43, -57, -70, -80, -87, -90,-90, -87, -80, -70, -57, -43, -25, -9, 9, 25, 43, 57, 70, 80, 87, 90;...
     90, 82, 67, 46, 22, -4, -31, -54, -73, -85, -90, -88, -78, -61, -38, -13, 13, 38, 61, 78, 88, 90, 85, 73, 54, 31, 4,-22,-46,-67,-82,-90;...
     89, 75, 50, 18, -18, -50, -75, -89, -89, -75, -50, -18, 18, 50, 75, 89, 89, 75, 50, 18, -18, -50, -75, -89, -89, -75, -50, -18, 18, 50, 75, 89;...
     88, 67, 31, -13, -54, -82, -90, -78, -46, -4, 38, 73, 90, 85, 61, 22, -22, -61, -85, -90, -73, -38, 4, 46, 78, 90, 82, 54, 13, -31, -67, -88;...
     87, 57, 9, -43, -80, -90, -70, -25, 25, 70, 90, 80, 43, -9, -57, -87, -87, -57, -9, 43, 80, 90, 70, 25, -25, -70, -90, -80, -43, 9, 57, 87;...
     85, 46,-13, -67, -90, -73, -22, 38, 82, 88, 54, -4, -61, -90, -78, -31, 31, 78, 90, 61, 4,-54, -88, -82, -38, 22, 73, 90, 67, 13, -46, -85;...
     83, 36, -36, -83, -83, -36, 36, 83, 83, 36, -36, -83, -83, -36, 36, 83, 83, 36, -36, -83, -83, -36, 36, 83, 83, 36, -36, -83, -83, -36, 36, 83;...
     82, 22, -54, -90, -61, 13, 78, 85, 31, -46, -90, -67, 4, 73, 88, 38, -38, -88, -73, -4, 67, 90, 46, -31, -85, -78, -13, 61, 90, 54, -22,-82;...
     80, 9, -70, -87, -25, 57, 90, 43, -43, -90, -57, 25, 87, 70, -9, -80, -80, -9, 70, 87, 25, -57, -90, -43, 43, 90, 57,-25, -87, -70, 9, 80;...
     78, -4, -82, -73, 13, 85, 67, -22, -88, -61, 31, 90, 54, -38, -90, -46, 46, 90, 38, -54, -90, -31, 61, 88, 22, -67, -85, -13, 73, 82, 4, -78;...
     75, -18, -89, -50, 50, 89, 18, -75, -75, 18, 89, 50, -50, -89, -18, 75, 75, -18, -89, -50, 50, 89, 18, -75, -75, 18, 89, 50, -50, -89, -18, 75;...
     73, -31, -90, -22, 78, 67, -38, -90, -13, 82, 61, -46, -88, -4, 85, 54, -54, -85, 4, 88, 46, -61, -82, 13, 90, 38, -67, -78, 22, 90, 31, -73;...
     70, -43, -87, 9, 90, 25, -80, -57, 57, 80, -25, -90, -9, 87, 43, -70, -70, 43, 87, -9, -90, -25, 80, 57, -57, -80, 25, 90, 9, -87, -43, 70;...
     67, -54, -78, 38, 85, -22, -90, 4, 90, 13, -88,  -31, 82, 46, -73, -61, 61, 73, -46, -82, 31, 88, -13, -90, -4, 90, 22, -85, -38, 78, 54, -67;...
     64, -64, -64, 64, 64, -64, -64, 64, 64, -64, -64, 64, 64, -64, -64, 64, 64, -64, -64, 64, 64, -64, -64, 64, 64, -64, -64, 64, 64, -64, -64, 64;...
     61, -73, -46, 82, 31, -88, -13, 90, -4, -90, 22, 85, -38, -78, 54, 67, -67, -54, 78, 38, -85, -22, 90, 4, -90, 13, 88, -31, -82, 46, 73, -61;...
     57, -80, -25, 90, -9, -87, 43, 70, -70, -43, 87, 9, -90, 25, 80, -57, -57, 80, 25, -90, 9, 87, -43, -70, 70, 43, -87, -9, 90, -25, -80, 57;...
     54, -85, -4, 88, -46, -61, 82, 13, -90, 38, 67, -78, -22, 90, -31, -73, 73, 31, -90, 22, 78, -67, -38, 90, -13, -82, 61, 46, -88, 4, 85, -54;...
     50, -89, 18, 75, -75, -18, 89, -50, -50, 89, -18, -75, 75, 18, -89, 50, 50, -89, 18, 75, -75, -18, 89, -50, -50, 89, -18, -75, 75, 18, -89, 50;...
     46, -90, 38, 54, -90, 31, 61, -88, 22, 67, -85, 13, 73, -82, 4, 78, -78, -4, 82, -73, -13, 85, -67, -22, 88, -61, -31, 90, -54, -38, 90, -46;...
     43, -90, 57, 25, -87, 70, 9, -80, 80, -9, -70, 87, -25, -57, 90, -43, -43, 90, -57, -25, 87, -70, -9, 80, -80, 9, 70, -87, 25, 57, -90, 43;...
     38, -88, 73, -4, -67, 90, -46, -31, 85, -78, 13, 61, -90, 54, 22, -82, 82, -22, -54, 90, -61, -13, 78, -85, 31, 46, -90, 67, 4, -73, 88, -38;...
     36, -83, 83, -36, -36, 83, -83, 36, 36, -83, 83, -36, -36, 83, -83, 36, 36, -83, 83, -36, -36, 83, -83, 36, 36, -83, 83, -36, -36, 83, -83, 36;...
     31, -78, 90, -61, 4, 54, -88, 82, -38, -22, 73, -90, 67, -13, -46, 85, -85, 46, 13, -67, 90, -73, 22, 38, -82, 88, -54, -4, 61, -90, 78, -31;...
     25, -70, 90, -80, 43, 9, -57, 87, -87, 57, -9, -43, 80, -90, 70, -25, -25, 70, -90, 80, -43, -9, 57, -87, 87, -57, 9, 43, -80, 90, -70, 25;...
     22, -61, 85, -90, 73, -38, -4, 46, -78, 90, -82, 54, -13, -31, 67, -88, 88, -67, 31, 13, -54, 82, -90, 78, -46, 4, 38, -73, 90, -85, 61, -22;...
     18, -50, 75, -89, 89, -75, 50, -18, -18, 50, -75, 89, -89, 75, -50, 18, 18, -50, 75, -89, 89, -75, 50, -18, -18, 50, -75, 89, -89, 75, -50, 18;...
     13, -38, 61, -78, 88, -90, 85, -73, 54, -31, 4, 22, -46, 67, -82, 90, -90, 82, -67, 46, -22, -4, 31, -54, 73, -85, 90, -88, 78, -61, 38, -13;...
     9, -25, 43, -57, 70, -80, 87, -90, 90, -87, 80, -70, 57, -43, 25, -9, -9, 25, -43, 57, -70, 80, -87, 90, -90, 87, -80, 70, -57, 43, -25, 9;...
     4, -13, 22, -31, 38, -46, 54, -61, 67, -73, 78, -82, 85, -88, 90, -90, 90, -90, 88, -85, 82, -78, 73, -67, 61, -54, 46, -38, 31, -22, 13, -4];
 
M_Mat{1} = M4_Mat;
M_Mat{2} = M8_Mat;
M_Mat{3} = M16_Mat;
M_Mat{4} = M32_Mat;
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% HEVC Standard Quantization Tables

Weights4_Mat_Base = ones(4,4)*16; %[16, 16, 16, 16; 16, 16, 16, 16; 16, 16, 16, 16; 16, 16, 16, 16];

Weights8_Mat_Base = [16, 16, 16, 16, 17, 18, 21, 24;...
          16, 16, 16, 16, 17, 19, 22, 25;...
          16, 16, 17, 18, 20, 22, 25, 29;...
          16, 16, 18, 21, 24, 27, 31, 36;...
          17, 17, 20, 24, 30, 35, 41, 47;...
          18, 19, 22, 27, 35, 44, 54, 65;...
          21, 22, 25, 31, 41, 54, 70, 88;...
          24, 25, 29, 36, 47, 65, 88, 115];
      
% Parametro flat para saturación de CSF
flat=true;
% Calculamos los WeightsBase Propios para 4
%------------------------------------------------------------
[fRad4, csfMat4, w, fMax]=GetDCTWeights(600,12.23,4,6.54,flat);
iour4=1./csfMat4;
sour4=ScaleMatrix(iour4,16,115);
Weights4_Mat_Our=ceil(sour4);

% Calculamos los WeightsBase Propios para 8
%------------------------------------------------------------
[fRad8, csfMat8, w, fMax]=GetDCTWeights(600,12.23,8,6.54,flat);
iour8=1./csfMat8;
sour8=ScaleMatrix(iour8,16,115);
Weights8_Mat_Our=ceil(sour8);

% Calculamos los WeightsBase Propios para 16
%------------------------------------------------------------
[fRad16, csfMat16, w, fMax]=GetDCTWeights(600,12.23,16,6.54,flat);
iour16=1./csfMat16;
sour16=ScaleMatrix(iour16,16,115);
Weights16_Mat_Our=ceil(sour16);

% Calculamos los WeightsBase Propios para 32
%------------------------------------------------------------
[fRad32, csfMat32, w, fMax]=GetDCTWeights(600,12.23,32,6.54,flat);
iour32=1./csfMat32;
sour32=ScaleMatrix(iour32,16,115);
Weights32_Mat_Our=ceil(sour32);

csfMats{1}=csfMat4;
csfMats{2}=csfMat8;
csfMats{3}=csfMat16;
csfMats{4}=csfMat32;


% Fijamos la DC a 16 para que su cuantización no se vea alterada
if (~flat)
    Weights4_Mat_Our(1,1)=16;
    Weights8_Mat_Our(1,1)=16;
    Weights16_Mat_Our(1,1)=16;
    Weights32_Mat_Our(1,1)=16;
end

if (strcmp(WeightMode,'ourCSF'))
    Weights4_Mat=ScaleStandardWeightMatrix(Weights4_Mat_Our,'direct',4,Qp,true);
    IWeights4_Mat=ScaleStandardWeightMatrix(Weights4_Mat_Our,'inverse',4,Qp,true);
    
    Weights8_Mat=ScaleStandardWeightMatrix(Weights8_Mat_Our,'direct',8,Qp,true);
    IWeights8_Mat=ScaleStandardWeightMatrix(Weights8_Mat_Our,'inverse',8,Qp,true);
    
    Weights16_Mat=ScaleStandardWeightMatrix(Weights16_Mat_Our,'direct',16,Qp,true);
    IWeights16_Mat=ScaleStandardWeightMatrix(Weights16_Mat_Our,'inverse',16,Qp,true);
    
    Weights32_Mat=ScaleStandardWeightMatrix(Weights32_Mat_Our,'direct',32,Qp,true);
    IWeights32_Mat=ScaleStandardWeightMatrix(Weights32_Mat_Our,'inverse',32,Qp,true);
elseif (strcmp(WeightMode,'staCSF'))
    Weights4_Mat=ScaleStandardWeightMatrix(Weights8_Mat_Base,'direct',4,Qp);
    IWeights4_Mat=ScaleStandardWeightMatrix(Weights8_Mat_Base,'inverse',4,Qp);

    Weights8_Mat=ScaleStandardWeightMatrix(Weights8_Mat_Base,'direct',8,Qp);
    IWeights8_Mat=ScaleStandardWeightMatrix(Weights8_Mat_Base,'inverse',8,Qp);

    Weights16_Mat=ScaleStandardWeightMatrix(Weights8_Mat_Base,'direct',16,Qp);
    IWeights16_Mat=ScaleStandardWeightMatrix(Weights8_Mat_Base,'inverse',16,Qp);

    Weights32_Mat=ScaleStandardWeightMatrix(Weights8_Mat_Base,'direct',32,Qp);
    IWeights32_Mat=ScaleStandardWeightMatrix(Weights8_Mat_Base,'inverse',32,Qp);
elseif (strcmp(WeightMode,'CSF'))
    % Para PU=04 usamos ourCSF y para otros tamaños staCSF
    Weights4_Mat=ScaleStandardWeightMatrix(Weights4_Mat_Our,'direct',4,Qp,true);
    IWeights4_Mat=ScaleStandardWeightMatrix(Weights4_Mat_Our,'inverse',4,Qp,true);
    
    Weights8_Mat=ScaleStandardWeightMatrix(Weights8_Mat_Base,'direct',8,Qp);
    IWeights8_Mat=ScaleStandardWeightMatrix(Weights8_Mat_Base,'inverse',8,Qp);

    Weights16_Mat=ScaleStandardWeightMatrix(Weights8_Mat_Base,'direct',16,Qp);
    IWeights16_Mat=ScaleStandardWeightMatrix(Weights8_Mat_Base,'inverse',16,Qp);

    Weights32_Mat=ScaleStandardWeightMatrix(Weights8_Mat_Base,'direct',32,Qp);
    IWeights32_Mat=ScaleStandardWeightMatrix(Weights8_Mat_Base,'inverse',32,Qp);
end


%Seleccionamos las matrices de cuantización perceptual si aplica
if ( strcmp(WeightMode,'staCSF') || strcmp(WeightMode,'ourCSF') || strcmp(WeightMode,'CSF') )
    Quant4_Mat  = Weights4_Mat; 
    Quant8_Mat  = Weights8_Mat; 
    Quant16_Mat = Weights16_Mat; 
    Quant32_Mat = Weights32_Mat; 
    IQuant4_Mat = IWeights4_Mat;
    IQuant8_Mat = IWeights8_Mat;
    IQuant16_Mat = IWeights16_Mat;
    IQuant32_Mat = IWeights32_Mat;

    Weights_Mat{1} = Weights4_Mat;
    Weights_Mat{2} = Weights8_Mat;
    Weights_Mat{3} = Weights16_Mat;
    Weights_Mat{4} = Weights32_Mat;

    IWeights_Mat{1} = IWeights4_Mat;
    IWeights_Mat{2} = IWeights8_Mat;
    IWeights_Mat{3} = IWeights16_Mat;
    IWeights_Mat{4} = IWeights32_Mat;
else
    qp = rem(Qp,6)+1;
    directQuantScales=[26214 23302 20560 18396 16384 14564];
    scaleFactor=directQuantScales(qp);
    Quant4_Mat  = ones(4,4)*scaleFactor; 
    Quant8_Mat  = ones(8,8)*scaleFactor; 
    Quant16_Mat = ones(16,16)*scaleFactor; 
    Quant32_Mat = ones(32,32)*scaleFactor;  
    IQuant4_Mat  = Quant4_Mat; 
    IQuant8_Mat  = Quant8_Mat; 
    IQuant16_Mat = Quant16_Mat; 
    IQuant32_Mat = Quant32_Mat;  
end

%Matrices Uniformes
qp = rem(Qp,6)+1;
directQuantScales=[26214 23302 20560 18396 16384 14564];
scaleFactor=directQuantScales(qp);
Quant4_Mat_Uni  = ones(4,4)*scaleFactor; 
Quant8_Mat_Uni  = ones(8,8)*scaleFactor; 
Quant16_Mat_Uni = ones(16,16)*scaleFactor; 
Quant32_Mat_Uni = ones(32,32)*scaleFactor;  
IQuant4_Mat_Uni  = Quant4_Mat_Uni; 
IQuant8_Mat_Uni  = Quant8_Mat_Uni; 
IQuant16_Mat_Uni = Quant16_Mat_Uni; 
IQuant32_Mat_Uni = Quant32_Mat_Uni;  
Quant_Mat_Uni{1} = Quant4_Mat_Uni;
Quant_Mat_Uni{2} = Quant8_Mat_Uni;
Quant_Mat_Uni{3} = Quant16_Mat_Uni;
Quant_Mat_Uni{4} = Quant32_Mat_Uni;
IQuant_Mat_Uni{1} = IQuant4_Mat_Uni;
IQuant_Mat_Uni{2} = IQuant8_Mat_Uni;
IQuant_Mat_Uni{3} = IQuant16_Mat_Uni;
IQuant_Mat_Uni{4} = IQuant32_Mat_Uni;
%-----------------------------
             
Quant_Mat{1} = Quant4_Mat;
Quant_Mat{2} = Quant8_Mat;
Quant_Mat{3} = Quant16_Mat;
Quant_Mat{4} = Quant32_Mat;
IQuant_Mat{1} = IQuant4_Mat;
IQuant_Mat{2} = IQuant8_Mat;
IQuant_Mat{3} = IQuant16_Mat;
IQuant_Mat{4} = IQuant32_Mat;

function newWeightMat=ScaleStandardWeightMatrix(staWeightMat,mode,newSize,Qp,our)
    if ~exist('our','var') || isempty(our)
        our=false;
        MAX_MATRIX_SIZE_NUM = 8;
    else
        our=true;
        MAX_MATRIX_SIZE_NUM = size(staWeightMat,1);
    end
    
    
    qp = rem(Qp,6)+1;
    scalingListSizeX=[4 8 16 32];
    directQuantScales=[26214 23302 20560 18396 16384 14564];
    inverseQuantScales =[40 45 51 57 64 72];
    switch mode
        case 'direct'
            quantScales=bitshift(directQuantScales,4);
        case 'inverse'
            quantScales=inverseQuantScales;
        otherwise 
            error('ScaleStandardWeightMatrix: mode param does not match ''direct'' or ''inverse'' ');
    end
    
    %------------------------
    if (newSize==4)
        quantScale = quantScales(qp);
        switch mode
            case 'direct'
                if our
                    assert(size(staWeightMat,1)==4,'ScaleStandardWeightMatrix: Para our=true el tamaño de la matriz debe ser 4');
                    WeightsMat=int32(staWeightMat);
                    sizeId=find(scalingListSizeX==newSize);
                    ratio = uint32(scalingListSizeX(sizeId)/min(MAX_MATRIX_SIZE_NUM,scalingListSizeX(sizeId)));
                    step=1;
                    for r=1:4
                        for c=1:4
                            weight=double(WeightsMat(r,c));
                            ixR=(r-1)*ratio+1:(r-1)*ratio+step;
                            ixC=(c-1)*ratio+1:(c-1)*ratio+step;
                            newWeightMat(ixR,ixC)=floor(quantScale/weight);
                        end
                    end
                else
                    newWeightMat=ones(4,4)*floor(quantScale/16);
                end
            case 'inverse'
                if our
                    assert(size(staWeightMat,1)==4,'ScaleStandardWeightMatrix: Para our=true el tamaño de la matriz debe ser 4');
                    WeightsMat=int32(staWeightMat);
                    sizeId=find(scalingListSizeX==newSize);
                    ratio = uint32(scalingListSizeX(sizeId)/min(MAX_MATRIX_SIZE_NUM,scalingListSizeX(sizeId)));
                    step=1;
                    for r=1:4
                        for c=1:4
                            weight=double(WeightsMat(r,c));
                            ixR=(r-1)*ratio+1:(r-1)*ratio+step;
                            ixC=(c-1)*ratio+1:(c-1)*ratio+step;
                            newWeightMat(ixR,ixC)=quantScale*weight;
                        end
                    end
                else
                    newWeightMat=ones(4,4)*quantScale*16;
                end
        end
    else
        blockSize=newSize;
        WeightsMat=int32(staWeightMat);
        sizeId=find(scalingListSizeX==blockSize);
        ratio = uint32(scalingListSizeX(sizeId)/min(MAX_MATRIX_SIZE_NUM,scalingListSizeX(sizeId)));
        quantScale = quantScales(qp);
        
        newWeightMat=zeros(blockSize,blockSize);
        step=blockSize/MAX_MATRIX_SIZE_NUM;
        for r=1:MAX_MATRIX_SIZE_NUM
            for c=1:MAX_MATRIX_SIZE_NUM
                weight=double(WeightsMat(r,c));
                ixR=(r-1)*ratio+1:(r-1)*ratio+step;
                ixC=(c-1)*ratio+1:(c-1)*ratio+step;
                switch mode
                    case 'direct'
                        newWeightMat(ixR,ixC)=floor(quantScale/weight);
                        %                     if (any(any(newWeightMat(ixR,ixC)~=checkM(ixR,ixC))))
                        %                         dummy=1;
                        %                     end
                    case 'inverse'
                        newWeightMat(ixR,ixC)=quantScale*weight;
                end
            end
        end
    end
end




