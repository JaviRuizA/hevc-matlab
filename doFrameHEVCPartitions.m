%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% doFrameHEVCPartitions: PROCESA UN FRAME CUANDO LAS PARTICIONES
%                        SON LAS DEL HEVC (DE DISTINTO TAMAÑO)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%Ficheros de salida.
%Guardamos el .yuv y el .bmp con estos nombres.
yuvOutput=sprintf('%s\\%s_%s_%03d_bd%02d_qp%02d_%s_bm%s%s',RunMode_dir,RunMode,yuvSequenceBasename,frame,bitDepth,Qp,WeightMode,BestModeBy,'.yuv');
outputImage=sprintf('%s\\%s_%s_%03d_bd%02d_qp%02d_%s_bm%s%s',RunMode_dir,RunMode,yuvSequenceBasename,frame,bitDepth,Qp,WeightMode,BestModeBy,'.bmp');
% 
%Cargamos el archivo .dat
hevcFramePartitionsFile=sprintf('%s\\%s\\%s\\%s_%03d_qp%d_%s.Part.dat',runDir,yuvSequenceBasename,RunMode,yuvSequenceBasename,frame,Qp,WeightMode);
% %%%%% ELIMINAR DESDE AQUÍ %%%%%
% hevcFramePartitionsFile=sprintf('%s\\%s\\%s\\%s_%03d_qp%d_%s_%sMask.Part.dat',runDir,yuvSequenceBasename,RunMode,yuvSequenceBasename,frame,Qp,WeightMode,'no');
% % ESTO LO HE HECHO PARA QUE SIEMPRE COJA EL PARTICIONADO DEL HM CUANDO LE
% % DECIMOS QUE NO HAGA TEXTURE MASKING, YA QUE ASÍ PUEDO COMPARAR EL
% % FUNCIONAMIENTO DE TEXTURE MASKING CON TONG Y CON COLÍNEAS
% %%%%% ELIMINAR HASTA AQUÍ %%%%%

%Si todos ya están generdos omitimos la ejecución
%if ~exist(yuvOutput,'file') || ~exist(outputImage,'file') || ~exist(framePartsFile,'file')
if ~exist(yuvOutput,'file') || ~exist(outputImage,'file')

    numModos=size(Indexes.ixsAngular,2)+2;
    
    frameParts = LoadPartitionFile(hevcFramePartitionsFile,width,height,ctuSize);
    
    ctuRows = size(frameParts,1);
    ctuCols = size(frameParts,2);
    hevcCTUSPerFrame = ctuRows * ctuCols;
    
    %Inicializamos el mapa de referencias a false;
    %Añadimos una columna a la izquierda y una fila por encima para las referencias fuera de frame
    frameRefsMap=false(height+1,width+1);
    % Inicializamos la imagen predecida a NaNs
    framePreImage=nan(height,width);
    % Inicializamos la imagen residual a NaNs
    frameResImage=nan(height,width);
    % Inicializamos la imagen cuantizada a NaNs
    frameCQImage=nan(height,width);
    % Inicializamos la imagen cuantizada inversa a NaNs
    frameCIQImage=nan(height,width);
    %Inicializamos la imagen de reconstruidos a NaNs
    frameRecImage=nan(height,width);
    
    %Procesamos CTU a CTU en raster order
    for ctuRow=1:ctuRows
        for ctuCol=1:ctuCols
            ctuParts=frameParts{ctuRow,ctuCol};
            %Procesamos las Parts del ctu
            %origCTU = double(orig_img(1 + ctuSize * (ctuRow - 1): ctuSize * (ctuRow), 1 + ctuSize * (ctuCol - 1): ctuSize * ctuCol)); % Imagen original correspondiente al CTU
            for cuID=1:size(ctuParts,1)
                TU = ctuParts(cuID,:);
                tuSize = TU(Indexes.ixTUsize); % Tamaño del bloque
                tuRow = TU(Indexes.ixRow); % Índice inicial de la fila del TU para todo el frame
                tuCol = TU(Indexes.ixCol); % Índice inicial de la columna del TU para todo el frame
                tuMode = TU(Indexes.ixMode); % Modo Intra
                
                origPU = double(orig_img(tuRow:tuRow + tuSize - 1, tuCol:tuCol + tuSize - 1)); % Imagen original correspondiente al TU

                %Obtenemos las muestras de referencia para calcular la predicción Intra de los bloques.
                %Tanto las muestras sin filtrar como las filtradas.
                % T=Top  L=Left  R=Referencias  'f' indica filtradas
                [T, L, R]=GetPartReferenceSamples(TU,frameRefsMap,frameRecImage,bitDepth);
                [Tf, Lf, Rf]=IntraFilteringReferenceSamples(T,L,R,bitDepth);

                %Añadimos a la parte las predicción correspondiente al modo HEVC

                switch tuMode
                    case Indexes.ixPlanarPre %Planar Prediction
                        [tuPRE]=GenPlanarPrediction(T,L,Tf,Lf);
                    case Indexes.ixDCPre     %DC Prediction
                        [tuPRE]=GenDCPrediction(T,L); % Al modo DC no se aplica filtro nunca por eso solo recibe sin filtrar
                    otherwise
                        %Angular HEVC Prediction
                        [tuPRE]=GenAngularPredictions(R,Rf,tuMode);
                end
                % Almacenamos la predicción
                framePreImage(tuRow:tuRow + tuSize - 1, tuCol:tuCol + tuSize - 1) = tuPRE;
                
                %Continuamos la ejecución en función del modo
                if (strcmp(RunMode,'hevc'))
                    try
                        % HEVC SELECTION MODE
                        doPartHEVCMode
                    catch ME
                        fprintf('doFrameHEVCPartitions: %s\n',ME.message);
                        error('doFrameHEVCPartitions: %s\n',ME.message);
                    end
                else
                    try
                        % PHEVC SELECTION MODE
                        doPartPHEVCMode
                    catch ME
                        fprintf('doFrameHEVCPartitions: %s\n',ME.message);
                        error('doFrameHEVCPartitions: %s\n',ME.message);
                    end

                end
            end
        end
    end
        
    % Reconstruyendo los PUs
    
    if (~silentMode)
        fprintf('\n');
        fprintf('Frame %03d Regenerando imagen a partir de los PUs reconstruidos ...\n',frame);
    end
    
    if HEVCPartitions % Particiones HEVC
        [RecImage]=frameRecImage;
    else
        %Obtenemos la imagen reconstruida
        % Creo que aquí nunca entrará, ya que si ~HEVCPartitios usará la función doFrameFixedPartitions.m
        [RecImage]=GetRecImage(CREC);
    end
end