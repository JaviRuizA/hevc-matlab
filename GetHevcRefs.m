function [ hevcR, hevcRf] = GetHevcRefs( nr, nc, r, c, frame)
global hevcData;
blockSize=size(hevcData{1,2},1);

ixRCol=7;
ixRFCol=8;

hevcRCol=hevcData(:,ixRCol,frame);
hevcRfCol=hevcData(:,ixRFCol,frame);

if blockSize>8
    %Los bloques que se cargan del fichero export de HEVC van en raster order.
    hevcZRs =reshape(hevcRCol ,nc,nr)';
    hevcZRfs=reshape(hevcRfCol,nc,nr)';
elseif blockSize==8
    %Los bloques que se cargan del fichero export de HEVC van en z-order por bloques de 4
    %que rellenan bloques de 4*blockSize en raster order.
    if isempty(hevcZRs) && isempty(hevcZRfs)
        %Toda la reordenación la hacemos sólo una vez, ya que esta función es llamada 
        %en cada iteración del bucle del HEVC_Main y siempre haría lo mismo.
        %Las variables globales se inicializan en AnalisisModos.m
        [hevcZRs, hevcZRfs]=LoadHevcData8(hevcRCol,hevcRfCol,nr,nc);
    end
elseif blockSize==4
    if isempty(hevcZRs) && isempty(hevcZRfs)
        %Toda la reordenación la hacemos sólo una vez, ya que esta función es llamada 
        %en cada iteración del bucle del HEVC_Main y siempre haría lo mismo.
        %Las variables globales se inicializan en AnalisisModos.m
        [hevcZRs, hevcZRfs]=LoadHevcData4(hevcRCol,hevcRfCol,nr,nc);
    end
end

hevcR=hevcZRs{r,c};
hevcRf=hevcZRfs{r,c};
end

function [hevcRs, hevcRfs]=LoadHevcData4(hevcRBlocks,hevcRfBlocks,nr,nc)

numBlocks=nr*nc;
numZBlocks=numBlocks/16;

hevcRs=cell(nr,nc);
nextR=1;
nextC=1;
ixBlock=1;
for zb=1:numZBlocks
    zblocks=hevcRBlocks(ixBlock:ixBlock+15);
    [hevcRs,nextR,nextC]=SetZBlocks4(hevcRs,zblocks,nextR,nextC);
    ixBlock=ixBlock+16;
end

hevcRfs=cell(nr,nc);
nextR=1;
nextC=1;
ixBlock=1;
for zb=1:numZBlocks
    zblocks=hevcRfBlocks(ixBlock:ixBlock+15);
    [hevcRfs,nextR,nextC]=SetZBlocks4(hevcRfs,zblocks,nextR,nextC);
    ixBlock=ixBlock+16;
end
end



function [hevcRs, hevcRfs]=LoadHevcData8(hevcRBlocks,hevcRfBlocks,nr,nc)

numBlocks=nr*nc;
numZBlocks=numBlocks/4;

hevcRs=cell(nr,nc);
nextR=1;
nextC=1;
ixBlock=1;
for zb=1:numZBlocks
    zblocks=hevcRBlocks(ixBlock:ixBlock+3);
    [hevcRs,nextR,nextC]=SetZBlocks8(hevcRs,zblocks,nextR,nextC);
    ixBlock=ixBlock+4;
end

hevcRfs=cell(nr,nc);
nextR=1;
nextC=1;
ixBlock=1;
for zb=1:numZBlocks
    zblocks=hevcRfBlocks(ixBlock:ixBlock+3);
    [hevcRfs,nextR,nextC]=SetZBlocks8(hevcRfs,zblocks,nextR,nextC);
    ixBlock=ixBlock+4;
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

