% HEVC Partitions Mode
% HEVC SELECTION MODE

%--------------------------------------------------------------------------- 

% Calculamos el residuo y lo actualizamos en frameResImage
tuRES=origPU-tuPRE;
frameResImage(tuRow:tuRow + tuSize - 1, tuCol:tuCol + tuSize - 1) = tuRES;

[ixMatrix]=GetIxMatrixForSize(tuSize);

% Calculamos la transformada el residuo de la partition en curso
%--------------------------------------------------------------------------- 
[ T ] = HEVC_Transformation(bitDepth, M_Matrixs{ixMatrix}, tuRES);

% Cuantizamos la partition para la QP pasada.
%--------------------------------------------------------------------------- 
[ Q ] = HEVC_Quantization(T, Q_Matrixs{ixMatrix}, Qp, bitDepth);

% La transformada cuantizada para todos los bloques se guarda en frameCQImage
%--------------------------------------------------------------------------- 
frameCQImage(tuRow:tuRow + tuSize - 1, tuCol:tuCol + tuSize - 1) = Q;

%===============================================================
%  COMIENZA LA FASE DE RECONSTRUCCIÓN
%===============================================================

% Cuantización inversa para la QP pasada.
%--------------------------------------------------------------------------- 
[ IQ ] = HEVC_InvQuantization(Q, IQ_Matrixs{ixMatrix}, Qp, bitDepth);
frameCIQImage(tuRow:tuRow + tuSize - 1, tuCol:tuCol + tuSize - 1) = IQ;

% Transformada Inversa para Reconstruir el PU_Res
%--------------------------------------------------------------------------- 
[ IT ] = HEVC_InvTransformation(IQ, M_Matrixs{ixMatrix}, bitDepth);

%--------------------------------------------------------------------------- 
% Componemos la Reconstrucción de la predicción para el modo y el residuo reconstruido
% Actualizamos frameRecImage y el mapa de predicción frameRefsMap
%--------------------------------------------------------------------------- 
tuREC=tuPRE+IT;
% clip between 0 and 255
minVal = 0;
maxVal = bitshift(1,bitDepth) - 1;
tuREC(tuREC > maxVal) = maxVal;
tuREC(tuREC < minVal) = minVal;
frameRecImage(tuRow:tuRow + tuSize - 1, tuCol:tuCol + tuSize - 1) = tuREC;
frameRefsMap(tuRow + 1:tuRow + tuSize, tuCol + 1:tuCol + tuSize) = true;
