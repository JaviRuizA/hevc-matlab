function [ hevcInvQT ] = GetHevcInvQT( nr, nc, r, c, frame)
global hevcData;
global hevcZInvQTs;

blockSize=size(hevcData{1,2},1);

ixInvQT=4; 
hevcInvQTCol=hevcData(:,ixInvQT,frame);

if blockSize>8
    %Los bloques que se cargan del fichero export de HEVC van en raster order.
    hevcInvQTs=reshape(hevcInvQTCol,nc,nr)';
    hevcInvQT=hevcInvQTs{r,c};
elseif blockSize==8
    %Los bloques que se cargan del fichero export de HEVC van en z-order en 4 bloques
    %que rellenan en raster order.
    if isempty(hevcZInvQTs)
        %Toda la reordenación la hacemos sólo una vez, ya que esta función es llamada 
        %en cada iteración del bucle del HEVC_Main y siempre haría lo mismo.
        %Las variables globales se inicializan en AnalisisModos.m
        LoadHevcData8(hevcInvQTCol,nr,nc);
    end
    hevcInvQT=hevcZInvQTs{r,c};
elseif blockSize==4
    %Los bloques que se cargan del fichero export de HEVC van en z-order en 4 bloques
    %que rellenan en raster order.
    if isempty(hevcZInvQTs)
        %Toda la reordenación la hacemos sólo una vez, ya que esta función es llamada 
        %en cada iteración del bucle del HEVC_Main y siempre haría lo mismo.
        %Las variables globales se inicializan en AnalisisModos.m
        LoadHevcData4(hevcInvQTCol,nr,nc);
    end
    hevcInvQT=hevcZInvQTs{r,c};
end
end

function LoadHevcData8(hevcInvQTCol,nr,nc)
global hevcZInvQTs;

numBlocks=nr*nc;
numZBlocks=numBlocks/4;

hevcZInvQTs=cell(nr,nc);
nextR=1;
nextC=1;
ixBlock=1;
for zb=1:numZBlocks
    zblocks=hevcInvQTCol(ixBlock:ixBlock+3);
    [hevcZInvQTs,nextR,nextC]=SetZBlocks8(hevcZInvQTs,zblocks,nextR,nextC);
    ixBlock=ixBlock+4;
end
end

function LoadHevcData4(hevcInvQTCol,nr,nc)
global hevcZInvQTs;

numBlocks=nr*nc;
numZBlocks=numBlocks/16;

hevcZInvQTs=cell(nr,nc);
nextR=1;
nextC=1;
ixBlock=1;
for zb=1:numZBlocks
    zblocks=hevcInvQTCol(ixBlock:ixBlock+15);
    [hevcZInvQTs,nextR,nextC]=SetZBlocks4(hevcZInvQTs,zblocks,nextR,nextC);
    ixBlock=ixBlock+16;
end
end

function [hevcZBlocks,nextR,nextC]=SetZBlocks8(hevcZBlocks,zblocks,ixR,ixC)
    blockSize=size(zblocks{1},1);
    hevcZBlocks(ixR,ixC)=zblocks(1);
    hevcZBlocks(ixR,ixC+1)=zblocks(2);
    hevcZBlocks(ixR+1,ixC)=zblocks(3);
    hevcZBlocks(ixR+1,ixC+1)=zblocks(4);
    [nr,nc]=size(hevcZBlocks);
    if (ixC+2)>nc
        nextC=1;
        nextR=ixR+2;
    else
        nextC=ixC+2;
        nextR=ixR;
    end
end

function [hevcZBlocks,nextR,nextC]=SetZBlocks4(hevcZBlocks,zblocks,ixR,ixC)
    % Primer bloque Z sup-izq
    hevcZBlocks(ixR,ixC)=zblocks(1);
    hevcZBlocks(ixR,ixC+1)=zblocks(2);
    hevcZBlocks(ixR+1,ixC)=zblocks(3);
    hevcZBlocks(ixR+1,ixC+1)=zblocks(4);
    % Segundo bloque Z sup-dcha
    hevcZBlocks(ixR,ixC+2)=zblocks(5);
    hevcZBlocks(ixR,ixC+3)=zblocks(6);
    hevcZBlocks(ixR+1,ixC+2)=zblocks(7);
    hevcZBlocks(ixR+1,ixC+3)=zblocks(8);
    % Tercer bloque Z inf-izq
    hevcZBlocks(ixR+2,ixC)=zblocks(9);
    hevcZBlocks(ixR+2,ixC+1)=zblocks(10);
    hevcZBlocks(ixR+3,ixC)=zblocks(11);
    hevcZBlocks(ixR+3,ixC+1)=zblocks(12);
    % Cuarto bloque Z inf-dcha
    hevcZBlocks(ixR+2,ixC+2)=zblocks(13);
    hevcZBlocks(ixR+2,ixC+3)=zblocks(14);
    hevcZBlocks(ixR+3,ixC+2)=zblocks(15);
    hevcZBlocks(ixR+3,ixC+3)=zblocks(16);
    
    [nr,nc]=size(hevcZBlocks);
    if (ixC+4)>nc
        nextC=1;
        nextR=ixR+4;
    else
        nextC=ixC+4;
        nextR=ixR;
    end
end





