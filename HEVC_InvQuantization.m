function [ piCoef ] = HEVC_InvQuantization(Coefs,Quant_Mat, QP, channelBitDepth)
%Determinamos por la matriz de cuantización si estamos aplicando o no CSF
if (~(mean2(Quant_Mat)==Quant_Mat(1,1))) 
    enableScalingLists=true;
else 
    enableScalingLists=false;
end

% Ver TComTrQuant.cpp -> TComTrQuant::xDeQuant
MAX_TR_DYNAMIC_RANGE=15;
IQUANT_SHIFT=6;

NVal = size(Coefs,1);
uiLog2TrSize = log2(NVal);

bClipTransformShiftTo0 = false; % En principio no hay transform skip
originalTransformShift = MAX_TR_DYNAMIC_RANGE - channelBitDepth - uiLog2TrSize;
if bClipTransformShiftTo0
    iTransformShift = max(0,originalTransformShift);
else
    iTransformShift = originalTransformShift;
end
QP_per = int32(floor(QP/6));
QP_rem = int32(mod(QP, 6));

if enableScalingLists
    LOG2_SCALING_LIST_NEUTRAL_VALUE = 4;
else
    LOG2_SCALING_LIST_NEUTRAL_VALUE = 0;
end
rightShift = int32((IQUANT_SHIFT - (iTransformShift + QP_per)) + (LOG2_SCALING_LIST_NEUTRAL_VALUE));

clipQCoef=Clip(Coefs);

if enableScalingLists
    if (rightShift > 0)
        iAdd = bitshift(1,(rightShift - 1),'int32');
        iCoeffQ = bitsra((clipQCoef .* int32(Quant_Mat)) + iAdd, rightShift);
        piCoef = Clip(iCoeffQ);
    else
        leftShift = -rightShift;
        iCoeffQ = bitshift((clipQCoef .* int32(Quant_Mat)), leftShift, 'int32');
        piCoef = Clip(iCoeffQ);
    end
else
    g_invQuantScales = int32([40, 45, 51, 57, 64, 72]);
    scale = g_invQuantScales(QP_rem + 1) * int32(ones(NVal)); % Matriz para aprovechar características matriciales de Matlab (en HM hay un bucle for para cada coeficiente)
    % QP_rem + 1 lo ponemos debido a que Matlab comienza los índices con 1 y C++ con 0.
    if (rightShift > 0)
        iAdd = bitshift(1,(rightShift - 1),'int32');
        iCoeffQ = bitsra((int32(clipQCoef) .* scale + iAdd), rightShift);
        piCoef = Clip(iCoeffQ);
    else
        leftShift = -rightShift;
        iCoeffQ = bitshift((int32(clipQCoef) .* scale), leftShift,'int32');
        piCoef = Clip(iCoeffQ);
    end
end

end