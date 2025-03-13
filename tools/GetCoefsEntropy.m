function [ImageEntropy,ImageBits,PUEntropies,PUBits,PUTotalBits,PUbpp]=GetCoefsEntropy(CellMatrix,signCoding,noDC)
%Obtiene la entropia y los bits resultantes del cell array que se pasa
%Parametros:
%  CellMatrix:  Cell Matrix con los coeficientes cuantizados a partir de los que calcular la entropia
%  SignCoding    : Determina los negativos como simbolos distintos para el calculo de la entropia si
%                  signCoding=true, true o false
%  noDC          : Elimina la componente DC para el calculo de la entropia del bloque.
%Salida:
%  ImageEntropy  : Entropia calculada con todos los coeficientes de la imagen
%  ImageBits     : Bits que ocupa la imagen con la entropia anterior
%  PUEntropies   : Matriz con la entropia para cada PU correspondiente a los PUs del Cell Array pasado
%  PUBits        : Matriz con los bits que ocupan cada PU según su entropia  
%  PUTotalBits   : Total de bits que se obtienen tras procesar toda la imagen en base a PUs
%  PUbpp         : Entropia final en Bits por Pixel que se obtienen tras procesar toda la imagen en base a PUs

[pr,pc]=size(CellMatrix);
sr=size(CellMatrix{1,1},1);
sc=size(CellMatrix{1,1},2);
ir=pr*sr;
ic=pc*sc;
ImageCoefs=zeros(ir,ic);
PUEntropies=zeros(pr,pc);
PUBits=zeros(pr,pc);

%----------------------------------------------------------------------------
%Calculamos la entropia en base al conjunto total de coeficientes cuantizados
%----------------------------------------------------------------------------
%Creamos el array global de coeficientes calculados
for r=1:pr
    ixr=r*sr-(sr-1);
    for c=1:pc
        ixc=c*sc-(sc-1);
        block=CellMatrix{r,c};
        ImageCoefs(ixr:ixr+sr-1,ixc:ixc+sc-1)=block;
    end
end
ImageEntropy=ZeroOrderEntropy(ImageCoefs,signCoding,noDC);
%Calculamos los bits ocupados.
numPixels=ir*ic;
ImageBits=ImageEntropy*numPixels;

%----------------------------------------------------------------------------
%Calculamos la entropia por PUs
%----------------------------------------------------------------------------
%Creamos el array global de coeficientes calculados
numBlockPixels=numel(CellMatrix{1,1});
for r=1:pr
    for c=1:pc
        block=CellMatrix{r,c};
        PUEntropies(r,c)=ZeroOrderEntropy(block,signCoding,noDC);
        PUBits(r,c)=PUEntropies(r,c)*numBlockPixels;
    end
end
PUTotalBits = sum(sum(PUBits));
PUbpp=PUTotalBits/(ir*ic);
end