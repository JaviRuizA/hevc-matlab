% HEVC SELECTION MODE

global hevcPUs;

% Creación en CResM de los residuos para todos los modos 
% Creación en SADSM de los costes de cada predicción
% Calculamos también el R/D (Entropia/SAD) para el modo hevc
%--------------------------------------------------------------------------- 
PU=CPU{rPU,cPU};
for m=1:numModos
    CResM{rPU,cPU,m}=PU-CPreM{rPU,cPU,m};
    SADSM(rPU,cPU,m)=CalcHad(PU,CPreM{rPU,cPU,m});
    %Para calcular el R/D basado en el SAD tenemos que calcular la entropia de los coeficientes
    %para lo cual hay que transformar y cuantizar, y con los coeficientes calcular la entropia y
    %bits. (solo para BestModeBy ~= 'Coste')
    if ~strcmp(BestModeBy,'Coste')
        % Calculamos la transformada del residuo de este modo
        %--------------------------------------------------------------------------- 
        [ T ] = HEVC_Transformation(bitDepth, M_Matrix, CResM{rPU,cPU,m});
        % Cuantizamos para la QP pasada.
        %--------------------------------------------------------------------------- 
        [ Q ] = HEVC_Quantization(T, Q_Matrix, Qp, bitDepth);
        % Calculamos Bits y Rate-Distortion para estas Qs
        [~,BitsM(rPU,cPU,m),~,~,~,~] = GetCoefsEntropy({Q},true,false);
        RDM(rPU,cPU,m)=QPEntropyDistortion(BitsM(rPU,cPU,m), SADSM(rPU,cPU,m),Qp);
    end
end


%--------------------------------------------------------------------------- 
% Calculamos el mejor modo para el bloque
%--------------------------------------------------------------------------- 

%El calculo de mejor modo está comprobado con el código C HM. para el SAD cuando allí se ha
%deshabilitado del R/D y se escoge simplemente por mejor SAD

%Seleccionamos el método para determinar el mejor modo
% BestModeBy='Coste';  %Para seleccionar el mejor modo en base al SAD. Lo que está comprobado. 
% BestModeBy='RD';   %Para seleccionar el mejor modo en base al R/D (Entropia/SAD).

switch BestModeBy
    case 'Coste' %Seleccionamos por HAD
        % Puede haber varios modos con el mejor coste (nos quedaremos con el primer modo)
        bests=find(SADSM(rPU,cPU,:)==min(SADSM(rPU,cPU,:)));
        %Si entre los mejores están el 35 o el 1 (DC o PLANAR) se elige:
        %   Si estan ambos se elige 1:PLANAR
        ix35=find(bests==35);
        ix1=find(bests==1);
        if (~isempty(ix35))
            if (~isempty(ix1))
                bestMode=bests(ix1);
            else
                bestMode=bests(ix35);
            end
        else
            bestMode=bests(1);
        end
        if (~silentMode)
            fprintf('[%02d %s] (Coste)\n',bestMode,GetTxtModo(bestMode));
        end
        %Guardamos el SADS del mejor modo
        SADS(rPU,cPU)=SADSM(rPU,cPU,bestMode);
    case 'RD' %Seleccionamos por R/D (Entropy/SAD)
        % Puede haber varios modos con el mejor coste (nos quedaremos con el primer modo)
        bests=find(RDM(rPU,cPU,:)==min(RDM(rPU,cPU,:)));
        %Si entre los mejores están el 35 o el 1 (DC o PLANAR) se elige:
        %   Si estan ambos se elige 1:PLANAR
        ix35=find(bests==35);
        ix1=find(bests==1);
        if (~isempty(ix35))
            if (~isempty(ix1))
                bestMode=bests(ix1);
            else
                bestMode=bests(ix35);
            end
        else
            bestMode=bests(1);
        end
        if (~silentMode)
            fprintf('[%02d %s] (R/D)\n',bestMode,GetTxtModo(bestMode));
        end
        %Guardamos el RD del mejor modo
        RD(rPU,cPU)=RDM(rPU,cPU,bestMode);
        Bits(rPU,cPU)=BitsM(rPU,cPU,bestMode);
    otherwise
        error('Error: con hevc mode los modos BestModeBy son RD y Coste');
end
%************** BEGIN HEVC ASSERT CONTROL ***************************
% Comprobamos que el modo seleccionado coincide con el del HEVC
if (ASSERT_CONTROL)
    assert(hevcMode==bestMode,sprintf('NO COINCIDE EL MODO HEVC=%d CON EL SELECCIONADO=%d',hevcMode,bestMode));
