% Ejecutamos para las common conditions Qps 22 27 32 37
% Para las secuencias definidas en el cell
% Para los modos hevc y phvc
% Para todos lo PUSizes 32,16,8,4
%   RunCommonConditions.m
%       Inicializa los parámetros para el procesamiento
%       Llama a HEVC_Main.m
%           Genera los distorsionados a distintas tasas y PUsizes
%       Llama a GenSequenceSetMetrics.m
%           Genera el Rate y los datos de calidad VQMT, VIF y VMAF
%       Llama a genGraph.m
%           Representa gráficamente los datos obtenidos

close all force;

if isdeployed()
    cd(getPWD());
end

%---Nombre del fichero de configuración
    ini_file = [ getPWD() '\config.ini'];
    initial_config = ini2struct(ini_file);

%---Parámetros para definir el ámbito del procesamiento
    % Secuencias
        sequences = eval(initial_config.sequences);
    % Dimensiones de cada secuencia (mismo orden) [width,height]
        dims = eval(initial_config.dims);
    % Fotogramas por segundo de cada secuencia (mismo orden) [width,height]
    %  en caso de ser una imagen estática, ponded un valor 25
        FrameRates = eval(initial_config.framerates);
    % Número de frame que se procesa en cada secuencia (mismo orden).
        Frames = eval(initial_config.frames);
    % CTUSizes y NLevels, a partir de los cuales se calcula el tamaño fijo de los PUs
        CTUSizes = eval(initial_config.ctusizes);
        NLevels = eval(initial_config.nlevels);
    % Modo particionado QuadTree
        loadHEVCPartitions = eval(initial_config.loadhevcpartitions);
    % QPs
        Qps = eval(initial_config.qps);
    % Modos, pude ser 'hevc' para el estándar original y 'phevc' para la versión perceptual (en desarrollo)
        Modes = eval(initial_config.modes);
    % WeightMode 
        WeightModes = eval(initial_config.weightmodes);
    % Método para la obtención del mejor modo en HEVC
        BestModesHEVC = eval(initial_config.bestmodeshevc);
    % Método para la obtención del mejor modo en PHEVC
        BestModesPHEVC = eval(initial_config.bestmodesphevc);
    % Directorio de salida donde se almacenarán los cálulos obtenidos
        output_dir = eval(initial_config.output_dir);
    % Métrica de gráfica
        Metric = eval(initial_config.metric);
    % Rate de gráfica
        RateMode = eval(initial_config.ratemode);
    % Modo vídeo
        videomode = eval(initial_config.videomode);
    % Computación paralela
        parallelMode = eval(initial_config.parallelmode);
    % Guardar gráficas en PDF
        print_to_pdf = eval(initial_config.print_to_pdf);
    % Guarda los ficheros binarios generados por TAppEncoder.exe
        global save_HM_binary;
        save_HM_binary = eval(initial_config.save_hm_binary);
    % Guarda los frames de salida generados por TAppEncoder.exe
        global save_HM_output;
        save_HM_output = eval(initial_config.save_hm_output);

%---Parámetros fijos
    bitdepth=8;
    global HM_UMH_TAppEncoder;
    if is64bitComputer()
        HM_UMH_TAppEncoder = [ getPWD() '\tools\TAppEncoder_x64.exe'];
    else
        HM_UMH_TAppEncoder = [ getPWD() '\tools\TAppEncoder_x32.exe'];
    end
    global encoder_intra_main;
    encoder_intra_main = [ getPWD() '\encoder_intra_main.cfg'];

%------------------------------------------------------

if isdeployed() % Stand-alone mode.
    % Comprobamos si se ha extraído el contenido de tools.zip
    if ~exist([getPWD() '\tools'], 'dir')
        tools_zip = [getPWD() '\tools.zip'];
        if ~exist( tools_zip, 'file') == 2
            error('File tools.zip not found in %s\n', getPWD());
        else
            unzip( tools_zip, getPWD() );
        end
    end
end

if parallelMode == true
    parallelWorkers = Inf;
else
    parallelWorkers = 0;
end

if loadHEVCPartitions == true
    % No se tiene en cuenta, asignamos valor -1
    CTUSizes = -1;
    NLevels = -1;
end

% Creación de la barra de progreso
sum_modos = 0;
if any(strcmp(Modes,'hevc'))
    sum_modos = sum_modos + size(BestModesHEVC,2);
end
if any(strcmp(Modes,'phevc'))
    sum_modos = sum_modos + size(BestModesPHEVC,2);
end

% Abrimos el archivo de métricas si existe
MetricsPath=sprintf('%s\\%s.csv',output_dir,'Metrics');
METRICS = {};
Info = struct;

