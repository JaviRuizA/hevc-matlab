function [ PUPlanar ] = GenPlanarPrediction(T,L,Tf,Lf)
%Generación de la predicción Planar para un PU en función de las predicciones L y T
%Obtenemos el tamaño del PU  a predecir del tamaño del T o L
N=(numel(T)-1)/2;  

PUPlanar=zeros(N,N);
if N>4 
    T=double(Tf(2:N+2));
    L=double(Lf(2:N+2));
else
    T=double(T(2:N+2));
    L=double(L(2:N+2));
end

for r=0:N-1 %rows
    for c=0:N-1 %columns
        %el multiplicador 1 va de 0 a s-1  multiplicador 2 va de 1 a s
        %Interpolación horizontal
        m1=double(N-1-c);
        m2=double(c+1);
        Ph=m1*L(r+1) + m2*T(N+1);
        %Interpolación vertical
        m1=double(N-1-r);
        m2=double(r+1);
        Pv=m1*T(c+1) + m2*L(N+1);
        PUPlanar(r+1,c+1)=bitshift(Ph+Pv+N,-(log2(N)+1),'int32');
    end
end

end
