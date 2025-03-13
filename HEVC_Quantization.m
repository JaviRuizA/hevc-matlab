function [ piQCoef ] = HEVC_Quantization( Coefs, Quant_Mat , QP, channelBitDepth )
% signCoefs=int64(sign(Coefs));
% absCoefs=abs(Coefs);
% NVal = size(Coefs,1);
% 
% MAX_TR_DYNAMIC_RANGE=15;
% Log2TrSize=log2(NVal);
% QP6=floor(QP/6);
% QUANT_SHIFT=14;
% iTransformShift=MAX_TR_DYNAMIC_RANGE-channelBitDepth-Log2TrSize;
% iQBits=QUANT_SHIFT + QP6 + iTransformShift;
% qBits8=iQBits-8;
% iAdd=bitshift(171,(iQBits-9),'int64');
% 
% tmpLevel=int64(absCoefs.*Quant_Mat);
% iLevel=bitshift(tmpLevel+iAdd,-iQBits);
% piQCoef=Clip(iLevel.*signCoefs);

%Determinamos por la matriz de cuantización si estamos aplicando o no CSF
% if (~(mean2(Quant_Mat)==Quant_Mat(1,1))) 
%     enableScalingLists=true;
% else 
%     enableScalingLists=false;
% end

% Ver TComTrQuant.cpp -> TComTrQuant::xQuant
MAX_TR_DYNAMIC_RANGE=15;
QUANT_SHIFT = 14;

QP_per = int32(floor(QP/6));
%QP_rem = int32(mod(QP, 6));

useTransformSkip = false; % En principio no hay transform skip
%useRDOQ = false; % En principio no hay RDOQ

%entropyCodingMinimum = int32(-(bitshift(1, MAX_TR_DYNAMIC_RANGE)));
%entropyCodingMaximum = int32(bitshift(1, MAX_TR_DYNAMIC_RANGE) - 1);

NVal = size(Coefs,1);
uiLog2TrSize = log2(NVal);

%scalingListType = 0; % En INTRA es 0

%g_quantScales = int32([26214, 23302, 20560, 18396, 16384, 14564]);
%defaultQuantisationCoefficient = g_quantScales(QP_rem + 1);
% QP_rem + 1 lo ponemos debido a que Matlab comienza los índices con 1 y C++ con 0.

iTransformShift = MAX_TR_DYNAMIC_RANGE - channelBitDepth - uiLog2TrSize;
if useTransformSkip
    iTransformShift = max(0,iTransformShift);
end
iQBits = int32(QUANT_SHIFT + QP_per + iTransformShift);

% if ADAPTIVE_QP_SELECTION
%iQBitsC = int32(2147483647);
%iAddC   = int32(2147483647);
% endif

iAdd = int64(bitshift(171, (iQBits - 9), 'int64'));
%qBits8 = iQBits - 8;

iLevel = int64(Coefs);
iSign = sign(iLevel);

tmpLevel = int64(abs(iLevel) .* int64(Quant_Mat));

quantisedMagnitude = bitsra(tmpLevel + iAdd, iQBits);
%deltaU = bitsra( tmpLevel - ( bitshift(quantisedMagnitude, iQBits, 'int64' )), qBits8);

quantisedCoefficient = quantisedMagnitude .* iSign;

piQCoef = int32(Clip(quantisedCoefficient));
end

