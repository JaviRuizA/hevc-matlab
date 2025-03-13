function [ zMatrix ] = GetZMatrix( ctuSize, nLevels, imWidth, imHeigth)
%Esta función devuelve la zMatrix, que contiene el orden de procesamiento de los PUs de una imagen
% Si nLevels>0 quiere decir que existe una descomposición de cada CTU en bloques a procesar en
%    z-order
% Si nLevels==0 quiere decir que no hay descomposición z-order y se procesa en raster order y que
% los PU tienen el mismo tamaño que los PU

cuSize=ctuSize/(2^nLevels);
numCols=imWidth/cuSize;
numRows=imHeigth/cuSize;
zMatrix=uint32(zeros(numRows,numCols));

step=ctuSize/cuSize;

if (nLevels>0)
    %Preparamos la matriz que contiene el z-order a procesar.
    
    ixsC=[1:step:numCols];
    ixsR=[1:step:numRows];

    counter=0;
    for r=1:numel(ixsR)
        ixR=ixsR(r);
        for c=1:numel(ixsC)
            ixC=ixsC(c);
            ctuMatrix=zMatrix(ixR:ixR+step-1,ixC:ixC+step-1);
            [ctuMatrix, counter] =FillCTU(ctuMatrix,nLevels-1,counter);
            zMatrix(ixR:ixR+step-1,ixC:ixC+step-1)=ctuMatrix;
        end
    end
else
    %Preparamos la matriz que tiene el raster-order a procesar.
    counter=0;
    for r=1:numRows
        for c=1:numCols
            counter=counter+1;
            zMatrix(r,c)=counter;
        end
    end
end
end

function [ctuMatrix, counter] = FillCTU(ctuMatrix,level,counter)
if level>0
    level=level-1;
    [nRows,nCols]=size(ctuMatrix);
    ctu1Matrix=ctuMatrix(1:nRows/2,1:nCols/2);
    ctu2Matrix=ctuMatrix(1:nRows/2,nCols/2+1:end);
    ctu3Matrix=ctuMatrix(nRows/2+1:end,1:nCols/2);
    ctu4Matrix=ctuMatrix(nRows/2+1:end,nCols/2+1:end);
    
    [ctuRMatrix, counter] = FillCTU(ctu1Matrix,level,counter);
    ctuMatrix(1:nRows/2,1:nCols/2)=ctuRMatrix;
    
    [ctuRMatrix, counter] = FillCTU(ctu2Matrix,level,counter);
    ctuMatrix(1:nRows/2,nCols/2+1:end)=ctuRMatrix;
    
    [ctuRMatrix, counter] = FillCTU(ctu3Matrix,level,counter);
    ctuMatrix(nRows/2+1:end,1:nCols/2)=ctuRMatrix;
    
    [ctuRMatrix, counter] = FillCTU(ctu4Matrix,level,counter);
    ctuMatrix(nRows/2+1:end,nCols/2+1:end)=ctuRMatrix;
else
    ctuMatrix(1,1)=counter+1;
    ctuMatrix(1,2)=counter+2;
    ctuMatrix(2,1)=counter+3;
    ctuMatrix(2,2)=counter+4;
    counter=counter+4;
end
end