function yuvOutput=HEVC_Main(yuvSequence,framesToProcess,width,height,bitDepth,Qp,ctuSize,nLevels,RunMode,WeightMode,BestModeBy,runDir,HEVCPartitions)
% yuvOutput=HEVC_Main(yuvSequence,framesToProcess,width,height,bitDepth,Qp,ctuSize,nLevels,RunMode,WeightMode,BestModeBy,runDir)
% PREDICCION INTRA PARA HEVC CON DOS MODOS DE TRABAJO: HEVC Y PHEVC 
% Parámetros:
%   yuvSequence     : Secuencia YUV de entrada en formato 420, PONER LA EXENSION .yuv en el parametro
%   framesToProcess : Rango de Frames a procesar de la secuencia
%   width           : Ancho del frame en pixels
%   height          : Alto del frame en pixels
%   bitDepth        : Profundidad de bits. Por defecto 8
%   Qp              : QP value as 0 to 51. Por defecto 4
%   ctuSize         : Tamaño de la Coding Tree Unit. Por defecto 64 
%   nLevels         : Niveles de descomposicion del CTU para obtener PUs de igual tamaño. Default 0;
%                     Ejemplo: si ctuSize=64 entonces level->PUSize 0->64 1->32 2->16 3->8 4->4
%                     Ejemplo: si ctuSize=16 entonces level->PUSize 0->16 1->8 2->4
%   RunMode           Define el modo en el que se va a realizar la predicción.
%                     'hevc' : Calcula la mejor predicción según el estándar HEVC.
%                     'phevc': Calcula la mejor predicción según nuestra própia propuesta.
%   WeightMode      : Define el tipo de matriz de pesos CSF.
%                     'noCSF' : No se aplica cuantización perceptual.
%                     'staCSF': Matriz de pesos CSF del estándar HEVC.
%                     'ourCSF': Matriz de pesos CSF própia con caída para bajas frecuencias.
%                     'CSF'   : Con PU=4 se aplica 'ourCSF', en el resto de casos 'staCSF'.
%   BestModeBy      : Determina el método para obtener el mejor modo.
%                     Para HEVC:
%                       'Coste': Obtiene el mejor modo basado sólo en el SAD (testeado con HM)
%                       'RD'   : Obtiene el mejor modo basado en el R/D (Entropy/SAD) 
%                     Para PHEVC:
%                       'HAD'      : Se utiliza el Hadamard del HEVC para determinar la distorsión lambda del HEVC.
%                       'SAD-Res'  : Se utiliza el SAD del residuo para determinar la distorsión lambda del HEVC.
%                       'SAD-FQRes': Se utiliza el SAD de los coef. cuantizados para determinar la distorsion lambda del HEVC.
%                       'SSIM1-Pre': Se utiliza la SSIM para determinar la distorsión entre la predicción y el PU. lambdaSSIM1 
%                       'SSIM2-Pre': Se utiliza la SSIM para determinar la distorsión entre la predicción y el PU. lambdaSSIM2 
%                       'SSIM3'    : Se utiliza la SSIM para determinar la distorsión entre la predicción y el PU. proporcionalidad entre distorsión y bits.
%   runDir          : Directorio de salida de los archivos resultantes.
%   HEVCPartitions  : Default false. True indica que se carga el fichero SplitFlags.dat con las particiones del HEVC

%Cargamos la definición de globales
%DefineGlobals;

%Control ASSERT con datos de HEVC 
global ASSERT_CONTROL;
if isempty(ASSERT_CONTROL)
    ASSERT_CONTROL=false;
end

% SILENT MODE 
%silentMode=false; %SI saca printfs e imagenes ....
silentMode=true;  %NO saca printfs ni imagenes....

% fullRD = true;  para el PHEVC, habilita la reconstrucción de cada predicción 
%                 y la obtención de la calidad perceptual con la msssim.m
% msssim.m de: http://sse.tongji.edu.cn/linzhang/IQA/Evalution_MS_SSIM/eva-MS-SSIM.htm
fullRD=true;
fullRD=false;

%Forzamos a que PHEVC coja los modos de HEVC
forceHevcModes=false;

%Primamos los modos Planar y DC tambien en el PHEVC
priorityPlanarDC=false;

% OUTPUT_MODE
%guardar_mat=true; % Guarda todos los .mat para debug
guardar_mat=false; % Guarda lo mínimo para obtener las métricas

