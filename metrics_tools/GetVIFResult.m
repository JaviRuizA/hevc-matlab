function [ vif, vifp ] = GetVIFResult( imorg, imdist, width, height )
%GETVIFRESULT Summary of this function goes here
%   Detailed explanation goes here

[imorgPATHSTR,imorgNAME,~] = fileparts(imorg);
[imdistPATHSTR,imdistNAME,~] = fileparts(imdist);

% Comprobamos si existe la versión .bmp del archivo
imorgBMP = [imorgPATHSTR filesep imorgNAME '.bmp'];
if ~exist(imorgBMP,'file')
    imorgYUV = [imorgPATHSTR filesep imorgNAME '.yuv'];
    % Comprobamos si existe la versión .yuv del archivo
    if ~exist(imorgYUV,'file')
        errorStruct.message = ['No se encuentra el archivo "' imdistPATHSTR filesep imdistNAME '" en formato .yuv'];
        errorStruct.identifier = 'MyFunction:fileNotFound';
        error(errorStruct);
    else
        % Convertimos el .yuv a .bmp
        [Y,~,~] = GetYuvFrame(imorgYUV,width,height,1);
        imwrite(uint8(Y),imorgBMP)
    end
end

% Comprobamos si existe la versión .bmp del archivo
imdistBMP = [imdistPATHSTR filesep imdistNAME '.bmp'];
if ~exist(imdistBMP,'file')
    imdistYUV = [imdistPATHSTR filesep imdistNAME '.yuv'];
    % Comprobamos si existe la versión .yuv del archivo
    if ~exist(imdistYUV,'file')
        errorStruct.message = ['No se encuentra el archivo "' imdistPATHSTR filesep imdistNAME '" en formato .bmp'];
        errorStruct.identifier = 'MyFunction:fileNotFound';
        error(errorStruct);
    else
        % Convertimos el .yuv a .bmp
        [Y,~,~] = GetYuvFrame(imdistYUV,width,height,1);
        imwrite(uint8(Y),imdistBMP)
    end
end

org_image = double(imread(imorgBMP));
dst_image = double(imread(imdistBMP));

vif = vifvec(org_image,dst_image);
vifp = vifp_mscale(org_image,dst_image);

end

