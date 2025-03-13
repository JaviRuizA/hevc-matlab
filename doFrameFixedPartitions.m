%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% doMainFixedPartitions: PROCESA UN FRAME CUANDO LAS PARTICIONES
%                        TIENEN TODAS EL MISMO TAMAÑO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BLOQUE: IntraPredictionPreprocess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BLOQUE PARA PREPROCESAR LA PREDICCION INTRA
% CREA MATRICES CON LOS VALORES DE LOS PIXELS UTILIZADOS PARA LA 
% PREDICCION INTRA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%************** BEGIN HEVC ASSERT CONTROL ***************************
% Controlamos que todos los PU originales sean exactos con los del HEVC
if (ASSERT_CONTROL)
    [ retBool, checkMatrix ] = CheckCellMatrix( CPU, f);
    assert(retBool,'NO COINCIDE LA IMAGEN EN ALGÚN PU');
end
%************** END HEVC ASSERT CONTROL ***************************

numModos=size(Indexes.ixsAngular,2)+2;

%Obtenemos un cell array de la imagen original con PUs del mismo tamaño 
CPU = GeneratePUC(orig_img,PUSize);

[nrPU,ncPU]=size(CPU);
CPreM=cell(nrPU,ncPU,numModos);  %Predicciones por modo
CPre=cell(nrPU,ncPU);            %Predicciones del mejor modo
CREC=cell(nrPU,ncPU);            %Cell array de PUs Reconstruidos a partir del optimo resudio

%----------------------------------------------------------------------
% Variables para modo HEVC
%----------------------------------------------------------------------
CResM=cell(nrPU,ncPU,numModos);       %Residuos por modo
SADSM=zeros(nrPU,ncPU,numModos);      %SADs mor modo
SADS=zeros(nrPU,ncPU);                %SADs mejor modo
CRes=cell(nrPU,ncPU);                 %Residuos para el mejor modo de cada PU
Mod=zeros(nrPU,ncPU);                 %Mejor Modo por bloque
CQ=cell(nrPU,ncPU);                   %Coeficientes cuantizados para mejor modo para cada PU
CIQ=cell(nrPU,ncPU);                  %Cuantización inversa para el mejor modo para cada PU
BitsM=zeros(nrPU,ncPU,numModos);      %Bits para cada PU transformado y cuantizado para cada modo.
RDM=zeros(nrPU,ncPU,numModos);        %R/D (Entropia/SAD) para cada PU transformado y cuantizado para cada modo.
RD=zeros(nrPU,ncPU);                  %R/D (entropia/SAD) para cada PU para el mejor modo
Bits=zeros(nrPU,ncPU);                %Bits para cada PU para el mejor modo

%----------------------------------------------------------------------
% Variables para modo PHEVC
%----------------------------------------------------------------------
CFResM = cell(nrPU,ncPU,numModos);       % Transformada del residuo para cada modo
CFQResM = cell(nrPU,ncPU,numModos);      % Resido en Frecuencia quantizado perceptualmente para cada modo
PCostesM = zeros(nrPU,ncPU,numModos);    % Coste Perceptual para cada modo
PBitsM = zeros(nrPU,ncPU,numModos);      % Bits de cada bloque para cada modo
PRDM = zeros(nrPU,ncPU,numModos);        % R/D Perceptual de cada bloque para cada modo
CFRes = cell(nrPU,ncPU);                 % Residuo en frecuencia para el modo seleccionado
PCostes = zeros(nrPU,ncPU);              % Coste por bloque para el modo seleccionado
PBits = zeros(nrPU,ncPU);                % Bits por bloque para el modo seleccionado
PRD = zeros(nrPU,ncPU);                  % R/D por bloque para el modo seleccionado
FMod = zeros(nrPU,ncPU);                 % Modo seleccionado por bloque en frecuencia
CFQRes = cell(nrPU,ncPU);                % Residuo en frecuenica cuantizado perceptualmente para el modo seleccionado.
CSSimRecM = zeros(nrPU,ncPU,numModos);
CSSimRec  = zeros(nrPU,ncPU,numModos);
CSSimMapRecM = cell(nrPU,ncPU,numModos);
CSSimMapRec  = cell(nrPU,ncPU,numModos);

% Variables necesarias para la ejecución del Masking
ProcessedBlocks = zeros(nrPU,ncPU);      % Matriz booleana que indica los bloques que se han procesado del frame

% zMatrix es la matriz de índices de recorrido en z-index. 
%La función GetZMatrix calcula cómo debe ser el recorrido z-index o no, dependiendo de si hay
%descomposición en niveles o no. Si los PU son de 32 o 16, no hay descomposición en z-index
%pero la matriz zMatrix ya indica este hecho con sus valores.
zMatrix=GetZMatrix(ctuSize,nLevels,width,height); 

