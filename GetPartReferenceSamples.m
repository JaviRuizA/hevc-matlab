function [T, L, R]=GetPartReferenceSamples(part,frameRefsMap,frameRecImage,bitDepth)
%[T, L, R]=GetPartReferenceSamples(part,frameRefsMap,frameRecImage,bitDepth);
%Obtiene las referencias T L y R de una partition, utilizando el frameRecImage
%
% Devuelve la Precition Row R para la partition
% Tiene en e cuenta los bloques previamente reconstruidos de frameRecImage, en base a
% los tamaños de la partition, su tamaño y las posiciones de sus referencias.
% Devuelve también: 
%   la referencia T (top) de izquiera a derecha. T(1)=L(1)=Corner.
%   la referencia L (left) de arriba a abajo
% La referencia R la devuelve en un vector fila concatenando:
%   L de abajo a arriba con T de derecha a izquiera sin el primer elemento
%   (que coincide con el último de L de abajo a arriba, el corner)

%Obtenemos los booleanos que indican si hay datos reconstruidos en los bloques L,LB,T y TR
[L, LB, T, TR, C] = AvailableRefs(part,frameRefsMap,frameRecImage,bitDepth);

L=[C;L;LB];
T=[C T TR];
R=[flip(L') T(2:end)];

end

% AvailableRefs(s,rec,b,r,c,bitDepth)
function [L, LB, T, TR, C] = AvailableRefs(part,frameRefsMap,frameRecImage,bitDepth)

[nr,nc]=size(frameRefsMap);
partRows = part(Indexes.ixTUsize);
partCols = part(Indexes.ixTUsize);
refGray=2^(bitDepth-1); 
onesRow=ones(1,partRows);
onesCol=ones(partCols,1);
refGrayRow=onesRow*refGray;
refGrayCol=onesCol*refGray;

%Obtenemos el desplazamiento de la partición en en frameRefsMap en row y cols en vez de dx,dy
dy = part(Indexes.ixRow) - 1;
dx = part(Indexes.ixCol) - 1;
r=dy+1; %r row en la imagen o imagen reconstruida
c=dx+1; %c col en la imagen o imagen reconstruida
%frameRefsMap tiene una columna y fila a la izquiera y arriba para las referencias fuera de imagen
%rM - rowMap row en el mapa
%cM - colMap col en el mapa
rM=dy+2; cM=dx+2;

% L, LB, T, TR, C
% L - Left - Los pixels a la izquierda de la partición
% LB - Left Bottom - Los pixels en la extensión izquierda abajo de la partición
% T - Top - Los pixels encima de la partición
% TR - Top Right - Los pixels en la extensión encima derecha de la particion
% C - Corner - El pixel esquina anterior a la esquina de la partición
% El prefijo b significa boolean
% Son True si el mapa de Referencias del frame indica si ha sido reconstruido ese pixel.
% Si no se ha reconstruido ese pixel su boolean será falso.


% bL=all(frameRefsMap(rM:rM+nr-1,cM-1));
% bLB=all(frameRefsMap(rM+nr:rM+2*nr-1,cM-1));
% bT=all(frameRefsMap(rM-1,cM:cM+nc-1));
% bTR=all(frameRefsMap(rM-1,cM+nc:cM+2*nc-1));
% bC=frameRefsMap(rM-1,cM-1);

if(r==1) %Primera fila
    if (c==1) %Primera Columna
        L=refGrayCol; LB=refGrayCol; T=refGrayRow; TR=refGrayRow; C=refGray;
    else %Columnas Intermedias y Ultima Columna
        bLB=all(frameRefsMap(rM+partRows:rM+2*partRows-1,cM-1)); 
        L=frameRecImage(r:r+partRows-1,c-1);
        if ~bLB
            LB=onesCol*L(end);
        else
            LB=frameRecImage(r+partRows:r+2*partRows-1,c-1);
        end
        C=L(1);
        T=onesRow*C; 
        TR=onesRow*C;
    end
elseif ((r+partRows)==nr)%Ultima fila
    if (c==1) %Primera Columna
        bTR=all(frameRefsMap(rM-1,cM+partCols:cM+2*partCols-1)); 
        T=frameRecImage(r-1,c:c+partCols-1);
        if ~bTR
            TR=onesRow*T(end);
        else
            TR=frameRecImage(r-1,c+partCols:c+2*partCols-1);
        end
        C=T(1);
        L=onesCol*C; 
        LB=onesCol*C; 
    elseif ((c+partCols)==nc) %Ultima Columna
        L=frameRecImage(r:r+partRows-1,c-1);
        T=frameRecImage(r-1,c:c+partCols-1);
        C=frameRecImage(r-1,c-1);
        LB=onesCol*L(end); 
        TR=onesRow*T(end); 
    else %Columnas Intermedias
        bTR=all(frameRefsMap(rM-1,cM+partCols:cM+2*partCols-1)); 
        L=frameRecImage(r:r+partRows-1,c-1);
        T=frameRecImage(r-1,c:c+partCols-1);
        if ~bTR
            TR=onesRow*T(end);
        else
            TR=frameRecImage(r-1,c+partCols:c+2*partCols-1);
        end
        C=frameRecImage(r-1,c-1);
        LB=onesCol*L(end);
    end
else%Filas intermedias    
    if (c==1) %Primera Columna
%         bL=false; bLB=false; bT=b(r-1,c); bTR=b(r-1,c+1); bC=false;
        bTR=all(frameRefsMap(rM-1,cM+partCols:cM+2*partCols-1));
        T=frameRecImage(r-1,c:c+partCols-1);
        if ~bTR
            TR=onesRow*T(end);
        else
            TR=frameRecImage(r-1,c+partCols:c+2*partCols-1);
        end
        C=T(1);
        L=onesCol*C; 
        LB=onesCol*C; 
    elseif ((c+partCols)==nc) %Ultima Columna
%         bL=b(r,c-1); bLB=b(r+1,c-1); bT=b(r-1,c); bTR=false; bC=b(r-1,c-1);
        bLB=all(frameRefsMap(rM+partRows:rM+2*partRows-1,cM-1));
        L=frameRecImage(r:r+partRows-1,c-1);
        if ~bLB
            LB=onesCol*L(end);
        else
            LB=frameRecImage(r+partRows:r+2*partRows-1,c-1);
        end
        T=frameRecImage(r-1,c:c+partCols-1);
        C=frameRecImage(r-1,c-1);
        TR=onesRow*T(end);
    else %Columnas Intermedias
%         bL=b(r,c-1); bLB=b(r+1,c-1); bT=b(r-1,c); bTR=b(r-1,c+1); bC=b(r-1,c-1);
        bLB=all(frameRefsMap(rM+partRows:rM+2*partRows-1,cM-1));
        bTR=all(frameRefsMap(rM-1,cM+partCols:cM+2*partCols-1));
        L=frameRecImage(r:r+partRows-1,c-1);
        if ~bLB
            LB=onesCol*L(end);
        else
            LB=frameRecImage(r+partRows:r+2*partRows-1,c-1);
        end
        T=frameRecImage(r-1,c:c+partCols-1);
        if ~bTR
            TR=onesRow*T(end);
        else
            TR=frameRecImage(r-1,c+partCols:c+2*partCols-1);
        end
        C=frameRecImage(r-1,c-1);
    end
end
end