%-------------------------------------------------------------------------
% BEGIN: CONTROL DE PARAMETROS
%-------------------------------------------------------------------------
if ~exist('yuvSequence','var') || isempty(yuvSequence)
  error('La sequencia yuv es un parámetro obligatorio');
end

if ~exist('framesToProcess','var') || isempty(framesToProcess)
  framesToProcess=[1];
end

if ~exist('bitDepth','var') || isempty(bitDepth)
  bitDepth=8; %Valor original.
end

if ~exist('Qp','var') || isempty(Qp)
  Qp=4; %Valor default.
end

if ~exist('ctuSize','var') || isempty(ctuSize)
  ctuSize=64; %Valor default.
end

if ~exist('nLevels','var') || isempty(nLevels)
  nLevels=0; %Valor default.
end

if ~exist('RunMode','var') || isempty(RunMode)
  RunMode='hevc'; %Valor original.
end

% Comprobamos si la variable RunMode tiene un valor definido
if ~any(strcmp({'hevc','phevc'},RunMode))
    error('El parámetro RunMode ''%s'' no coincide con ningún valor definido: ''hevc'' o ''phevc''',RunMode);
end

% El WeightMode define si se utiliza la perceptual weighting matrix Standard ('sta')
% o la que hemos definido como WorstConditions, la nuestra ('our')
if ~exist('WeightMode','var') || isempty(WeightMode)
    % Si no existe la variable supondremos sin cuantización perceptual
    WeightMode='noCSF';
elseif ~any(strcmp({'sta','our','no','staCSF','ourCSF','noCSF','CSF'},WeightMode))
    % Si no es un parámetro válido, tiramos error
    error('El parámetro WeightMode ''%s'' no coincide con ningún valor definido: ''noCSF'', ''staCSF'',''ourCSF'' o ''CSF''',WeightMode);
elseif any(strcmp({'sta','our','no'},WeightMode))
    % Escribimos el nombre de la variable correctamente
    % no -> noCSF, sta -> staCSF, our -> ourCSF
    WeightMode = strcat(WeightMode,'CSF');
end

% Si no se proporciona un valor asignamos uno por defecto
if ~exist('BestModeBy','var') || isempty(BestModeBy)
    if strcmp('hevc',RunMode)
        BestModeBy='RD'; % Valor por defecto: Obtención del mejor modo en base al R/D
    elseif strcmp('phevc',RunMode)
        BestModeBy='HAD'; % Valor por defecto: Obtención del mejor modo en base al Hadamard del HEVC 
    end
else
    % Si se proporciona un valor, verificamos que corresponda con uno válido
    if strcmp('hevc',RunMode) && ~any(strcmp({'RD' 'Coste'},BestModeBy))
        error('El parámetro BestModeBy ''%s'' para ''hevc'' no coincide con ningún valor definido: ''RD'' o ''Coste''',BestModeBy);
    elseif strcmp('phevc',RunMode) && ~any(strcmp({'HAD','SAD-Res','SAD-FQRes','SSIM1-Pre','SSIM2-Pre','SSIM3'},BestModeBy))
        error('El parámetro BestModeBy ''%s'' para ''phevc'' no coincide con ningún valor definido: ''HAD'', ''SAD-Res'', ''SAD-FQRes'', ''SSIM1-Pre'', ''SSIM2-Pre'' o ''SSIM3''',BestModeBy);
    end
end

%Comprobamos los parámetros loadHEVCModes y loadHEVCPartitions para colocar su valor por defecto si no se pasan.
if ~exist('HEVCPartitions','var') || isempty(HEVCPartitions)
    HEVCPartitions=false;
end

%-------------------------------------------------------------------------
% END: CONTROL DE PARAMETROS
%-------------------------------------------------------------------------

%Cerramos todas las figuras abiertas.
close all

if ~HEVCPartitions
    %Calculamos el PUSize en función del CtuSize y el numero de levels nLevels
    PUSize=ctuSize/2^(nLevels);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        Define las matrices HEVC de los distintos tamaños 4, 8, 16, 32
