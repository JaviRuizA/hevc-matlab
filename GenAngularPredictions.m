function [PUAngulars]=GenAngularPredictions(R,Rf,partMode)
%GENANGULARPREDICTIONS
%   Generación de la predicción Planar para un PU en función del vector de
%   muestras de referencia R. Si se le indica la variable partMode calcula
%   la predicción para dicho modo (devuelve array), si se omite, calcula la
%   predicción para todos los modos (devuelve un cell)

if ~exist('partMode','var') || isempty(partMode)
    partMode=0;
end

oR=R;
oRf=Rf;

for r=1:numel(R)
    R(r)=r;
    Rf(r)=r;
end

R=oR;
Rf=oRf;

%Obtenemos el tamaño del PU  a predecir a partir de R
s=(numel(R)-1)/4;

ixLb=1;
ixLu=ixLb+s;
ixCo=2*s+1;
ixTl=ixCo+1;
ixTr=ixTl+s;

Lb=R(ixLb:s);
Lu=R(ixLu:ixLu+s-1);
Co=R(ixCo);
Tl=R(ixTl:ixTl+s-1);
Tr=R(ixTr:ixTr+s-1);

Lfb=Rf(ixLb:s);
Lfu=Rf(ixLu:ixLu+s-1);
Cfo=Rf(ixCo);
Tfl=Rf(ixTl:ixTl+s-1);
Tfr=Rf(ixTr:ixTr+s-1);