% recMaatrix es una matriz de booleanos que indica que bloques han sido ya reconstruidos y están
% disponibles para la predicción de los siguientes.
%recMatrix=boolean(zeros(nrPU,ncPU)); % 'boolean' es una función de
%simulink, mejor usar 'logical', aunque también se puede dejar así:
recMatrix=false(nrPU,ncPU);

%Número total de bloques a procesar.
numBlocks=numel(zMatrix);

%     %para test_cost_function.m
%     savedBpp=0.0;


%Procesamos los bloques en el orden que indica la zMatrix.
for b=1:numBlocks
    %Buscamos la fila y columna del siguiente bloque a procesar. Eso lo da la zMatrix.
    [rPU,cPU]=find(zMatrix==b);

    if (~silentMode)
        fprintf('Frame[%03d] PU%04d[%02d][%02d] ',frame,b,rPU,cPU);
    end

    %Obtenemos las muestras de referencia para calcular la predicción Intra de los bloques.
    %Tanto las muestras sin filtrar como las filtradas.
    % T=Top  L=Left  R=Referencias  'f' indica filtradas
    [T, L, R]=GetReferenceSamples(CPU, CREC, recMatrix, rPU, cPU, bitDepth);
    [Tf, Lf, Rf]=IntraFilteringReferenceSamples(T,L,R,bitDepth);

    %************** BEGIN HEVC ASSERT CONTROL ***************************
    % Comprobamos que las referencias para calcular la predicción son
    % iguales que las del HEVC.
    if (ASSERT_CONTROL && strcmp(RunMode,'hevc'))
        [ hevcR, hevcRf] = GetHevcRefs( nrPU, ncPU, rPU, cPU, f);
        assert(all(R==hevcR)  ,sprintf('NO COINCIDE LA REFERENCIA R usada para el PU[%d][%d]',rPU,cPU));
        assert(all(Rf==hevcRf),sprintf('NO COINCIDE LA REFERENCIA Rf usada para el PU[%d][%d]',rPU,cPU));
    end
    %************** END HEVC ASSERT CONTROL ***************************

    %Obtenemos las predicciones, PLANAR, DC y ANGULARS
    [PUPlanarPre]=GenPlanarPrediction(T,L,Tf,Lf);
    [PUDCPre]=GenDCPrediction(T,L); % Al modo DC no se aplica filtro nunca por eso solo recibe sin filtrar
    [PUAngulars]=GenAngularPredictions(R,Rf);

    %Asignamos los Predicted PUs a su cell correspondiente CPreM
    %Asignamos Planar  [1]
    CPreM{rPU,cPU,Indexes.ixPlanarPre}=PUPlanarPre;
    %Asignamos DC [35]
    CPreM{rPU,cPU,Indexes.ixDCPre}=PUDCPre;
    %Asignamos los Angulares [n]
    for ixAng=1:size(Indexes.ixsAngular,2)
        m=Indexes.ixsAngular(ixAng)-1; %El array de modos empieza en 2, el índice de PUAngulasr en 1
        CPreM{rPU,cPU,Indexes.ixsAngular(ixAng)}=PUAngulars{m};
    end

    %************** BEGIN HEVC ASSERT CONTROL ***************************
    % Comprobamos que la Predicción de este PU coincide con la generada
    % por el HEVC
    if (ASSERT_CONTROL && strcmp(RunMode,'hevc'))
        [ hevcMode, hevcPUPrediction ] = GetHevcPUPrediction( nrPU, ncPU, rPU, cPU, f);
        PUCPredictons(1:35,1)=CPreM(rPU,cPU,:);
        assert(all(all(PUCPredictons{hevcMode}==hevcPUPrediction)),sprintf('NO COINCIDE LA PREDICCION MODE=%d PU[%d][%d]',hevcMode,rPU,cPU));
    end
    %************** END HEVC ASSERT CONTROL ***************************


    %Continuamos la ejecución en función del modo
    if (strcmp(RunMode,'hevc'))
        % HEVC SELECTION MODE
        doHEVCMode
    else
        % PHEVC SELECTION MODE
        doPHEVCMode
    end
    %fPU_waitbar.iterate(1);

end  %numBlocks

if (~silentMode)
    fprintf('\n');
    fprintf('Frame %03d Regenerando imagen a partir de los PUs reconstruidos ...\n',frame);
end

%close(fPU_waitbar);

%Obtenemos la imagen reconstruida
[RecImage]=GetRecImage(CREC);