if exist(MetricsPath,'file') == 2
    [METRICS, Info] = csv2cell(MetricsPath, 'fromfile');
    % Limpiamos las posibles filas vacías ';;;;;;;;;;'
    METRICS = METRICS(~cellfun(@isempty,METRICS(:,1)),:);
    % Eliminamos las posibles filas duplicadas (si es lanzamiento HM puro)
    if isfield(Info,'SBH')
        METRICS = RemoveDuplicateRowsMetrics(METRICS, Info.FRAME, Info.SBH);
    end
    % Ordenamos el CSV para un correcto procesado
    METRICS = sortrows(METRICS,[Info.MODE,Info.SEQUENCE,Info.FRAME,-Info.PUSIZE,-Info.QP,-Info.CSF]);
end

% Matriz donde se guardan las ejecuciones que van a lanzarse
ejecuciones = {};

% Obtenemos cada una de las ejecuciones programadas, descartando las ya
% existentes
if ~loadHEVCPartitions
    for i=1:size(sequences,2)
        sequenceName=sequences{i};
        width=dims{i}(1); 
        height=dims{i}(2);
        frames=Frames{i};
        for m=1:size(Modes,2)
            mode=Modes{m};
            if (strcmp(mode,'hevc'))
                BestModes = BestModesHEVC;
            else
                BestModes = BestModesPHEVC;
            end
            for p=1:size(CTUSizes,2)
                ctusize=CTUSizes(p);
                nlevels=NLevels(p);
                for q=1:size(Qps,2)
                    qp=Qps(q);
                    for bm=1:size(BestModes,2)
                        bestmodeby = BestModes{bm};
                        for wm=1:size(WeightModes,2)
                            weightmode = WeightModes{wm};

                            % Si es HEVC, CTU=16, NLevel=2 (PU = 4) y staCSF, nos lo saltamos
                            % ya que en el estandar no aplica
                            if strcmp(mode,'hevc') && ctusize == 16 && nlevels == 2 && strcmp(weightmode,'staCSF')
                                continue;
                            end

                            % Obtenemos los frames de la configuración actual que no se han procesado.
                            remaining_frames = check_if_processed(METRICS,Info,sequenceName,frames,bitdepth,mode,ctusize,nlevels,qp,weightmode,bestmodeby,output_dir);
                            if size(remaining_frames) == 0
                                continue;
                            end

                            % Añadimos la configuración a la lista de ejecuciones
                            ejecuciones(end+1,:) = {sequenceName,remaining_frames,width,height,bitdepth,mode,qp,ctusize,nlevels,weightmode,bestmodeby};

                        end % WeightModes
                    end % BestModes
                end % QPs
            end % CTUSizes
        end % Modes
    end % Sequences
else
    for i=1:size(sequences,2)
        sequenceName=sequences{i};
        width=dims{i}(1); 
        height=dims{i}(2);
        frames=Frames{i};
        for m=1:size(Modes,2)
            mode=Modes{m};
            if (strcmp(mode,'hevc'))
                BestModes = BestModesHEVC;
            else
                BestModes = BestModesPHEVC;
            end
            for q=1:size(Qps,2)
                qp=Qps(q);
                for bm=1:size(BestModes,2)
                    bestmodeby = BestModes{bm};
                    for wm=1:size(WeightModes,2)
                        weightmode = WeightModes{wm};
                        % Obtenemos los frames de la configuración actual que no se han procesado.
                        remaining_frames = check_if_partition_processed(METRICS,Info,sequenceName,frames,bitdepth,mode,qp,weightmode,bestmodeby,output_dir);
                        if size(remaining_frames) == 0
                            continue;
                        end

                        % Añadimos la configuración a la lista de ejecuciones
                        ejecuciones(end+1,:) = {sequenceName,remaining_frames,width,height,bitdepth,mode,qp,'','',weightmode,bestmodeby};
                    end % WeightModes
                end % BestModes
            end % QPs
        end % Modes
    end % Sequences
    % Comprobamos o generamos los archivos de particionado .dat
    steps = size(ejecuciones,1);
    if steps > 0
        f_waitbar = parfor_progressbar(steps,'Obteniendo particionado de HM, tenga paciencia...');
        for i=1:size(ejecuciones,1)
            GenerateHEVCPartitionsFiles(ejecuciones(i,:), output_dir);
            f_waitbar.iterate(1);
        end
        close(f_waitbar)
    end
end


% Creamos la barra de progreso
steps = size(ejecuciones,1);

if steps > 0
    f_waitbar = parfor_progressbar(steps,'Procesando configuración, tenga paciencia...');
    
    % Si la aplicación es compilada, se debe inicializar el clúster paralelo
    if isdeployed() && parallelMode == true
        myCluster = parcluster();
    end
    
    % Bucle de ejecuciones
    for i = 1:steps
    %parfor ( i = 1:steps, parallelWorkers )
        sequenceName = ejecuciones{i,1};
        remaining_frames = ejecuciones{i,2};
        width = ejecuciones{i,3};
        height = ejecuciones{i,4};