L=flip([Lb Lu Co]');
T=[Co Tl Tr];

Lf=flip([Lfb Lfu Cfo]');
Tf=[Cfo Tfl Tfr];

intraAngularMode=[2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34];                          % intra prediction mode
intraAngle=[32 26 21 17 13 9 5 2 0 -2 -5 -9 -13 -17 -21 -26 -32 -26 -21 -17 -13 -9 -5 -2 0 2 5 9 13 17 21 26 32];                 % intra prediction angle
intraInvAngle=[0 0 0 0 0 0 0 0 0 -4096 -1638 -910 -630 -482 -390 -315 -256 -315 -390 -482 -630 -910 -1638 -4096 0 0 0 0 0 0 0 0 0];  % intra prediction inverse angle

numModes=size(intraAngularMode,2);

%-----------------------------------------------------------
%  GENERAMOS LAS REFERENCIAS para todos los modos en los cell arrays 
%  Refs  para las referencias sin filtrado
%  Repsf para las referencias filtradas
%  Mas adelante, en función del tañamo de bloque se decidirá si se toma Refs o Refsf 
%-----------------------------------------------------------
%Para los modos negativos calculamos las Referencias con las proyeccioens 
%   Left LP y top TP de L y T
%   Left LfP y top TfP de Lf y Tf
%Refs es un cell array que recoge las Referencias para cada modo
%   El array de referencias Refs es array fila independientemente de si el modo es vertical u
%   horizontal. Pero se calcula diferente para modos horizontales y verticales.
Refs=cell(numModes,5);
Refsf=cell(numModes,5);
% Columnas de Refs: 1(modo) 2(Angulo) 3(InvAngle) 4(NumPix) 5(Ref)

%MODOS HORIZONTALES CON ANGULO POSITIVO, modos 2 al 10, (los indices en los arrays son 1 al 9)
    for nm=1:9 
        mode=intraAngularMode(nm);
        %Refs
        Refs{nm,1}=mode;
        Refs{nm,2}=intraAngle(nm);
        Refs{nm,3}=intraInvAngle(nm);
        Refs{nm,4}=0;
        Refs{nm,5}=L;
        %Refsf
        Refsf{nm,1}=mode;
        Refsf{nm,2}=intraAngle(nm);
        Refsf{nm,3}=intraInvAngle(nm);
        Refsf{nm,4}=0;
        Refsf{nm,5}=Lf;
    end

%MODOS VERTICALES CON ANGULO POSITIVO, modos 26 al 34, (los indices en los arrays son 25 al 33)
    for nm=25:33
        mode=intraAngularMode(nm);
        %Refs
        Refs{nm,1}=mode;
        Refs{nm,2}=intraAngle(nm);
        Refs{nm,3}=intraInvAngle(nm);
        Refs{nm,4}=0;
        Refs{nm,5}=T;
        %Refsf
        Refsf{nm,1}=mode;
        Refsf{nm,2}=intraAngle(nm);
        Refsf{nm,3}=intraInvAngle(nm);
        Refsf{nm,4}=0;
        Refsf{nm,5}=Tf;
    end
%MODOS CON ANGULO NEGATIVO, modos 11 al 25 (los indices en los arrays son 10 al 24)
    for nm=10:16 %Modos HORIZONTALES con Ángulo negativo
        invAngle=intraInvAngle(nm);
        mode=intraAngularMode(nm);
        %Refs
        [Pix]=GetTopProjectedPixels(invAngle,T);
        Refs{nm,1}=mode;
        Refs{nm,2}=intraAngle(nm);
        Refs{nm,3}=intraInvAngle(nm);
        Refs{nm,4}=numel(Pix(:));
        Refs{nm,5}=[Pix; L];
        %Refsf
        [Pixf]=GetTopProjectedPixels(invAngle,Tf);
        Refsf{nm,1}=mode;
        Refsf{nm,2}=intraAngle(nm);
        Refsf{nm,3}=intraInvAngle(nm);
        Refsf{nm,4}=numel(Pixf(:));
        Refsf{nm,5}=[Pixf; Lf];
    end
    for nm=17:24 %Modos VERITICALES con Ángulo negativo
        mode=intraAngularMode(nm);
        invAngle=intraInvAngle(nm);
        %Refs
        [Pix]=GetLeftProjectedPixels(invAngle,L);
        Refs{nm,1}=mode;
        Refs{nm,2}=intraAngle(nm);
        Refs{nm,3}=intraInvAngle(nm);
        Refs{nm,4}=numel(Pix(:));
        Refs{nm,5}=[Pix T];
        %Refsf
        [Pixf]=GetLeftProjectedPixels(invAngle,Lf);
        Refsf{nm,1}=mode;
        Refsf{nm,2}=intraAngle(nm);
        Refsf{nm,3}=intraInvAngle(nm);
        Refsf{nm,4}=numel(Pixf(:));
        Refsf{nm,5}=[Pixf Tf];
    end

if partMode~=0     
    %-----------------------------------------------------------
    %  REALIZAMOS LA PREDICCION ANGULAR para el modo pasado
    %-----------------------------------------------------------
    mode=partMode;
    A=intraAngle(mode-1);

    %Obtenemos las Referencias filtradas o no, según corresponda.
    ref=double(GetRefs(s,mode,Refs,Refsf));  % R= L, Lf, T o Tf

    %Necesario para que no se salga de ámbito en el último valor.
    ref(end+1)=ref(end); 
    
    if (mode>=2) && (mode<=17) %Modos Horizontales
        [offset]=GetOffset(mode,Refs);
        for r=1:s %rows (y)
            for c=1:s %cols (x)
                y=r-1; 
                x=c-1;
                i=bitshift((x+1)*A,-5,'int32');
                f=bitand((x+1)*A,31,'int32');
                ix1=offset+y+i+1+1;
                ix2=offset+y+i+2+1;
%                     fprintf('Modo[%d] [%d][%d] offset[%d] i[%d] f[%d] ix1=%d ix2=%d',mode,y,x,offset,i,f,ix1,ix2);
%                     fprintf(' R[%d]=%d R[%d]=%d\n',ix1,ref(ix1),ix2,ref(ix2));
                PU(r,c)=bitshift( (32-f)*ref(ix1) + f*ref(ix2) + 16 , -5,'int32' );
            end
        end
    else  %Modos Verticales
        [offset]=GetOffset(mode,Refs);
        for r=1:s %rows (y)
            for c=1:s %cols (x)
                y=r-1; 
                x=c-1;
                i=bitshift((y+1)*A,-5,'int32');
                f=bitand((y+1)*A,31,'int32');
                ix1=offset+x+i+1+1;
                ix2=offset+x+i+2+1;
                PU(r,c)=bitshift( (32-f)*ref(ix1) + f*ref(ix2) + 16 , -5 ,'int32');
            end
        end
    end
    
    %PostFiltrado si Modos Puros Horizonatal y Vertical
    if (((mode==10) || (mode==26)) && (s<32))
        PU=PostFiltering(PU,T,L,mode);
    end
    PUAngulars = PU;
%     imshow(uint8(PU))
    
else    
    %-----------------------------------------------------------
    %  REALIZAMOS LA PREDICCION ANGULAR para todos los modos
    %-----------------------------------------------------------
    PUAngulars=cell(numModes,1);
    for m=1:numModes
        PU=zeros(s,s);
        mode=intraAngularMode(m);
        A=intraAngle(m);

    %     fprintf('Procesando Modo(%d)=%d Angulo=%d ',m,mode,A);

        %Obtenemos las Referencias filtradas o no, según corresponda.
        ref=double(GetRefs(s,mode,Refs,Refsf));  % R= L, Lf, T o Tf

        %Necesario para que no se salga de ámbito en el último valor.
        ref(end+1)=ref(end); 

        if (mode>=2) && (mode<=17) %Modos Horizontales
    %         fprintf('Horizontal \n');
            [offset]=GetOffset(mode,Refs);
            for r=1:s %rows (y)
                for c=1:s %cols (x)
                    y=r-1; 
                    x=c-1;
                    i=bitshift((x+1)*A,-5,'int32');
                    f=bitand((x+1)*A,31,'int32');
                    ix1=offset+y+i+1+1;
                    ix2=offset+y+i+2+1;
    %                 fprintf('Modo[%d] [%d][%d] offset[%d] i[%d] f[%d] ix1=%d ix2=%d',mode,y,x,offset,i,f,ix1,ix2);
    %                 fprintf(' R[%d]=%d R[%d]=%d\n',ix1,ref(ix1),ix2,ref(ix2));
                    PU(r,c)=bitshift( (32-f)*ref(ix1) + f*ref(ix2) + 16 , -5,'int32' );
                end
            end
        else  %Modos Verticales
    %         fprintf('Vertical \n');
            [offset]=GetOffset(mode,Refs);
            for r=1:s %rows (y)
                for c=1:s %cols (x)
                    y=r-1; 
                    x=c-1;
                    i=bitshift((y+1)*A,-5,'int32');
                    f=bitand((y+1)*A,31,'int32');
                    ix1=offset+x+i+1+1;
                    ix2=offset+x+i+2+1;
    %                 fprintf('Modo[%d] [%d][%d] offset[%d] i[%d] f[%d] ix1=%d ix2=%d',mode,y,x,offset,i,f,ix1,ix2);
    %                 fprintf(' R[%d]=%d R[%d]=%d\n',ix1,ref(ix1),ix2,ref(ix2));
                    PU(r,c)=bitshift( (32-f)*ref(ix1) + f*ref(ix2) + 16 , -5 ,'int32');
                end
            end
        end
        %PostFiltrado si Modos Puros Horizonatal y Vertical
        if (((mode==10) || (mode==26)) && (s<32))
            PU=PostFiltering(PU,T,L,mode);
        end
        PUAngulars{m}=PU;
    %     imshow(uint8(PU))
    end
end
end

function [LP]=GetLeftProjectedPixels(intraInvAngle,L)
%Devuelve la proyección de L para modos con angulo negativo.
s=(numel(L)-1)/2;
LP=[];
for rx=1:s
   x=-rx;
%    ixVal=-1+bitshift(x*intraInvAngle+128,-8,'int32');
   ixVal=bitshift(x*intraInvAngle+128,-8,'int32');
   if (ixVal>=numel(L(:)))
       break;
   end
   LP(rx)=L(ixVal+1);
end
LP=flip(LP);
end

function [TP]=GetTopProjectedPixels(intraInvAngle,T)
%Devuelve la proyección de L para modos con angulo negativo.
s=(numel(T)-1)/2;
TP=[];
% fprintf('GetTopProjectedPixels(%d,T);\n',intraInvAngle);
for rx=1:s
   x=-rx;
%    ixVal=-1+bitshift(x*intraInvAngle+128,-8,'int32');
   ixVal=bitshift(x*intraInvAngle+128,-8,'int32');
   if (ixVal>=numel(T(:)))
       break;
   end
   TP(rx,1)=T(ixVal+1);
end
TP=flip(TP);
end

function [R]=GetRefs(s,mode,Refs,Refsf)
%-----------------------------------------------------------
%  Determinamos si se toman las Refs o las Refsf (filtradas)
%-----------------------------------------------------------
% Tamaño bloque: 4x4 -> No Filtrar
% Tamaño bloque: 8x8 -> Filtrar en modos 2,18 y 34
% Tamaño bloque: 16x16 -> Filtrar siempre excepto en modos: 9, 10, 11, 25, 26 y 27
% Tamaño bloque: 32x32 -> Filtrar siempre excepto en modos: 10 y 26 
% -----------------------------------------------
m=mode-1; %El array de modos empieza en 2, el índice de Refs en 1
if ((s==8) && ((mode==2) || (mode==18) || (mode==34)))
    R=Refsf{m,5};
elseif ( (s==16) && (mode~=9) &&  (mode~=10) &&  (mode~=11)&&  (mode~=25) &&  (mode~=26) &&  (mode~=27) )
    R=Refsf{m,5};
elseif ( (s==32) && (mode~=10) &&  (mode~=26) )
    R=Refsf{m,5};
else %Incluye tb. 4x4 
    R=Refs{m,5};
end
end

function [offset]=GetOffset(mode,Refs)
    offset=Refs{mode-1,4};
end

