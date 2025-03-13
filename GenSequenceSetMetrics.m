function [METRICS, Info] = GenSequenceSetMetrics(SequenceSet,SequenceSizes,FrameRates,FramesSet,Modes,CTUSizes,NLevels,Qps,CSFWeightMode,BestModeBy,output_dir,MetricsPath,parallelWorkers)
%Genera un fichero .mat con todas las métricas para los parámetros pedidos. 
%Para calcular el rate utiliza GetImageRate.m
%Para calcular las métricas VQMT utiliza GetVQMTResults.m
%Si no encuentra algún archivo que encaje con los parámetros dados lo omite.
%
%Parametros:
%  SequenceSet  : Un cell array con el nombre de las secuencias a procesar.
%  SequenceSizes: Un cell array con las dimensiones [width, height] de las
%                   secuencias a procesar. En el mismo orden.
%  FrameRates   : Un cell array con las tasas de velocidad de frame de las
%                   secuencias a procesar. En el mismo orden.
%  FramesSet    : Un cell array con el número de frames en formato array a
%                   procesar por cada secuencia. En el mismo orden.
%  Modes        : Un cell array con el nombre de los modos a procesar. Al menos debe indicarse uno
%                   de {'hevc' 'phevc'}
%  CTUSizes     : Un array con los tamaños de CTU a procesar.
%  NLevels      : Un array con el nivel de descomposicion para cada uno de los CTUSizes del
%                 parametro anterior. En el mismo orden.
%  Qps          : Un array con el valor de las distintas Qps a procesar
%  CSFWeightMode: String que indica el tipo de CSF aplicada. {'noCSF' 'staCSF' 'ourCSF' 'CSF'}
%  BestModeBy   : Un cell array con el método para elegir el mejor modo.
%                   para el Mode 'hevc' : {'Coste' 'RD'}
%                   para el Mode 'phevc': {'HAD' 'SAD-Res' 'SAD-FQRes' 'SSIM1-Pre' 'SSIM2-Pre' 'SSIM3'}
%  MetricsPath  : Ruta absoluta del archivo de métricas .CSV
%  pWorkers     : Número de workers o hilos paralelos de ejecución.

% Obtenemos las métricas ya guardadas, para evitar volver a procesarlas
METRICS = {};
Info = struct;
bitDepth=8;

new_metrics = false;

if exist(MetricsPath,'file') == 2
    [METRICS, Info] = csv2cell(MetricsPath, 'fromfile');
    
    CSV_loaded_size = size(METRICS,1);
    
    % Limpiamos las posibles filas vacías ';;;;;;;;;;'
    METRICS = METRICS(~cellfun(@isempty,METRICS(:,1)),:);
    
    % Eliminamos las posibles filas duplicadas (si es lanzamiento HM puro)
    if isfield(Info,'SBH')
        METRICS = RemoveDuplicateRowsMetrics(METRICS, Info.FRAME, Info.SBH);
    end
    
    CSV_cleaned_size = size(METRICS,1);
    
    % Si se detectan filas vacías en el CSV cargado, aunque no se generen
    % más métricas se da la orden de generar un nuevo CSV, que tendrá
    % eliminadas dichas filas
    if CSV_loaded_size ~= CSV_cleaned_size
        new_metrics = true;
    end
    
    % Ordenamos el CSV para un correcto procesado
    METRICS = sortrows(METRICS,[Info.MODE,Info.SEQUENCE,Info.FRAME,-Info.PUSIZE,-Info.QP,-Info.CSF]);
end

BestModesHEVC = {'RD','Coste'};
BestModesPHEVC = {'HAD','SAD-Res','SAD-FQRes','SSIM1-Pre','SSIM2-Pre','SSIM3'};

% Obtenemos el número total de secuencias yuv y de Frames
numSequences=size(SequenceSet,2);

% Obtenemos el número total de modos
numModes=size(Modes,2);

% Obtenemos el número total de CTUs y NLevels
numCTUs=numel(CTUSizes);
numNLevels=numel(NLevels);

if numCTUs ~= numNLevels
    error('Las variables CTUSizes y NLevels deben tener el mismo número de elementos');
end

% Obtenemos el número total de Qps
numQps=numel(Qps);

% Obtenemos el número total de pesos CSF
numCSFWeight=size(CSFWeightMode,2);

% Obtenemos el número total de Modos de obtención de predicciones
numBestModeBy=size(BestModeBy,2);