%         bitdepth = ejecuciones{i,5};
        mode = ejecuciones{i,6};
        qp = ejecuciones{i,7};
        ctusize = ejecuciones{i,8};
        nlevels = ejecuciones{i,9};
        weightmode = ejecuciones{i,10};
        bestmodeby = ejecuciones{i,11};
        try
            HEVC_Main(sequenceName,remaining_frames,width,height,bitdepth,qp,ctusize,nlevels,mode,weightmode,bestmodeby,output_dir,loadHEVCPartitions);
        catch ME
            ShowError( ME );
            error('RunCommonConditionsFromINI: %s\n',ME.message);
        end
        f_waitbar.iterate(1);
    end
    
    % Si la aplicación es compilada y se ha paralelizado, eliminamos el clúster paralelo
    if isdeployed() && parallelMode == true
        delete(gcp('nocreate'));
    end
    
    close(f_waitbar)
end

% Una vez se han ejecutado las codificaciones se lanza el script que
% obtiene las métricas
[METRICS, Info] = GenSequenceSetMetrics(sequences,dims,FrameRates,Frames,Modes,CTUSizes,NLevels,Qps,WeightModes,[BestModesHEVC BestModesPHEVC],output_dir,MetricsPath,parallelWorkers);

% Finalmente, con las métricas generadas se lanza el script que genera las
% gráficas así como el CSV de las mismas.
for met_id = 1:size(Metric,2)
    this_metric = Metric{met_id};
    genGraph(METRICS,Info,MetricsPath,this_metric,sequences,Frames,Modes,CTUSizes,NLevels,WeightModes,[BestModesHEVC BestModesPHEVC],RateMode,videomode,print_to_pdf)
end

function [ remaining_frames ] = check_if_processed(METRICS, Info, sequence,frames,bitdepth,mode,ctusize,nlevels,qp,weightmode,bestmodeby,output_dir)
% Función que comprueba si ya se ha codificado la configuración dada, para así omitirla.
% Devuelve el número de frames pendientes de codificar.
remaining_frames = [];

[~,sequenceBaseName,~] = fileparts(sequence);
% Comprobamos primero si tenemos alguna métrica de lo que pedimos (a
% excepción de los frames)

if ~isempty(METRICS)
    idx_seq = find(strcmp(METRICS(:, Info.SEQUENCE), sequenceBaseName));
    if ~isempty(idx_seq)
        METRICS = METRICS(idx_seq,:);
        idx_mode = find(strcmp(METRICS(:, Info.MODE), mode));
        if ~isempty(idx_mode)
            METRICS = METRICS(idx_mode,:);
            idx_ctu = find([METRICS{:, Info.CTUSIZE}] == ctusize)';
            if ~isempty(idx_ctu)
                METRICS = METRICS(idx_ctu,:);
                idx_nlevels = find([METRICS{:, Info.NLEVELS}] == nlevels)';
                if ~isempty(idx_nlevels)
                    METRICS = METRICS(idx_nlevels,:);
                    idx_qp = find([METRICS{:, Info.QP}] == qp)';
                    if ~isempty(idx_qp)
                        METRICS = METRICS(idx_qp,:);
                        idx_csf = find(strcmp(METRICS(:, Info.CSF), weightmode));
                        if ~isempty(idx_csf)
                            METRICS = METRICS(idx_csf,:);
                            idx_bm = find(strcmp(METRICS(:, Info.BESTMODEBY), bestmodeby));
                            if ~isempty(idx_bm)
                                METRICS = METRICS(idx_bm,:);
                                % Y ahora los frames
                                remaining_frames_csv = frames(~ismember(frames, cell2mat(METRICS(:,Info.FRAME))));
                                if isempty(remaining_frames_csv)
                                    % Tiene todas las métricas en el CSV
                                    return
                                else
                                    frames = remaining_frames_csv;
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

% Comprobamos si tiene los archivos .MAT guardados
num_frames = numel(frames);
for i=1:num_frames
    frame = frames(i);
    
    % Comprobamos si tenemos el .mat CQ o CFQRes según corresponda
    if strcmp('hevc',mode)
        pattern=sprintf('%s\\%s\\%s\\%s_%s_%03d_CQ_*ctu%02d_l%1d_qp%02d_%s_bm%s.mat',output_dir,sequenceBaseName,mode,mode,sequenceBaseName,frame,ctusize,nlevels,qp,weightmode,bestmodeby);
    else
        pattern=sprintf('%s\\%s\\%s\\%s_%s_%03d_CFQRes_*ctu%02d_l%1d_qp%02d_%s_bm%s.mat',output_dir,sequenceBaseName,mode,mode,sequenceBaseName,frame,ctusize,nlevels,qp,weightmode,bestmodeby);
    end

    if size(dir(pattern),1)~=1
        remaining_frames = [remaining_frames frame];
        continue
    end

    % Comprobamos si tenemos el archivo original y el regenerado
    original_sequence_path = sprintf('%s\\%s\\%s_%03d.yuv',output_dir,sequenceBaseName,sequenceBaseName,frame);
    regenerate_sequence_path = sprintf('%s\\%s\\%s\\%s_%s_%03d_bd%02d_ctu%02d_l%1d_qp%02d_%s_%sMask_bm%s.yuv',output_dir,sequenceBaseName,mode,mode,sequenceBaseName,frame,bitdepth,ctusize,nlevels,qp,weightmode,bestmodeby);

    if exist(original_sequence_path,'file') ~= 2
        remaining_frames = [remaining_frames frame];
        continue
    elseif exist(regenerate_sequence_path,'file') ~= 2
        remaining_frames = [remaining_frames frame];
        continue
    end
