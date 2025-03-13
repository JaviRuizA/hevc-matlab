classdef Indexes
    properties(Constant)
        % Indices para los elementos de cada CTU en frameParts -----------------------
        ixCUid     =  1; % Identificador de CU dentro del CTU
        ixCUsize   =  2; % Tama�o de bloque CU (32 16 8)
        ixTUsize   =  3; % Tama�o de bloque TU (32 16 8 4)
        ixTUrow    =  4; % Posici�n x (fila) dentro del CTU
        ixTUcol    =  5; % Posici�n y (columna) dentro del CTU
        ixRow      =  6; % Posici�n x (fila) dentro del frame
        ixCol      =  7; % Posici�n y (columna) dentro del frame
        ixMode     =  8; % Modo de predicci�n Intra
        ixTexClass =  9; % Clasificaci�n de textura del bloque (-1 None, 0 Plain, 1 Edge, 2 Texture)
        ixMaskVal  = 10; % Valor del factor multiplicador de masking
        %-----------------------------------------------------------------------------

        %Indices para los modos de predicci�n ----------------------------------------
        ixPlanarPre =  1;      % PLANAR
        ixDCPre     = 35;     % DC   (ponemos el DC en el 35 porque as� los modos angulares coinciden con su indice)
                              % los indices de angular van de 2 a 34 incluidos.
        ixsAngular  = [2:34]; % ANGULARS. Mode=1 ser� el ix=2=>ixsAngular(1)
        %-----------------------------------------------------------------------------
        
        % �ndices para los tipos de enmascaramiento por textura ----------------------
        ixPlain   = 0; % PLAIN o plano, sin textura
        ixEdge    = 1; % EDGE o borde, con textura claramente orientada
        ixTexture = 2; % TEXTURE o textura, con textura
        %-----------------------------------------------------------------------------
    end
end