% Si no existe un fichero de métricas, inicializamos aquí sus columnas
if numel(fieldnames(Info)) == 0
    % Columas del cell 1=SEQUENCE, 2:MODE, 3=FRAME, 4=CTUSIZE, ...
    Info.SEQUENCE=1;
    Info.MODE=2;
    Info.FRAME=3;
    Info.CTUSIZE=4;
    Info.NLEVELS=5;
    Info.PUSIZE=6;
    Info.QP=7;
    Info.CSF=8;
    Info.BESTMODEBY=9;
    Info.RATE_BITS=10;
    Info.RATE_BPP=11;
    Info.RATE_BPS = 12;
    Info.RATE_KBPS = 13;
    Info.RATE_MBPS = 14;
    Info.PSNR=15;
    Info.SSIM=16;
    Info.MSSSIM=17;
    Info.VIFP=18;
    Info.PSNRHVS=19;
    Info.PSNRHVSM=20;
    Info.VIF=21;
    Info.VMAF_INTRA=22;
    Info.CIEDE=23;
end

% Comprobamos si existe el directorio de salida y lo creamos
if ~exist(output_dir,'dir')
    mkdir(output_dir);
end

% Matriz donde se guardan las ejecuciones de métricas que van a lanzarse
ejecuciones_metricas = {};

