function [ixMatrix]=GetIxMatrixForSize(size)
%[nr,nc]=GetIxMatrixForSize(level)
%   Devuelve el �ndice de la matriz de transformaci�n en funci�n del tama�o
%   del bloque

    switch size
        case 32
            ixMatrix=4;
        case 16
            ixMatrix=3;
        case 8
            ixMatrix=2;
        case 4
            ixMatrix=1;
        otherwise
            error('GetixMatrixForLevel: incorrect size %d\n', size);
    end
end