%        Basis Vectors of the HEVC Core Transforms -> M_Mat{}
%        Default Quantization Matrixes -> Q_Mat{}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Se incluye la definición de las tablas para la transformada
DefineHEVCTables

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%% Calculo de la distribución CSF usada para calcular el coste - 
% %%%% Aplica solo para modo phevc con nuestra CSF
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [fRad, csfMat, w, fMax]=GetDCTWeights(600,12.23,PUSize,6.54);
% [ csfDist ] = GetFreqDist( csfMat, 'upper');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        Read inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist(yuvSequence, 'file')
  % File does not exist.
  errorMessage = sprintf('Error: El fichero [%s] no exite.', yuvSequence);
  % Eliminamos todo rastro de msgbox para evitar que el programa se detenga
  %uiwait(msgbox(errorMessage,'Error','error'));
  error(errorMessage);
end


% Obtenemos el baseName de la secuencia Yuv
[pathstr,yuvSequenceBasename,ext] = fileparts(yuvSequence);

% Creamos (si no existen) los directorios donde se almacenarán los archivos
% resultantes.
% Directorio de salida
if ~exist(runDir,'dir')
    mkdir(runDir);
end
% Subdirectorio de secuencia
sequence_dir = strcat(runDir,'\',yuvSequenceBasename);
if ~exist(sequence_dir,'dir')
    mkdir(sequence_dir);
end
% Subdirectorio de modo
RunMode_dir = strcat(sequence_dir,'\',RunMode);
if ~exist(RunMode_dir,'dir')
    mkdir(RunMode_dir);
end


%Obtenemos los frames a procesar y generamos los Yuvs correspondientes a cada frame.
numFramesToProcess=numel(framesToProcess);
orig_imgs=cell(numFramesToProcess,1);

for f=1:numFramesToProcess
    frame=framesToProcess(f);
    
    % Cargamos en memoria los frames del YUV original
%     [ Y{f}, U{f}, V{f} ] = GetYuvFrame( yuvSequence, width, height, frame);
    [ Y, U, V ] = GetYuvFrame( yuvSequence, width, height, frame);
%     orig_imgs{f}=uint8(Y{f});
    orig_imgs{f}=uint8(Y);

    % Cada frame se guarda en un fichero donde se añade el numero de frame al nombre de la secuencia
    yuvFrame=sprintf('%s\\%s_%03d.yuv',sequence_dir,yuvSequenceBasename,frame);
    if ~exist(yuvFrame,'file')
%         SaveYuv(yuvFrame,'w',Y{f},U{f},V{f});
        SaveYuv(yuvFrame,'w',Y,U,V);
    end
%     [~,yuvFrameBasename,~] = fileparts(yuvFrame);

    % Guardamos el bmp original del frame
    outputImage=sprintf('%s\\%s_%03d.bmp',sequence_dir,yuvSequenceBasename,frame);
    if ~exist(outputImage,'file')
        imwrite(orig_imgs{f},outputImage);
    end
end

if ~HEVCPartitions
    %Todos los PUs tienen el mismo tañmaño.
    %Obtenemos los indices de las tablas de cuantización.
    [M_MatIndex, Quant_MatIndex, Weights_MatIndex] = GetTables(PUSize);

    %Obtenemos la Matriz de Vectores Base a usar
    M_Matrix=M_Mat{M_MatIndex};

    %Obtenemos la Matriz de Quantización a usar
    Q_Matrix=Quant_Mat{Quant_MatIndex};
    IQ_Matrix=IQuant_Mat{Quant_MatIndex};

else
    %Cada particion es un PU de distinto tamaño
    %Cargamos las tablas para todos los tamaños.
    %[M_MatIndex, Quant_MatIndex, Weights_MatIndex] = GetTables(0); %Todos los indices
    
    %Obtenemos las Matrices de Vectores Base y de cuantización a usar
    for ix=1:4
        M_Matrixs{ix}=M_Mat{ix};
        Q_Matrixs{ix}=Quant_Mat{ix};
        IQ_Matrixs{ix}=IQuant_Mat{ix};
    end
end

if ( strcmp(WeightMode,'staCSF') || strcmp(WeightMode,'ourCSF') || strcmp(WeightMode,'CSF') )
    if ~HEVCPartitions
        W_Matrix=Weights_Mat{Weights_MatIndex};
        IW_Matrix=IWeights_Mat{Weights_MatIndex};
    else
        %Obtenemos las Matrices de pesos 
        for ix=1:4
            W_Matrixs{ix}=Weights_Mat{ix};
            IW_Matrixs{ix}=IWeights_Mat{ix};
        end
    end
end

%PROCESO COMPLETO FRAME A FRAME
for f=1:numFramesToProcess
    frame=framesToProcess(f);
    
    if ~HEVCPartitions
        label_ = sprintf('Processing Frame=%03d Sequence=%s Mode=%s CTU=%02d Levels=%1d Qp=%02d BestModeBy=%s WeightMode=%s',frame,yuvSequenceBasename,RunMode,ctuSize,nLevels,Qp,BestModeBy,WeightMode);
    else
        label_ = sprintf('Processing Frame=%03d Sequence=%s Mode=%s HEVCPartition Qp=%02d BestModeBy=%s WeightMode=%s',frame,yuvSequenceBasename,RunMode,Qp,BestModeBy,WeightMode);
    end
    fprintf('  %s\n',label_);
    
    orig_img=orig_imgs{f}; % Used in doFrameFixedPartitions
    
    % Procesamos el frame con Particiones fijas o con Particiones variables (HEVC Partitions)
    if ~HEVCPartitions
        try
            doFrameFixedPartitions
        catch ME
            ShowError( ME );
            error('HEVC_Main: %s\n',ME.message);
        end
    else
        try
            
            doFrameHEVCPartitions
        catch ME
            ShowError( ME );
            error('HEVC_Main: %s\n',ME.message);
        end
    end
    
    % Guardamos la imagen reconstruida
    %-----------------------------------------------------
    if (~silentMode)
        fprintf('Frame %03d Grabando imagen reconstruida ...\n',frame);
    end
    %outputImage =>  <originalName>_<bitDepth>_<PUSize>_<Qp>.bmp

    %Guardamos el yuv reconstruido
    if ~HEVCPartitions
        yuvOutput=sprintf('%s\\%s_%s_%03d_bd%02d_ctu%02d_l%1d_qp%02d_%s_bm%s%s',RunMode_dir,RunMode,yuvSequenceBasename,frame,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy,'.yuv');
    else
        yuvOutput=sprintf('%s\\%s_%s_%03d_bd%02d_qp%02d_%s_bm%s%s',RunMode_dir,RunMode,yuvSequenceBasename,frame,bitDepth,Qp,WeightMode,BestModeBy,'.yuv');
    end
    [rY,rU,rV]=Y2YUV(uint8(RecImage));
    SaveYuv(yuvOutput,'w',rY,rU,rV);

    %Guardamos el bmp reconstruido
    if ~HEVCPartitions
        outputImage=sprintf('%s\\%s_%s_%03d_bd%02d_ctu%02d_l%1d_qp%02d_%s_bm%s%s',RunMode_dir,RunMode,yuvSequenceBasename,frame,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy,'.bmp');
    else
        outputImage=sprintf('%s\\%s_%s_%03d_bd%02d_qp%02d_%s_bm%s%s',RunMode_dir,RunMode,yuvSequenceBasename,frame,bitDepth,Qp,WeightMode,BestModeBy,'.bmp');
    end
    imwrite(uint8(RecImage),outputImage);

    %Mostramos la imagen
    if (~silentMode)
        imshow(uint8(RecImage));
    end
    
    %-----------------------------------------------------
    %  GUARDANDO DATOS EN FICHEROS .mat
    %-----------------------------------------------------

    % Guardamos los cell arrays y otros asociados a la ejecución
    % cellFileName =>  <originalName>_<cellArray>_<bitDepth>_<PUSize>_<Qp>.mat
    %-----------------------------------------------------
    if (~silentMode)
        fprintf('Frame %03d Guardando datos en .mats ...\n',frame);
    end
	
    %-----------------------------------------------------
    % Generando .mat
    %-----------------------------------------------------
    
    if guardar_mat == true && ~HEVCPartitions
        % CPU   Cell array con todos los PUs
        SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CPU',CPU,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
        % CPreM   Cell array con todas las Predicciones para cada PU y Modo Intra
        SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CPreM',CPreM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
        % CREC  Cell array con la reconstrucción de cada PU
        SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CREC',CREC,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
    end
    if (strcmp(RunMode,'hevc')) %HEVC
        if guardar_mat == true && ~HEVCPartitions
            % CResM  Cell array con todos los residuos por modo
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CResM',CResM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % Mod    array con el mejor Modo Intra para cada PU 
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'Mod',Mod,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % CRes Cell array con el Residuo para cada PU del mejor Modo Intra
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CRes',CRes,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % SADSM array con los SADS para cada Modo 
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'SADSM',SADSM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % SADS array con los SADS para el modo seleccionado 
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'SADS',SADS,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % BitsM Array con los bits para cada bloque transformado y cuantizado para cada modo
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'BitsM',BitsM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % RDM Array con el R/D (entropy/SAD) para cada bloque transformado y cuantizado para cada modo
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'RDM',RDM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % RD Array con el R/D (entropy/SAD) para cada bloque transformado y cuantizado para el mejor modo
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'RD',RD,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % Bits Array con los bits para cada bloque transformado y cuantizado para el mejor modo
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'Bits',Bits,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % CPre   Cell array con los valores transformados y cuantizados para cada PU
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CPre',CPre,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % CIQ   Cell array con los valores transformados y cuantizados para cada PU
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CIQ',CIQ,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
        end
        if guardar_mat == true && HEVCPartitions
            % framePreImage   Array con los valores de predicción para todo el frame
			SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'framePreImage',framePreImage,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % frameResImage   Array con los valores residuales para todo el frame
			SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'frameResImage',frameResImage,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % frameCQImage   Array con los valores transformados y cuantizados para todo el frame
			SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'frameCIQImage',frameCIQImage,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % frameRecImage   Array con los valores reconstruidos para todo el frame
			SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'frameRecImage',frameRecImage,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
        end
        if ~HEVCPartitions
            % CQ   Cell array con los valores transformados y cuantizados para cada PU
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CQ',CQ,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
        end
		if HEVCPartitions
            % frameCQImage   Array con los valores transformados y cuantizados para todo el frame
			SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'frameCQImage',frameCQImage,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
			% Guardamos las FrameParts puesto que han sido modificadas en la ejecución.
            SaveFrameParts(runDir,frameParts,hevcCTUSPerFrame,RunMode,yuvSequenceBasename,width,height,frame,bitDepth,Qp,WeightMode,BestModeBy);
		end
    else %PHEVC
        if guardar_mat == true
            % CFResM    Cell array con todos los residuos en frecuencia
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CFResM',CFResM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % CFQResM   Cell array con todos los residuos en frecuencia cuantizados por modo
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CFQResM',CFQResM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % FMod    array con el mejor Modo Intra para cada PU 
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'FMod',FMod,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % CFRes array con el Residuo en frecuencia 
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CFRes',CFRes,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % PCostesM array con los Costes para cada Modo Intra para cada PU
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'PCostesM',PCostesM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % PCostes array con los Costes para el modo seleccionado
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'PCostes',PCostes,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % PBitsM array con los bits de los residuos cuantizados perceptualmente para cada modo
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'PBitsM',PBitsM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % PRDM array con el R/D (entropia/Coste) de los residuos cuantizados perceptualmente para cada modo
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'PRDM',PRDM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % PRD array con el R/D (entropia/Coste) de los residuos cuantizados perceptualmente para el modo seleccionado
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'PRD',PRD,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % CSSimRecM array con los valores de SSIM para cada modo
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CSSimRecM',CSSimRecM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % CSSimMapRecM array con los valores de mapa SSIM para cada modo
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CSSimMapRecM',CSSimMapRecM,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % CSSimRec array con los valores de SSIM para el mejor modo
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CSSimRec',CSSimRec,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
            % CSSimMapRec array con los valores de mapa SSIM para el mejor modo
            SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CSSimMapRec',CSSimMapRec,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
        end
        % PBits array con los bits de los residuos cuantizados perceptualmente para el modo seleccionado
        SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'PBits',PBits,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
        % CFQRes array con los residuos en frecuencia cuantizados correspondientes al modo seleccionado
        SaveMat(runDir,RunMode, yuvSequenceBasename, frame,'CFQRes',CFQRes,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
    end
    
end %Proceso frame a frame

frameParts={};

end %HEVC_Main


function SaveFigurePDF(fig,runDir,RunMode, yuvSequenceBasename, frame, fig_name, bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
    filePath=sprintf('%s\\%s\\%s',runDir,yuvSequenceBasename,RunMode);
    cellFileName=sprintf('%s_%s_%03d_%s_bd%02d_ctu%02d_l%1d_qp%02d_%s_bm%s',RunMode,yuvSequenceBasename,frame,fig_name,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy);
    orient(fig,'landscape');
    print(fig,[filePath '\\' cellFileName],'-dpdf','-fillpage');
    close(fig);
end