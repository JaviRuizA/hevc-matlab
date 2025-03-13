function [PUDC]=GenDCPrediction(T,L)
%Generaci�n de la predicci�n DC para un PU en funci�n de las predicciones L y T
%Obtenemos el tama�o del PU  a predecir del tama�o del T o L
s=(numel(T)-1)/2;

T=double(T);
L=double(L);

dcVal =  bitshift( sum(L(2:(s+1))) + sum(T(2:(s+1))) + s , -(log2(s)+1),'int32' );

%Filtrado adicional a los bloques 4x4, 8x8 y 16x16
if (s<32)
    PUDC=PostFiltering(zeros(s,s),T,L,35,dcVal);
else
    %Bloques de 32x32 no llevan filtrado adicional
    PUDC(1:s,1:s)=dcVal;
end

end

