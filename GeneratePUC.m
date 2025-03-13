function [ PUC ] = GeneratePUC( image, PUSize)
%Genera un cell array con todos los CU de la imagen
[nr,nc]=size(image);

try
    cellRowParam=repmat(PUSize,1,nr/PUSize);
    cellColumParam=repmat(PUSize,1,nc/PUSize);
    %PUC Cell Array con cada uno de los CUs de la imagen original
    PUC=mat2cell(double(image),cellRowParam,cellColumParam);
catch ME
    % ERROR debido a que la imagen no se puede dividir entre el tamaño de
    % PU y que el resultado sea un entero
    error(['GeneratePUC.m: ' ME.message]);
end

end

