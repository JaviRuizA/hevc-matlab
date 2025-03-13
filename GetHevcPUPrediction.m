function [ mode, hevcPUPrediction ] = GetHevcPUPrediction( nr, nc, r, c, frame)

global hevcData;
global hevcZPredictions;
global hevcZModes;

blockSize=size(hevcData{1,2},1);

ixModeCol=1;
ixPredictionCol=3;

hevcModeCol=hevcData(:,ixModeCol,frame);
hevcPredictionsCol=hevcData(:,ixPredictionCol,frame);

if blockSize>8
    %Los bloques que se cargan del fichero export del HEVC van en raster order
    hevcModes=reshape(hevcModeCol,nc,nr)';
    hevcPredictions=reshape(hevcPredictionsCol,nc,nr)';

    hevcPUPrediction=hevcPredictions{r,c};
    mode=hevcModes{r,c};
elseif blockSize==8
    %Los bloques que se cargan del fichero export del HEVC van en zorder
    if isempty(hevcZPredictions) && isempty(hevcZModes)
        %Toda la reordenación en zorders la hacemos sólo una vez, ya que esta función es llamada
        %en cada iteración del bucle del HEVC_Main y siempre haría lo mismo.
        %Las variables globales se inicializan en AnalisisModos.m
        LoadHevcData8(hevcModeCol,hevcPredictionsCol,nr,nc);
    end
    hevcPUPrediction=hevcZPredictions{r,c};
    mode=hevcZModes{r,c};
elseif blockSize==4
    %Los bloques que se cargan del fichero export del HEVC van en zorder
    if isempty(hevcZPredictions) && isempty(hevcZModes)
        %Toda la reordenación en zorders la hacemos sólo una vez, ya que esta función es llamada
        %en cada iteración del bucle del HEVC_Main y siempre haría lo mismo.
        %Las variables globales se inicializan en AnalisisModos.m
        LoadHevcData4(hevcModeCol,hevcPredictionsCol,nr,nc);
    end
    hevcPUPrediction=hevcZPredictions{r,c};
    mode=hevcZModes{r,c};
end

%Traducción del índice de modo en función de la posición en nuestro array de modos.
if mode==0
    mode=1; %Planar
elseif mode==1
    mode=35; %DC
end %Modos angulares coincide el índice.

end

function LoadHevcData8(hevcModeCol,hevcPredictionsCol,nr,nc)
global hevcZPredictions;
global hevcZModes;

numBlocks=nr*nc;
numZBlocks=numBlocks/4;

hevcZModes=cell(nr,nc);
nextR=1;
nextC=1;
ixBlock=1;
for zb=1:numZBlocks
    zblocks=hevcModeCol(ixBlock:ixBlock+3);
    [hevcZModes,nextR,nextC]=SetZBlocks8(hevcZModes,zblocks,nextR,nextC);
    ixBlock=ixBlock+4;
end

hevcZPredictions=cell(nr,nc);
nextR=1;
nextC=1;
ixBlock=1;
for zb=1:numZBlocks
    zblocks=hevcPredictionsCol(ixBlock:ixBlock+3);
    [hevcZPredictions,nextR,nextC]=SetZBlocks8(hevcZPredictions,zblocks,nextR,nextC);
    ixBlock=ixBlock+4;
end
end

function LoadHevcData4(hevcModeCol,hevcPredictionsCol,nr,nc)
global hevcZPredictions;
global hevcZModes;

numBlocks=nr*nc;
numZBlocks=numBlocks/16;

hevcZModes=cell(nr,nc);
nextR=1;
nextC=1;
ixBlock=1;
for zb=1:numZBlocks
    zblocks=hevcModeCol(ixBlock:ixBlock+15);
    [hevcZModes,nextR,nextC]=SetZBlocks4(hevcZModes,zblocks,nextR,nextC);
    ixBlock=ixBlock+16;
end

hevcZPredictions=cell(nr,nc);
nextR=1;
nextC=1;
ixBlock=1;
for zb=1:numZBlocks
    zblocks=hevcPredictionsCol(ixBlock:ixBlock+15);
    [hevcZPredictions,nextR,nextC]=SetZBlocks4(hevcZPredictions,zblocks,nextR,nextC);
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
