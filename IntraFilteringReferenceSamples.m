function [Tf, Lf, Rf] = IntraFilteringReferenceSamples( T, L , R, bitDepth)
% % Intra Smoothing Filter
% % PU = 4x4      -> Not Available
% % PU = 8x8      -> Only Planar, Angular(2,18,34)
% % PU = 16x16    -> All modes except DC, Angular(10,26,9,11,25,27)
% % PU = 32x32    -> All modex except DC, Angular(10,26)
% 
% % Inputs  : Neighboring Pixels
% % Outputs : Smoothed Neighboring Pixels

% REFERENCIA: 4.2.2 Filtering Process of Reference Samples (Libro HEVC)
% Se realiza el filtrado de las referencias, independientemente de que sean luego elegidas o 
% no en función del modo.
% ----------------------------------------------
% Modo: DC  -> No Filtrar
% Tamaño bloque: 4x4 -> No Filtrar
% Tamaño bloque: 8x8 -> Filtrar en modos 2, 18 y 34
% Tamaño bloque: 16x16 -> Filtrar siempre excepto en modos: 9, 10, 11, 25, 26 y 27
% Tamaño bloque: 32x32 -> Filtrar siempre excepto en modos: 10 y 26 
% -----------------------------------------------
% Aquí sólo se realiza el filtrado, luego se decidirá si se seleccionan o no en base a la tabla
% anterior
% El filtrado puede ser de dos tipos, 
%   a) Three tap filtering: [1 2 1]/4 aplicando el filtro.
%   b) Linear interpolation de las esquinas.
% En función del tamaño del bloque se aplica uno, otro o ninguno:
%   4x4 -> No se aplica ninguno, se devuelve en Tf y Lf los valores de entrada.
%   8x8 -> Se aplica el Tap filtering.
%  16x16-> Se aplica el Tap filtering.
%  32x32-> Se aplica el Linear Interpolation.

%Obtenemos el tamaño del PU  a predecir del tamaño del T o L
s=(numel(T)-1)/2;
RSize=4*s+1;

%Determinamos si los valores cumplen la condición flatness para ver que filtrado se aplica.
flatnessThreshold = bitshift(1,(bitDepth-5),'int32');
flatnessL = abs(L(1)+L(end)-2*L(s+1)) < flatnessThreshold;
flatnessT = abs(T(1)+T(end)-2*T(s+1)) < flatnessThreshold;
flatness=flatnessT && flatnessL;
shift=log2(bitshift(s,1,'int32'));

% flatness a true iguala el código anterior que aplicaba el filtrado por interpolación 
% siempre, sin tener en cuenta el flatness a los bloques de 32x32
% flatness=true; 

if (s == 32) && (flatness) %tamaño 32x32 cumpliendose la condición de flatness
    Tf(1,1)=T(1);
    Lf(1,1)=L(end);  %Empezamos por el bottom, por eso hay que hacer flip del Lf al final del bucle.
    for i=2:(2*s+1)
        Tf(1,i)=bitshift( (64-i+1)*T(1)   + (i-1)*T(2*s+1) + 32 , -shift,'int64') ;
        Lf(i,1)=bitshift( (64-i+1)*L(end) + (i-1)*L(1)     + 32 , -shift,'int64') ;
    end
    Lf=flip(Lf);
    Rf=[flip(Lf)' Tf(2:end)];
elseif (s >= 4) %tamaños 8x8 o 16x16 o 32x32_no_flatness
    Rf=zeros(1,RSize);
    Rf(1)=R(1);
    Rf(end)=R(end);
    for i=2:RSize-1
        Rf(i)=bitshift(R(i-1) + 2*R(i) + R(i+1) +2 ,-2,'int32');
    end
    Lf=flip(Rf(1:2*s+1))';
    Tf=Rf(2*s+1:end);
% else  %tamaño 4x4
%     Tf=T;
%     Lf=L;
%     Rf=[flip(Lf)' Tf(2:end)];
end


end