% Bucle para contar el número de secuencias a procesar
for i=1:numSequences
    width=SequenceSizes{i}(1);
    height=SequenceSizes{i}(2);
    framerate=FrameRates{i};

    sequence=SequenceSet{i};
    [~,sequenceBaseName,~] = fileparts(sequence);
    % Creamos el directorio de la secuencia si no existe
    if  ~exist(strcat(output_dir,'\',sequenceBaseName),'dir')
        mkdir(strcat(output_dir,'\',sequenceBaseName));
    end
    
    Frames=FramesSet{i};
    numFrames=numel(Frames);
    
    % Bucle de Frames
    for f=1:numFrames
        frame=Frames(f);
        % Bucle de Modes
        for m=1:numModes
            mode=Modes{m};
            % Creamos el directorio del modo si no existe
            if  ~exist(strcat(output_dir,'\',sequenceBaseName,'\',mode),'dir')
                mkdir(strcat(output_dir,'\',sequenceBaseName,'\',mode));
            end
            % Bucle de CTUs y NLevels
            for c=1:numCTUs
                ctusize=CTUSizes(c);
                nlevels=NLevels(c);
                pusize=ctusize/2^nlevels;
                if pusize == -2, pusize = -1; end % Si es HEVCPartition asignanos a pusize el valor -1
                % Bucle de Qps
                for q=1:numQps
                    qp=Qps(q);
                    for cm=1:numCSFWeight
                        csfmode=CSFWeightMode{cm};
                        for bm=1:numBestModeBy
                            bestmodeby = BestModeBy{bm};
                            if (strcmp(mode,'hevc') && ~any(strcmp(BestModesHEVC,bestmodeby))) || (strcmp(mode,'phevc') && ~any(strcmp(BestModesPHEVC,bestmodeby)))
                                continue
                            end
                            % Si es HEVC, PUSize = 4 y staCSF, nos lo saltamos
                            % ya que en el estandar no aplica
                            if strcmp(mode,'hevc') && pusize == 4 && strcmp(csfmode,'staCSF')
                                continue;
                            end
                            % Comprobamos si ya se han procesado las métricas, en cuyo caso nos saltamos este proceso
                            if CheckIfMetricExist(METRICS,Info,sequenceBaseName,mode,frame,ctusize,nlevels,qp,csfmode,bestmodeby) == true
                                continue
                            end
                            ejecuciones_metricas(end+1,:) = {sequenceBaseName,frame,framerate,width,height,bitDepth,mode,qp,ctusize,nlevels,csfmode,bestmodeby};
                        end %BestModeBy
                    end %CSFWeightMode
                end %Qps
            end %CTUs y NLevels
        end %Modes
    end %Frames
end %Sequences

% Creamos la barra de progreso
steps = size(ejecuciones_metricas,1);

if steps > 0
    f_waitbar = parfor_progressbar(steps,'Generando métricas, tenga paciencia...');
    
    METRICS_TMP = cell(steps,numel(fieldnames(Info)));
    
    % Inicialización a false del vector de flags para cada iteración
    new_metrics_array = false(steps, 1);
    
    % Bucle de ejecuciones
	parfor ( i = 1:steps, parallelWorkers )
    %for i = 1:steps % Todavía no funciona correctamente, se salta algunos y luego quedan huecos y peta. Mejor secuencialmente.
        sequenceBaseName = ejecuciones_metricas{i,1};
        frame = ejecuciones_metricas{i,2};
        framerate = ejecuciones_metricas{i,3};
        width = ejecuciones_metricas{i,4};
        height = ejecuciones_metricas{i,5};
        bitDepth = ejecuciones_metricas{i,6};
        mode = ejecuciones_metricas{i,7};
        qp = ejecuciones_metricas{i,8};
        ctusize = ejecuciones_metricas{i,9};
        nlevels = ejecuciones_metricas{i,10};
        pusize = ctusize/2^(nlevels);
        if pusize == -2, pusize = -1; end % Si es HEVCPartition asignanos a pusize el valor -1
        csfmode = ejecuciones_metricas{i,11};
        bestmodeby = ejecuciones_metricas{i,12};
        
        % Comprobamos si se está usando particionado QuadTree en función
        % del valor de ctusize o nlevels
        HEVCPartition = false;
        if ctusize == -1 || nlevels == -1
            HEVCPartition = true;
        end
        
        if ~HEVCPartition
            fprintf('  Processing metrics: Sequence=%s Frame=%03d CTU=%02d Levels=%1d QP=%02d CSF=%s\n', sequenceBaseName, frame, ctusize, nlevels, qp, csfmode);
        else
            fprintf('  Processing metrics: Sequence=%s Frame=%03d HEVCPartition QP=%02d CSF=%s\n', sequenceBaseName, frame, qp, csfmode);
        end

        original_sequence_path = sprintf('%s\\%s\\%s_%03d.yuv',output_dir,sequenceBaseName,sequenceBaseName,frame);
        if ~HEVCPartition
            regenerate_sequence_path = sprintf('%s\\%s\\%s\\%s_%s_%03d_bd%02d_ctu%02d_l%1d_qp%02d_%s_bm%s.yuv',output_dir,sequenceBaseName,mode,mode,sequenceBaseName,frame,bitDepth,ctusize,nlevels,qp,csfmode,bestmodeby);
        else
            regenerate_sequence_path = sprintf('%s\\%s\\%s\\%s_%s_%03d_bd%02d_qp%02d_%s_bm%s.yuv',output_dir,sequenceBaseName,mode,mode,sequenceBaseName,frame,bitDepth,qp,csfmode,bestmodeby);
        end
        
        try
            [vif, vifp] = GetVIFResult(original_sequence_path,regenerate_sequence_path,width,height);
        catch ME
            if ~strcmp(ME.identifier,'MyFunction:fileNotFound')
                warning(ME.message);
            else
                fprintf('    ERROR: %s\n', ME.message);
            end
            f_waitbar.iterate(1);
            continue;
        end
        try
            if ~HEVCPartition
%                 [ImageEntropy] = GetImageEntropy(sprintf('%s\\%s',output_dir,sequence),frame,mode,ctusize,nlevels,qp,csfmode,bestmodeby);
                [ bits, bpp, bps, kbps, Mbps ] = GetImageRate( sprintf('%s\\%s',output_dir,sequenceBaseName), frame, framerate, mode, ctusize, nlevels, qp, csfmode, bestmodeby);
            else
                ImageCoefs=LoadFrameCQImage(sprintf('%s\\%s',output_dir,sequenceBaseName), frame, mode, qp, csfmode, bestmodeby);
                ImageEntropy=ZeroOrderEntropy(ImageCoefs,true,false);

                %Calculamos los bits ocupados.
                numPixels=width*height;
                
                bits=ImageEntropy*numPixels;

                bpp=bits/numPixels;

                bps = bits * framerate;
                kbps = bps * 10^-3;
                Mbps = bps * 10^-6;
            end
        catch ME
            warning(ME.message);
            f_waitbar.iterate(1);
            continue;
        end
        try
            %[psnr, ssim, msssim, vifp, psnr_hvs, psnr_hvs_m] = GetVQMTResult(original_sequence_path,regenerate_sequence_path,height,width,1);
            [~, ~, ~, ~, psnr_hvs, ~] = GetVQMTResult(original_sequence_path,regenerate_sequence_path,height,width,1);
%             % Implementación original en Matlab de PSNR-HVS, 
%             % PSNR-HVS-M y VIFP (las PSNR-HVS* van bastante mas
%             % lentas que su implementación en C de VQMT.exe)
%             [org_image, ~, ~] = yuv_import(original_sequence_path, [width, height], 1, 0, 'YUV420_8');
%             [dist_image, ~, ~] = yuv_import(regenerate_sequence_path, [width, height], 1, 0, 'YUV420_8');
%             [psnr_hvs_m, psnr_hvs] = psnrhvsm(org_image{1}, dist_image{1});
%             [vifp] = vifp_mscale(org_image{1}, dist_image{1});
        catch ME
            warning(ME.message);
            f_waitbar.iterate(1);
            continue;
        end
        try
            [vmaf_intra, psnr, ssim, msssim, ciede, psnr_hvs_m, psnr_hvs_m_y, ~, ~, ~, ~, ~, ~, ~, ~, ~] = GetVMAFResult(original_sequence_path,regenerate_sequence_path,width,height);
        catch ME
            warning(ME.message);
            f_waitbar.iterate(1);
            continue;
        end
        
        METRIC_TMP = METRICS_TMP(i,:);
        
        METRIC_TMP{Info.SEQUENCE}=sequenceBaseName;
        METRIC_TMP{Info.MODE}=mode;
        METRIC_TMP{Info.FRAME}=frame;
        METRIC_TMP{Info.CTUSIZE}=ctusize;
        METRIC_TMP{Info.NLEVELS}=nlevels;
        METRIC_TMP{Info.PUSIZE}=pusize;
        METRIC_TMP{Info.QP}=qp;
        METRIC_TMP{Info.CSF}=csfmode;
        METRIC_TMP{Info.BESTMODEBY}=bestmodeby;
        METRIC_TMP{Info.RATE_BITS}=bits;
        METRIC_TMP{Info.RATE_BPP}=bpp;
        METRIC_TMP{Info.RATE_BPS}=bps;
        METRIC_TMP{Info.RATE_KBPS}=kbps;
        METRIC_TMP{Info.RATE_MBPS}=Mbps;
        METRIC_TMP{Info.PSNR}=psnr;
        METRIC_TMP{Info.SSIM}=ssim;
        METRIC_TMP{Info.MSSSIM}=msssim;
        METRIC_TMP{Info.VIFP}=vifp;
        METRIC_TMP{Info.PSNRHVS}=psnr_hvs;
        METRIC_TMP{Info.PSNRHVSM}=psnr_hvs_m_y; % la variante _y indica luminancia únicamente
        METRIC_TMP{Info.VIF}=vif;
        METRIC_TMP{Info.VMAF_INTRA}=vmaf_intra;
        METRIC_TMP{Info.CIEDE}=ciede;
        
        METRICS_TMP(i,:) = METRIC_TMP;
        
        % Se asigna true a la posición i del vector
        new_metrics_array(i) = true;
        
        f_waitbar.iterate(1);
    end
    close(f_waitbar)
    
    METRICS = [METRICS;METRICS_TMP];
    
    % Se determina si alguna iteración generó nueva métrica:
    new_metrics = any(new_metrics_array);
end

% Se determina si alguna iteración generó nueva métrica:
new_metrics = any(new_metrics_array);

% Limpiamos las secuencias no procesadas (evitamos guardar ';;;;;;;;' en CSV
METRICS = METRICS(~cellfun(@isempty,METRICS(:,1)),:);

% Eliminamos las posibles filas duplicadas (si es lanzamiento de HM puro)
if isfield(Info,'SBH')
    METRICS = RemoveDuplicateRowsMetrics(METRICS, Info.FRAME, Info.SBH);
end

% Ordenamos el CSV para un correcto procesado
METRICS = sortrows(METRICS,[Info.MODE,Info.SEQUENCE,Info.FRAME,-Info.PUSIZE,-Info.QP,-Info.CSF]);

% Guarda el CSV con las métricas solo si hay cambios
if new_metrics == true
    GenCSV(METRICS,Info,'Metrics',output_dir);
end
end

function found = CheckIfMetricExist(Metrics,Info,Sequence,Mode,Frame,CTUsize,NLevels,Qp,CSFmode,Bestmodeby)
found = false;

if ~isempty(Metrics)
    idx_seq = find(strcmp(Metrics(:, Info.SEQUENCE), Sequence));
    if ~isempty(idx_seq)
        Metrics = Metrics(idx_seq,:);
        idx_mode = find(strcmp(Metrics(:, Info.MODE), Mode));
        if ~isempty(idx_mode)
            Metrics = Metrics(idx_mode,:);
            idx_frame = find([Metrics{:, Info.FRAME}] == Frame)';
            if ~isempty(idx_frame)
                Metrics = Metrics(idx_frame,:);
                idx_ctu = find([Metrics{:, Info.CTUSIZE}] == CTUsize)';
                if ~isempty(idx_ctu)
                    Metrics = Metrics(idx_ctu,:);
                    idx_nlevels = find([Metrics{:, Info.NLEVELS}] == NLevels)';
                    if ~isempty(idx_nlevels)
                        Metrics = Metrics(idx_nlevels,:);
                        idx_qp = find([Metrics{:, Info.QP}] == Qp)';
                        if ~isempty(idx_qp)
                            Metrics = Metrics(idx_qp,:);
                            idx_csf = find(strcmp(Metrics(:, Info.CSF), CSFmode));
                            if ~isempty(idx_csf)
                                Metrics = Metrics(idx_csf,:);
                                idx_bm = find(strcmp(Metrics(:, Info.BESTMODEBY), Bestmodeby));
                                if ~isempty(idx_bm)
                                    found = true;
                                end
                            end
                        end
                    end
                end
            end  
        end
    end
end
end

function GenCSV(METRICS,Info,fileName,output_dir)
    csvFileName=sprintf('%s\\%s.csv',output_dir,fileName);
    
    % Hacemos un backup del archivo de métricas
    fecha_ejecucion = datestr(now,'yyyymmddHHMMSS');
    csvFileNameBackup=sprintf('%s\\%s_%s.csv',output_dir,fileName,fecha_ejecucion);
    if exist(csvFileName,'file') == 2
        copyfile(csvFileName, csvFileNameBackup);
    end

    fid=fopen(csvFileName,'w'); % Sobreescribimos el archivo existente

    if (fid<0)
        delete(csvFileNameBackup);
        error('No se ha podido abrir para escritura el fichero %s',csvFileName);
    else
        try
            csvHeader1 = '';
            columnas = fieldnames(Info);
            num_columnas = numel(columnas);
            col_id = 1;
            for i=1:num_columnas
                for j=1:num_columnas
                    if Info.(columnas{i}) == col_id
                        csvHeader1 = [csvHeader1 columnas{i}];
                        if col_id < num_columnas
                            csvHeader1 = [csvHeader1 ';'];
                        end

                        break
                    end
                end
                col_id = col_id + 1;
            end
            fprintf(fid,[csvHeader1 '\n']);

            string_columns = [Info.SEQUENCE Info.MODE Info.CSF Info.BESTMODEBY];
            double_02_columns = [Info.CTUSIZE Info.PUSIZE Info.QP Info.RATE_BITS Info.RATE_BPS];
            double_03_columns = [Info.FRAME];
            double_01_columns = [Info.NLEVELS];
            float_04_columns = [Info.RATE_BPP Info.RATE_KBPS Info.RATE_MBPS];
            float_06_columns = [Info.VIFP Info.VIF Info.SSIM Info.MSSSIM Info.PSNR Info.PSNRHVS Info.PSNRHVSM Info.VMAF_INTRA Info.CIEDE];

            for r=1:size(METRICS,1)
                fila = '';
                for c=1:num_columnas
                    if any(ismember(c,float_04_columns))
                        fila = [fila strrep(sprintf('%.4f',METRICS{r,c}),'.',',')]; % Cambiamos el punto por la coma para separación decimal
                    elseif any(ismember(c,float_06_columns))
                        fila = [fila strrep(sprintf('%.6f',METRICS{r,c}),'.',',')]; % Cambiamos el punto por la coma para separación decimal
                    elseif any(ismember(c,string_columns))
                        fila = [fila sprintf('%s',METRICS{r,c})];
                    elseif any(ismember(c,double_02_columns))
                        fila = [fila strrep(sprintf('%02d',METRICS{r,c}),'.',',')];
                    elseif any(ismember(c,double_01_columns))
                        fila = [fila strrep(sprintf('%1d',METRICS{r,c}),'.',',')];
                    elseif any(ismember(c,double_03_columns))
                        fila = [fila strrep(sprintf('%03d',METRICS{r,c}),'.',',')];
                    else
                        continue
                    end

                    if c < num_columnas
                        fila = [fila ';'];
                    else
                        fila = [fila '\n'];
                    end
                end
                fprintf(fid,fila);
            end
            fclose(fid);
        catch ME
            % En caso de cualquier error, se restaura el archivo original
            fclose(fid);
            fclose('all');
            delete(csvFileName);
            if exist(csvFileNameBackup,'file') == 2
                copyfile(csvFileNameBackup, csvFileName);
                delete(csvFileNameBackup);
            end
            error(ME.message);
        end
    end
end