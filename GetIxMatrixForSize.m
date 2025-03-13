function [ixMatrix]=GetIxMatrixForSize(size)
%[nr,nc]=GetIxMatrixForSize(level)
%   Devuelve el índice de la matriz de transformación en función del tamaño
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
