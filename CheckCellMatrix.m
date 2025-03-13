function [ retBool, checkMatrix ] = CheckCellMatrix( cellMatrix, frame)
global hevcPUs;
global hevcData;

column=2;
[nr,nc]=size(cellMatrix);
blockSize=size(cellMatrix{1,1},1);
hevcDataCol=hevcData(:,column,frame);

if blockSize>8
    %Los bloques que se cargan del fichero export de HEVC van en raster order.
    hevcPUs=reshape(hevcDataCol,nc,nr)';
elseif blockSize==8
    %Los bloques que se cargan del fichero export de HEVC van en z-order por bloques de 4
    %que rellenan 4 bloques de 8x8 en raster order.
    hevcPUs=LoadHevcData8(hevcDataCol,nr,nc);
elseif blockSize==4
    %Los bloques que se cargan del fichero export de HEVC van en z-order por bloques de 4
    %que rellenan 16 bloques de 4x4 en raster order.
    hevcPUs=LoadHevcData4(hevcDataCol,nr,nc);
end

checkMatrix=uint8(zeros(nr,nc));
for r=1:nr
    for c=1:nc
        cellBlock=cellMatrix{r,c};
        hevcBlock=hevcPUs{r,c};
        checkMatrix(r,c)=isSameBlock(cellBlock,hevcBlock);
    end
end

retBool=all(all(checkMatrix));

end

function retBool=isSameBlock(A,B)
    retBool=all(all(A==B));
end

function hevcMatrix=LoadHevcData4(hevcBlocks,nr,nc)
numBlocks=numel(hevcBlocks);
numZBlocks=numBlocks/16;
hevcMatrix=cell(nr,nc);

nextR=1;
nextC=1;
ixBlock=1;
for zb=1:numZBlocks
    %Un zblock son 16 bloques de 4x4
    zblocks=hevcBlocks(ixBlock:ixBlock+15);
    [hevcMatrix,nextR,nextC]=SetZBlocks4(hevcMatrix,zblocks,nextR,nextC);
    ixBlock=ixBlock+16;
end
end


function hevcMatrix=LoadHevcData8(hevcBlocks,nr,nc)
numBlocks=numel(hevcBlocks);
numZBlocks=numBlocks/4;
hevcMatrix=cell(nr,nc);

nextR=1;
nextC=1;
ixBlock=1;
for zb=1:numZBlocks
    %Un zblock son 4 bloques de 8x8
    zblocks=hevcBlocks(ixBlock:ixBlock+3);
    [hevcMatrix,nextR,nextC]=SetZBlocks8(hevcMatrix,zblocks,nextR,nextC);
    ixBlock=ixBlock+4;
end
end

function [hevcMatrix,nextR,nextC]=SetZBlocks8(hevcMatrix,zblocks,ixR,ixC)
    hevcMatrix(ixR,ixC)=zblocks(1);
    hevcMatrix(ixR,ixC+1)=zblocks(2);
    hevcMatrix(ixR+1,ixC)=zblocks(3);
    hevcMatrix(ixR+1,ixC+1)=zblocks(4);
    [nr,nc]=size(hevcMatrix);
    if (ixC+2)>nc
        nextC=1;
        nextR=ixR+2;
    else
        nextC=ixC+2;
        nextR=ixR;
    end
end

function [hevcMatrix,nextR,nextC]=SetZBlocks4(hevcMatrix,zblocks,ixR,ixC)
    % Primer bloque Z sup-izq
    hevcMatrix(ixR,ixC)=zblocks(1);
    hevcMatrix(ixR,ixC+1)=zblocks(2);
    hevcMatrix(ixR+1,ixC)=zblocks(3);
    hevcMatrix(ixR+1,ixC+1)=zblocks(4);
    % Segundo bloque Z sup-dcha
    hevcMatrix(ixR,ixC+2)=zblocks(5);
    hevcMatrix(ixR,ixC+3)=zblocks(6);
    hevcMatrix(ixR+1,ixC+2)=zblocks(7);
    hevcMatrix(ixR+1,ixC+3)=zblocks(8);
    % Tercer bloque Z inf-izq
    hevcMatrix(ixR+2,ixC)=zblocks(9);
    hevcMatrix(ixR+2,ixC+1)=zblocks(10);
    hevcMatrix(ixR+3,ixC)=zblocks(11);
    hevcMatrix(ixR+3,ixC+1)=zblocks(12);
    % Cuarto bloque Z inf-dcha
    hevcMatrix(ixR+2,ixC+2)=zblocks(13);
    hevcMatrix(ixR+2,ixC+3)=zblocks(14);
    hevcMatrix(ixR+3,ixC+2)=zblocks(15);
    hevcMatrix(ixR+3,ixC+3)=zblocks(16);

    [nr,nc]=size(hevcMatrix);
    if (ixC+4)>nc
        nextC=1;
        nextR=ixR+4;
    else
        nextC=ixC+4;
        nextR=ixR;
    end
end