end
end

function [ remaining_frames ] = check_if_partition_processed(METRICS, Info, sequence,frames,bitdepth,mode,qp,weightmode,bestmodeby,output_dir)
% Función que comprueba si ya se ha codificado la configuración dada, para así omitirla.
% Devuelve el número de frames pendientes de codificar.
remaining_frames = [];

ctusize = -1;
nlevels = -1;

[~,sequenceBaseName,~] = fileparts(sequence);
% Comprobamos primero si tenemos alguna métrica de lo que pedimos (a
% excepción de los frames)

if ~isempty(METRICS)
    idx_seq = find(strcmp(METRICS(:, Info.SEQUENCE), sequenceBaseName));
    if ~isempty(idx_seq)
        METRICS = METRICS(idx_seq,:);
        idx_mode = find(strcmp(METRICS(:, Info.MODE), mode));
        if ~isempty(idx_mode)
            METRICS = METRICS(idx_mode,:);
            idx_ctu = find([METRICS{:, Info.CTUSIZE}] == ctusize)';
            if ~isempty(idx_ctu)
                METRICS = METRICS(idx_ctu,:);
                idx_nlevels = find([METRICS{:, Info.NLEVELS}] == nlevels)';
                if ~isempty(idx_nlevels)
                    METRICS = METRICS(idx_nlevels,:);
                    idx_qp = find([METRICS{:, Info.QP}] == qp)';
                    if ~isempty(idx_qp)
                        METRICS = METRICS(idx_qp,:);
                        idx_csf = find(strcmp(METRICS(:, Info.CSF), weightmode));
                        if ~isempty(idx_csf)
                            METRICS = METRICS(idx_csf,:);
                            idx_bm = find(strcmp(METRICS(:, Info.BESTMODEBY), bestmodeby));
                            if ~isempty(idx_bm)
                                METRICS = METRICS(idx_bm,:);
                                % Y ahora los frames
                                remaining_frames_csv = frames(~ismember(frames, cell2mat(METRICS(:,Info.FRAME))));
                                if isempty(remaining_frames_csv)
                                    % Tiene todas las métricas en el CSV
                                    return
                                else
                                    frames = remaining_frames_csv;
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

% Comprobamos si tiene los archivos .MAT guardados
num_frames = numel(frames);
for i=1:num_frames
    frame = frames(i);
    
    % Comprobamos si tenemos el .mat frameParts según corresponda
    if strcmp('hevc',mode)
        pattern=sprintf('%s\\%s\\%s\\%s_%s_%03d_frameParts_*qp%02d_%s_bm%s.mat',output_dir,sequenceBaseName,mode,mode,sequenceBaseName,frame,qp,weightmode,bestmodeby);
    else
        % Por ahora no se ha modificado, petará el día que se retome PHEVC
        pattern=sprintf('%s\\%s\\%s\\%s_%s_%03d_CFQRes_*qp%02d_%s_bm%s.mat',output_dir,sequenceBaseName,mode,mode,sequenceBaseName,frame,qp,weightmode,bestmodeby);
    end

    if size(dir(pattern),1)~=1
        remaining_frames = [remaining_frames frame];
        continue
    end

    % Comprobamos si tenemos el archivo original y el regenerado
    original_sequence_path = sprintf('%s\\%s\\%s_%03d.yuv',output_dir,sequenceBaseName,sequenceBaseName,frame);
    regenerate_sequence_path = sprintf('%s\\%s\\%s\\%s_%s_%03d_bd%02d_qp%02d_%s_bm%s.yuv',output_dir,sequenceBaseName,mode,mode,sequenceBaseName,frame,bitdepth,qp,weightmode,bestmodeby);

    if exist(original_sequence_path,'file') ~= 2
        remaining_frames = [remaining_frames frame];
        continue
    elseif exist(regenerate_sequence_path,'file') ~= 2
        remaining_frames = [remaining_frames frame];
        continue
    end
end
end
