function [ T, L, R] = GetReferenceSamples( PUC, REC, RECB, row, col, bitDepth)
% Devuelve la Precition Row R para el PU que está en la posición row col del PUC cell array
% Tiene en e cuenta los bloques previamente reconstruidos de REC, en base a la matriz
% booleana RECB que es true para los bloques ya reconstruidos.
% Devuelve también: 
%   la referencia T (top) de izquiera a derecha. T(1)=L(1)=Corner.
%   la referencia L (left) de arriba a abajo
% La referencia R la devuelve en un vector fila concatenando:
%   L de abajo a arriba con T de derecha a izquiera sin el primer elemento
%   (que coincide con el último de L de abajo a arriba, el corner)
 
PUSize=size(PUC{1,1});

% s es el tamaño de bloque
s=PUSize(1);

%Obtenemos los booleanos que indican si hay datos reconstruidos en los bloques L,LB,T y TR
[L, LB, T, TR, C] = AvailableRefs(s,REC,RECB,row,col,bitDepth);

L=[C;L;LB];
T=[C T TR];
R=[flip(L') T(2:end)];

end

function [L, LB, T, TR, C] = AvailableRefs(s,rec,b,r,c,bitDepth)
refGray=2^(bitDepth-1);
onesRow=ones(1,s);
onesCol=ones(s,1);
refGrayRow=onesRow*refGray;
refGrayCol=onesCol*refGray;
[nr,nc]=size(rec);
if(r==1) %Primera fila
    if (c==1) %Primera Columna
        bL=false; bLB=false; bT=false; bTR=false; bC=false;
        L=refGrayCol; LB=refGrayCol; T=refGrayRow; TR=refGrayRow; C=refGray;
    else %Columnas Intermedias y Ultima Columna
        bL=b(r,c-1); bLB=b(r+1,c-1); bT=false; bTR=false; bC=false;
        block=rec{r,c-1};   L=block(:,end);
        if ~bLB
            LB=onesCol*L(end);
        else
            block=rec{r+1,c-1}; 
            LB=block(:,end);
        end
        C=L(1);
        T=onesRow*C; TR=onesRow*C;
    end
elseif (r==nr)%Ultima fila
    if (c==1) %Primera Columna
        bL=false; bLB=false; bT=b(r-1,c); bTR=b(r-1,c+1); bC=false;
        block=rec{r-1,c};   T=block(end,:);
        if ~bTR
            TR=onesRow*T(end);
        else
            block=rec{r-1,c+1}; 
            TR=block(end,:);
        end
        C=T(1);
        L=onesCol*C; LB=onesCol*C; 
    elseif (c==nc) %Ultima Columna
        bL=b(r,c-1); bLB=false; bT=b(r-1,c); bTR=false; bC=b(r-1,c-1);
        block=rec{r,c-1};   L=block(:,end);
        block=rec{r-1,c};   T=block(end,:);
        block=rec{r-1,c-1}; C=block(end,end);
        LB=onesCol*L(end); TR=onesRow*T(end); 
    else %Columnas Intermedias
        bL=b(r,c-1); bLB=false; bT=b(r-1,c); bTR=b(r-1,c+1); bC=b(r-1,c-1);
        block=rec{r,c-1};   L=block(:,end);
        block=rec{r-1,c};   T=block(end,:);
        if ~bTR
            TR=onesRow*T(end);
        else
            block=rec{r-1,c+1}; 
            TR=block(end,:);
        end
        block=rec{r-1,c-1}; C=block(end,end);
        LB=onesCol*L(end);
    end
else%Filas intermedias    
    if (c==1) %Primera Columna
        bL=false; bLB=false; bT=b(r-1,c); bTR=b(r-1,c+1); bC=false;
        block=rec{r-1,c};   T=block(end,:);
        if ~bTR
            TR=onesRow*T(end);
        else
            block=rec{r-1,c+1}; 
            TR=block(end,:);
        end
        C=T(1);
        L=onesCol*C; LB=onesCol*C; 
    elseif (c==nc) %Ultima Columna
        bL=b(r,c-1); bLB=b(r+1,c-1); bT=b(r-1,c); bTR=false; bC=b(r-1,c-1);
        block=rec{r,c-1};   L=block(:,end);
        if ~bLB
            LB=onesCol*L(end);
        else
            block=rec{r+1,c-1}; 
            LB=block(:,end);
        end
        block=rec{r-1,c};   T=block(end,:);
        block=rec{r-1,c-1}; C=block(end,end);
        TR=onesRow*T(end);
    else %Columnas Intermedias
        bL=b(r,c-1); bLB=b(r+1,c-1); bT=b(r-1,c); bTR=b(r-1,c+1); bC=b(r-1,c-1);
        block=rec{r,c-1};   L=block(:,end);
        if ~bLB
            LB=onesCol*L(end);
        else
            block=rec{r+1,c-1}; 
            LB=block(:,end);
        end
        block=rec{r-1,c};   T=block(end,:);
        if ~bTR
            TR=onesRow*T(end);
        else
            block=rec{r-1,c+1}; 
            TR=block(end,:);
        end
        block=rec{r-1,c-1}; C=block(end,end);
    end
end
end