% % Guardamos la imagen reconstruida
% %-----------------------------------------------------
% if (~silentMode)
%     fprintf('Frame %03d Grabando imagen reconstruida ...\n',frame);
% end
% %outputImage =>  <originalName>_<bitDepth>_<PUSize>_<Qp>.bmp
% 
% %Guardamos el yuv reconstruido
% yuvOutput=sprintf('%s\\%s_%s_%03d_bd%02d_ctu%02d_l%1d_qp%02d_%s_bm%s%s',RunMode_dir,RunMode,yuvSequenceBasename,frame,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy,'.yuv');
% [rY,rU,rV]=Y2YUV(uint8(RecImage));
% SaveYuv(yuvOutput,'w',rY,rU,rV);
% 
% %Guardamos el bmp reconstruido
% outputImage=sprintf('%s\\%s_%s_%03d_bd%02d_ctu%02d_l%1d_qp%02d_%s_bm%s%s',RunMode_dir,RunMode,yuvSequenceBasename,frame,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy,'.bmp');
% imwrite(uint8(RecImage),outputImage);
% 
% %Mostramos la imagen
% if (~silentMode)
%     imshow(uint8(RecImage));
% end
% 
% %-----------------------------------------------------
% %  GUARDANDO DATOS EN FICHEROS .mat
% %-----------------------------------------------------
% 
% % Guardamos los cell arrays y otros asociados a la ejecución
% % cellFileName =>  <originalName>_<cellArray>_<bitDepth>_<PUSize>_<Qp>.mat
% %-----------------------------------------------------
% if (~silentMode)
%     fprintf('Frame %03d Guardando datos en .mats ...\n',frame);
% end
% 
% %-----------------------------------------------------
% % Generando .mat
% %-----------------------------------------------------
% 
% if guardar_mat == true
%     % CPU   Cell array con todos los PUs
%     SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CPU',CPU,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%     % CPreM   Cell array con todas las Predicciones para cada PU y Modo Intra
%     SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CPreM',CPreM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%     % CREC  Cell array con la reconstrucción de cada PU
%     SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CREC',CREC,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
% end
% if (strcmp(RunMode,'hevc')) %HEVC
%     if guardar_mat == true
%         % CResM  Cell array con todos los residuos por modo
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CResM',CResM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % Mod    array con el mejor Modo Intra para cada PU 
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'Mod',Mod,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % CRes Cell array con el Residuo para cada PU del mejor Modo Intra
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CRes',CRes,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % SADSM array con los SADS para cada Modo 
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'SADSM',SADSM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % SADS array con los SADS para el modo seleccionado 
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'SADS',SADS,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % BitsM Array con los bits para cada bloque transformado y cuantizado para cada modo
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'BitsM',BitsM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % RDM Array con el R/D (entropy/SAD) para cada bloque transformado y cuantizado para cada modo
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'RDM',RDM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % RD Array con el R/D (entropy/SAD) para cada bloque transformado y cuantizado para el mejor modo
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'RD',RD,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % Bits Array con los bits para cada bloque transformado y cuantizado para el mejor modo
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'Bits',Bits,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % CPre   Cell array con los valores transformados y cuantizados para cada PU
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CPre',CPre,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % CIQ   Cell array con los valores transformados y cuantizados para cada PU
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CIQ',CIQ,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%     end
%     % CQ   Cell array con los valores transformados y cuantizados para cada PU
%     SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CQ',CQ,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%     
% else %PHEVC
%     if guardar_mat == true
%         % CFResM    Cell array con todos los residuos en frecuencia
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CFResM',CFResM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % CFQResM   Cell array con todos los residuos en frecuencia cuantizados por modo
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CFQResM',CFQResM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % FMod    array con el mejor Modo Intra para cada PU 
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'FMod',FMod,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % CFRes array con el Residuo en frecuencia 
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CFRes',CFRes,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % PCostesM array con los Costes para cada Modo Intra para cada PU
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'PCostesM',PCostesM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % PCostes array con los Costes para el modo seleccionado
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'PCostes',PCostes,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % PBitsM array con los bits de los residuos cuantizados perceptualmente para cada modo
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'PBitsM',PBitsM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % PRDM array con el R/D (entropia/Coste) de los residuos cuantizados perceptualmente para cada modo
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'PRDM',PRDM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % PRD array con el R/D (entropia/Coste) de los residuos cuantizados perceptualmente para el modo seleccionado
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'PRD',PRD,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % CSSimRecM array con los valores de SSIM para cada modo
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CSSimRecM',CSSimRecM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % CSSimMapRecM array con los valores de mapa SSIM para cada modo
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CSSimMapRecM',CSSimMapRecM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % CSSimRec array con los valores de SSIM para el mejor modo
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CSSimRec',CSSimRec,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%         % CSSimMapRec array con los valores de mapa SSIM para el mejor modo
%         SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CSSimMapRec',CSSimMapRec,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%     end
%     % PBits array con los bits de los residuos cuantizados perceptualmente para el modo seleccionado
%     SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'PBits',PBits,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
%     % CFQRes array con los residuos en frecuencia cuantizados correspondientes al modo seleccionado
%     SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CFQRes',CFQRes,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
% end
