function [frameParts]=LoadPartitionFile(partition_file,width,height,maxCTU)
%LOADPARTITIONFILE
%   Devuelve en matrices la siguiente información de cada CTU (ver archivo
%   indexes.m)
% ixCUid - Identificador de CU dentro del frame (ixCUid)
% ixCUsize - Tamaño de bloque CU (32 16 8)
% ixTUsize - Tamaño de bloque TU (32 16 8 4)
% ixTUrow - Posición x (fila) dentro del CTU
% ixTUcol - Posición y (columna) dentro del CTU
% ixRow - Posición x (fila) dentro del frame
% ixCol - Posición y (columna) dentro del frame
% ixMode - Modo de predicción Intra
% ixTexClass - Clasificación de textura del bloque (-1 None, 0 Plain, 1 Edge, 2 Texture)
% ixMaskVal - Valor del factor multiplicador de masking

minCU = 8;
minTU = 4;

numRowsCTU = height / maxCTU;
numColsCTU = width / maxCTU;

numCTUs = numColsCTU * numRowsCTU;

frameParts = cell(numRowsCTU,numColsCTU);

fid = fopen(partition_file,'r');
fileCols = numel(str2double(strsplit(fgetl(fid),' ')))-1;
fclose(fid);

warning('off','all'); % Se muestra un warning ya que confunde el formato del particionado con un DATETIME
if verLessThan('matlab', '9.8.0')
    splitFlags = readtable(partition_file, 'Delimiter', ' ', 'ReadVariableNames', false, 'DatetimeType','text');
else
    splitFlags = readtable(partition_file, 'Delimiter', ' ', 'ReadVariableNames', false, 'DatetimeType','text','Format','auto');
end
warning('on','all');
splitFlags = table2cell(splitFlags(1:numCTUs,1:fileCols));


ctuID = 1; % necesario para recorrer el archivo importado del HM
for ctuRow=1:numRowsCTU
    for ctuCol=1:numColsCTU
        
        %fprintf('CTU %d\n',ctuID);
        CTU = splitFlags(ctuID,:);
        IntraMode = zeros(1,fileCols);
        TransfDepth = zeros(1,fileCols);
        CUSize = zeros(1,fileCols);
        for j=1:fileCols
            tmp = split(CTU{j},'-');
            IntraMode(j) = str2double(tmp(1));
            TransfDepth(j) = str2double(tmp(2));
            CUSize(j) = str2double(tmp(3));
        end

        TU_id = zeros(256,9);
        CU_count = 1; TU_count = 0;
        idx = 1;
        while idx <= fileCols
            CU_size = CUSize(idx);
            last_CU_idx = idx + minTU*(CU_size / minCU)^2 - 1;

            % Sabemos exactamente el tamaño del CU, toca ahora conocer el
            % tamaño del TU

            % Si el flag de particionado es 0, el valor de TU es igual al de CU
            % Si el flag de particionado es 1 o mayor, el bloque CU se ha
            % particionado en 4 o más TUs en modo QuadTree

            while idx <= last_CU_idx
                SplitFlag = TransfDepth(idx);
                TU_size = CU_size / 2^SplitFlag;
                last_TU_idx = idx + minTU*(TU_size / minCU)^2 - 1;
                [row_tu,col_tu] = ZScan_QuadTree(idx,maxCTU);
                row = (ctuRow-1)*maxCTU + row_tu;
                col = (ctuCol-1)*maxCTU + col_tu;
                intra_mode = TranslateModeHM_to_Matlab(IntraMode(idx));
                TU_count = TU_count + 1;
                TU_id(TU_count,Indexes.ixCUid) = CU_count;
                TU_id(TU_count,Indexes.ixTUsize) = TU_size;
                TU_id(TU_count,Indexes.ixTUrow) = row_tu;
                TU_id(TU_count,Indexes.ixTUcol) = col_tu;
                TU_id(TU_count,Indexes.ixRow) = row;
                TU_id(TU_count,Indexes.ixCol) = col;
                TU_id(TU_count,Indexes.ixMode) = intra_mode;
                TU_id(TU_count,Indexes.ixTexClass) = -1;
                TU_id(TU_count,Indexes.ixMaskVal) = 1;
                idx = last_TU_idx + 1;
            end
            CU_count = CU_count + 1;

        end

        frameParts{ctuRow,ctuCol} = TU_id(1:TU_count,:);

        ctuID = ctuID + 1;
    end
end

end