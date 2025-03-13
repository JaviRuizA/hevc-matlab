function [frameCQImage]=LoadFrameCQImage(yuvSequence, frame, mode, qp, csfMode, bestmodeby)
%frameCQImage=LoadFrameCQImage(yuvSequence, frame, mode, qp, csfMode, bestmodeby)
%   Detailed explanation goes here

[pathstr,sequenceName,~] = fileparts(yuvSequence);

if strcmp('hevc',mode)
    pattern=sprintf('%s\\%s\\%s\\%s_%s_%03d_frameCQImage_*qp%02d_%s_bm%s.mat',pathstr,sequenceName,mode,mode,sequenceName,frame,qp,csfMode,bestmodeby);
else
    pattern=sprintf('%s\\%s\\%s\\%s_%s_%03d_CFQRes_*ctu%02d_l%1d_qp%02d_%s_bm%s.mat',pathstr,sequenceName,mode,mode,sequenceName,frame,ctusize,nlevels,qp,csfMode,bestmodeby);
end

files=dir(pattern);
if size(files,1)>1
    fprintf('Se han encontrado dos ficheros con el mismo patron.\n');
    return
end
if (size(files,1)==0)
    fprintf('Archivo frameParts no encontrado. Omitiendo _frame\n');
    return
end

%Cargamos el fichero de coeficientes. El patron del fichero se genera con los parámetros.
filePath=files(1).folder;
fileName=files(1).name;
load(strcat(filePath,'\',fileName));

end

