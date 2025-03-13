function [ bits, bpp, bps, kbps, Mbps ] = GetImageRate( yuvSequence, frame, framerate, mode, ctusize, nlevels, qp, csfMode, bestmodeby)
%GETIMAGERATE Devuelve la entropia de los coeficientes de la imagen.
%  Basándose en el nombre de la secuencia busca el fichero .mat con los coeficientes de la imagen
%  y calcula la entropia de los mismos.
%
% Parámetros de entrada: 
%  yuvSequence  : Secuencia yuv en formato 4:2:0 
%  frame        : Frame del que calcular la entropia
%  framerate    : Velocidad de frames por segundo (FPS)
%  mode         : 'hevc' o 'phevc'
%  ctusize      : tamaño del ctu (32,16,8,4)
%  nlevels      : numero de descomposiciones del ctu en bloques iguales (0,1,2)
%  qp           : Valor de cuantización Qp
%  csfMode      : String que indica el tipo de csf aplicada. {'noCSF' 'staCSF' 'ourCSF' 'CSF'}
%  bestmodeby   : String que indica el método utilizado para seleccionar el
%                 mejor modo.
%                   para el mode 'hevc' : {'Coste' 'RD'}
%                   para el mode 'phevc': {'HAD' 'SAD-Res' 'SAD-FQRes' 'SSIM1-Pre' 'SSIM2-Pre' 'SSIM3'}
%
% Parámetros de salida:
%          bits : Número de bits totales
%          bpp  : Bits por píxel
%          bps  : Bits por segundo
%         kbps  : Kilobits por segundo
%         Mbps  : Megabits por segundo

%Calculamos el PUSize en función del CtuSize y el numero de levels nLevels
pusize=ctusize/2^(nlevels);

if ~any(strcmp(string({'hevc' 'phevc'}),mode))
   error('mode debe ser ''hevc'' o ''phevc''');
end

if ~any(pusize==[32 16 8 4])
    error('pusize debe ser uno de [32 16 8 4]');
end

if strcmp('hevc',mode) && ~any(strcmp({'RD' 'Coste'},bestmodeby))
   error('bestmodeby para el mode ''hevc'' debe ser alguno de estos: ''RD'' o ''Coste''');
elseif strcmp('phevc',mode) && ~any(strcmp({'HAD','SAD-Res','SAD-FQRes','SSIM1-Pre','SSIM2-Pre','SSIM3'},bestmodeby))
    error('bestmodeby para el mode ''phevc'' debe ser alguno de estos: ''HAD'', ''SAD-Res'', ''SAD-FQRes'', ''SSIM1-Pre'', ''SSIM2-Pre'' o ''SSIM3''');
end

[pathstr,sequenceName,~] = fileparts(yuvSequence);

if strcmp('hevc',mode)
    pattern=sprintf('%s\\%s\\%s\\%s_%s_%03d_CQ_*ctu%02d_l%1d_qp%02d_%s_bm%s.mat',pathstr,sequenceName,mode,mode,sequenceName,frame,ctusize,nlevels,qp,csfMode,bestmodeby);
else
    pattern=sprintf('%s\\%s\\%s\\%s_%s_%03d_CFQRes_*ctu%02d_l%1d_qp%02d_%s_bm%s.mat',pathstr,sequenceName,mode,mode,sequenceName,frame,ctusize,nlevels,qp,csfMode,bestmodeby);
end

files=dir(pattern);
if size(files,1)>1
    fprintf('Se han encontrado dos ficheros con el mismo patron.\n');
    return
end
if (size(files,1)==0)
    fprintf('Archivo CQ (hevc) o CFQRes (phevc) no encontrado. Omitiendo _frame\n');
    return
end

%Cargamos el fichero de coeficientes. El patron del fichero se genera con los parámetros.
filePath=files(1).folder;
fileName=files(1).name;
load(strcat(filePath,'\',fileName));

signCoding = true;
noDC = false;

[nr,nc]=size(CQ);
[bpp,bits,~,~,~,~] = GetCoefsEntropy(CQ,signCoding,noDC);

img_nr=nr*pusize;
img_nc=nc*pusize;

% Recalculamos bpp teniendo en cuenta la matriz de masking si corresponde
bps = bits * framerate;
kbps = bps * 10^-3;
Mbps = bps * 10^-6;

end