end
%************** END HEVC ASSERT CONTROL ***************************

% Los mejores residuos se guardan en CRes{}
%--------------------------------------------------------------------------- 
CRes{rPU,cPU}=CResM{rPU,cPU,bestMode};

% Los mejores modos se guardan en Mod[]
%--------------------------------------------------------------------------- 
Mod(rPU,cPU)=bestMode;

%************** BEGIN HEVC ASSERT CONTROL ***************************
% Comprobamos que el residuo es el mismo que el que da el HEVC 
if (ASSERT_CONTROL)
    hevcPU=hevcPUs{rPU,cPU};
    hevcRes=hevcPU-hevcPUPrediction;
    assert(all(all(hevcRes==CRes{rPU,cPU})),'NO COINCIDE EL RESIDUO HEVC CON EL GENERADO');
end
%************** END HEVC ASSERT CONTROL ***************************

% Calculamos la transformada del mejor residuo
%--------------------------------------------------------------------------- 
[ T ] = HEVC_Transformation(bitDepth, M_Matrix, CRes{rPU,cPU});

% Cuantizamos para la QP pasada.
%--------------------------------------------------------------------------- 
[ Q ] = HEVC_Quantization(T, Q_Matrix, Qp, bitDepth);

% La transformada cuantizada para todos los bloques se guarda en CQ{}
%--------------------------------------------------------------------------- 
CQ{rPU,cPU}=Q;

%************** BEGIN HEVC ASSERT CONTROL ***************************
% Comprobamos que el residuo transformado y cuantizado coincide con el que da el HEVC 
if (ASSERT_CONTROL)
    hevcResTQ=GetHevcResTQ(nrPU, ncPU, rPU, cPU, f);
    assert(all(all(hevcResTQ==Q)),sprintf('[%d][%d] NO COINCIDE EL RESIDUO TRANSFORMADO Y CUANTIZADO CON EL DEL HEVC',rPU,cPU));
end
%************** END HEVC ASSERT CONTROL ***************************

%===============================================================
%  COMIENZA LA FASE DE RECONSTRUCCIÓN
%===============================================================

% Cuantización inversa para la QP pasada.
%--------------------------------------------------------------------------- 
[ IQ ] = HEVC_InvQuantization(Q, IQ_Matrix, Qp, bitDepth);
CIQ{rPU,cPU} = IQ;

% Transformada Inversa para Reconstruir el PU_Res
%--------------------------------------------------------------------------- 
[ IT ] = HEVC_InvTransformation(IQ, M_Matrix, bitDepth);

%************** BEGIN HEVC ASSERT CONTROL ***************************
% Comprobamos que la decuantización y la transformada inversa coinciden con HEVC 
if (ASSERT_CONTROL)
    hevcInvQT=GetHevcInvQT(nrPU, ncPU, rPU, cPU, f);
    assert(all(all(hevcInvQT==IT)),sprintf('[%d][%d] NO COINCIDE LA INVERSA DE QUANTIZACIÓN + INV TRANSFORMADA CON EL HEVC',rPU,cPU));
end
%************** END HEVC ASSERT CONTROL ***************************

% Componemos la Reconstrucción de la predicción para el modo y el residuo reconstruido
%--------------------------------------------------------------------------- 
% Componemos la Reconstrucción de la predicción para el modo y el residuo reconstruido
%--------------------------------------------------------------------------- 
Pre=CPreM{rPU,cPU,bestMode};
CPre{rPU,cPU} = Pre; 
Rec=Pre+IT;
% clip between 0 and 255
minVal = 0;
maxVal = bitshift(1,bitDepth) - 1;
Rec(Rec > maxVal) = maxVal;
Rec(Rec < minVal) = minVal;

% Los bloques reconstruidos usando el mejor modo se guardan en CREC{} y serán usados para la
% siguiente predicción. Se actualiza la matriz de ya reconstruidos
%************** BEGIN HEVC ASSERT CONTROL ***************************
% Comprobamos que la recosntrucción coincide con el HEVC 
if (ASSERT_CONTROL)
    hevcRec=GetHevcRec(nrPU, ncPU, rPU, cPU, f);
    assert(all(all(hevcRec==Rec)),sprintf('[%d][%d] NO COINCIDE LA RECONSTRUCCIÓN CON EL HEVC',rPU,cPU));
end
%************** END HEVC ASSERT CONTROL ***************************
%--------------------------------------------------------------------------- 
CREC{rPU,cPU}=Rec;
recMatrix(rPU,cPU)=true;
