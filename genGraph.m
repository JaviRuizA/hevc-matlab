function [ ] = genGraph(METRICS,Info,metrics_path,quality_metric,sequences_,frames_,modes_,ctusize_,nlevel_,csf_,bestmodeby_,ratemode_,videomode_,print_to_pdf)
% GENGRAPH Realiza las gráficas a partir del archivo de métricas generado
% con GenSequenceSetMetrics.m y crea un CSV para exportar a MS Excel
%
% Parámetros:
%  metrics_path   : La ruta completa del archivo .csv de métricas.
%  quality_metric : String para indicar la métrica de calidad a la hora
%                    realizar las gráficas. Puede ser:
%                   'PSNR', 'SSIM', 'MSSSIM' ,'VIFP' ,'PSNRHVS' ,'PSNRHVSM',
%                   'VIF', 'VMAF', 'VMAF_INTRA', 'CIEDE'
%  sequence_      : Un cell array con el nombre de las secuencias a procesar.
%  frame_         : Un cell array con el número de frames en formato array a
%                    procesar por cada secuencia.
%  mode_          : Un cell array con el nombre de los modos a procesar.
%                    Al menos debe indicarse uno de {'hevc' 'phevc'}
%  ctusize_       : Un array con los tamaños de CTU a procesar
%  nlevel_        : Un array con el nivel de descomposicion para cada uno de los CTUSizes del
%                    parametro anterior. En el mismo orden.
%  csf_           : Un cell array con el tipo de CSF aplicada. {'noCSF' 'staCSF' 'ourCSF' 'CSF'}
%  bestmodeby_    : Un cell array con el método para elegir el mejor modo.
%                    para el modo_ 'hevc' : {'Coste' 'RD'}
%                    para el modo_ 'phevc': {'HAD' 'SAD-Res' 'SAD-FQRes' 'SSIM1-Pre' 'SSIM2-Pre' 'SSIM3'}
%  ratemode_      : Un char string que indica el modo de rate utilizado.
%  videomode_     : Un booleano que indique si se deben hacer promedios de los
%                    frames (true) o graficar los frames por separado (false).
%                    Por defecto estará a false.
%  print_to_pdf   : Una variable booleana que decide si las gráficas se
%                    guardan en PDF.
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Inicialización y carga de variables %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%close all;

load_CSV = false;

if ~exist('METRICS','var') || ~exist('Info','var')
    % Obtenemos las métricas ya guardadas, para evitar volver a procesarlas
    METRICS = {};
    Info = struct;

    if exist(metrics_path,'file') == 2
        [METRICS, Info] = csv2cell(metrics_path, 'fromfile');
        % Ordenamos el CSV para un correcto procesado
        METRICS = sortrows(METRICS,[Info.MODE,Info.SEQUENCE,Info.FRAME,-Info.PUSIZE,-Info.QP,-Info.CSF]);
    else
        error('No se encuentra el archivo %s', metrics_path)
    end
end

% Si no hay archivo de métricas o se encuentra vacío, terminamos la
% ejecución
if size(METRICS,1) == 0
    error('Imposible generar gráficas y estadísticos: el archivo de métricas se encuentra vacío o no existe');
    return
end

% Obtenemos el directorio de salida donde guardar el CSV
[output_path,~,~] = fileparts(metrics_path);

% Obtenemos la fecha de lanzamiento de la métrica
fecha_metricas = datestr(now,'yyyymmddHHMMSS');

% Ordenación de parámetros específica
sorted_Modes = {'hevc','phevc'};
sorted_CSFs = {'noCSF','staCSF','ourCSF','CSF'};
sorted_BestModeBy_hevc = {'RD','Coste'};
sorted_BestModeBy_phevc = {'HAD','SAD-Res','SAD-FQRes','SSIM1-Pre','SSIM2-Pre','SSIM3'};
sorted_BestModeBy = [sorted_BestModeBy_hevc, sorted_BestModeBy_phevc];

rate_metric = ratemode_;
rate_label = ratemode_;

quality_metric_id = eval(['Info.',quality_metric]);
rate_metric_id = eval(['Info.RATE_',upper(rate_metric)]);

if ~isempty(sequences_)
    for i=1:numel(sequences_)
        % Eliminamos el .yuv del nombre de las secuencias
        [~,sequence_name,~] = fileparts(sequences_{i});
        sequences_{i} = sequence_name;
    end
end

if isempty(videomode_)
    videomode_ = false;
end

if videomode_ == true
    METRICS = getMetricAverage(METRICS,Info,sequences_,frames_);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Recorrido y procesado de las métricas %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i_seq=1:numel(sequences_)
    actual_sequence = sequences_{i_seq};
    sequence_idx = strcmp(METRICS(:,Info.SEQUENCE),actual_sequence)';
    
    frames = frames_{i_seq};
    if videomode_ == true
        frames = -1;
    end
    for i_fr=1:numel(frames)
        actual_frame = frames(i_fr);
        
        frame_idx = ([METRICS{:,Info.FRAME}] == actual_frame);
        
        for i_ctnl=1:size(ctusize_,2)
            actual_CTUsize = ctusize_(i_ctnl);
            actual_NLevel = nlevel_(i_ctnl);
            
            HEVCPartition = false;
            if actual_CTUsize == -1 || actual_NLevel == -1
                HEVCPartition = true;
            end
            
            ctusize_idx = ([METRICS{:,Info.CTUSIZE}] == actual_CTUsize);
            nlevels_idx = ([METRICS{:,Info.NLEVELS}] == actual_NLevel);
            
            EjeX = {};
            EjeY = {};
            legend_str = {};
            
            for i_mod=1:numel(sorted_Modes)
                actual_mode = sorted_Modes{i_mod};
                if ~ismember(actual_mode,modes_)
                    continue
                end
                
                mode_idx = strcmp(METRICS(:,Info.MODE),actual_mode)';
                for i_csf=1:numel(sorted_CSFs)
                    actual_CSF = sorted_CSFs{i_csf};
                    % Comprobamos si es miembro de CSFs
                    if ~ismember(actual_CSF,csf_)
                        continue
                    end
                    
                    csf_idx = strcmp(METRICS(:,Info.CSF),actual_CSF)';

                    for i_bm=1:numel(sorted_BestModeBy)
                        actual_BestModeBy = sorted_BestModeBy{i_bm};

                        % Evitamos los modos que no corresponden
                        if strcmp('hevc',actual_mode) && ~any(strcmp(sorted_BestModeBy_hevc,actual_BestModeBy))
                            continue
                        elseif strcmp('phevc',actual_mode) && ~any(strcmp(sorted_BestModeBy_phevc,actual_BestModeBy))
                            continue
                        end

                        % Comprobamos si es miembro de BestModeBy
                        if ~ismember(actual_BestModeBy,bestmodeby_)
                            continue
                        end

                        bestModeBy_idx = strcmp(METRICS(:,Info.BESTMODEBY),actual_BestModeBy)';

                        % Índice de elementos que cumplen lo establecido arriba,
                        % ahora toca coger el valor (AND '&' Operador lógico)
                        elementos_que_cumplen = find(sequence_idx & mode_idx & frame_idx & ctusize_idx & nlevels_idx & csf_idx & bestModeBy_idx);

                        if ~any(elementos_que_cumplen)
                            continue
                        end

                        EjeX_tmp = cell2mat(METRICS(elementos_que_cumplen,rate_metric_id));
                        EjeY_tmp = cell2mat(METRICS(elementos_que_cumplen,quality_metric_id));

                        % Ordenamos los datos de menor a mayor valor según el eje X
                        [EjeX_tmp_sorted, sort_idx] = sort(EjeX_tmp);
                        EjeY_tmp_sorted = EjeY_tmp(sort_idx);

                        EjeX{end+1} = EjeX_tmp_sorted;
                        EjeY{end+1} = EjeY_tmp_sorted;

                        legend_str{end+1} = [actual_mode,' ',actual_CSF,' ',actual_BestModeBy];
                    end % BestModeBy
                end % CSF
            end % Mode
            
        % Solo grafico y creo el CSV si hay datos
        if ~isempty(legend_str)
            if videomode_ == false && ~HEVCPartition
                title_str = [actual_sequence,' F=',num2str(actual_frame,'%03d'),' CTU=',num2str(actual_CTUsize),' NLevels=',num2str(actual_NLevel)];
                %title_str = [actual_sequence,' F=',num2str(actual_frame,'%03d'),' TB=',num2str(actual_CTUsize/(2^actual_NLevel))];
            elseif videomode_ == false && HEVCPartition
                title_str = [actual_sequence,' F=',num2str(actual_frame,'%03d')];
            elseif videomode_ == true && ~HEVCPartition
                title_str = [actual_sequence,' CTU=',num2str(actual_CTUsize),' NLevels=',num2str(actual_NLevel)];
                %title_str = [actual_sequence,' TB=',num2str(actual_CTUsize/(2^actual_NLevel))];
            else % videomode_ == true && HEVCPartition
                title_str = [actual_sequence];
            end
            plot_graph(EjeX,EjeY,title_str,rate_label,quality_metric,legend_str,print_to_pdf,output_path);
            generate_CSV(EjeX,EjeY,title_str,rate_label,quality_metric,legend_str,output_path,fecha_metricas);
            generate_Bjontegaard(EjeX,EjeY,title_str,rate_label,quality_metric,legend_str,output_path,fecha_metricas);
        end
            
        end % CTUsize y NLevels
    end % Frame
end % Sequence
end

function [] = generate_CSV(EjeX,EjeY,title_str,xAxis_str,yAxis_str,legend_str,outputDir,fecha_calculo)
% Función auxiliar de genGraph.m que genera el CSV preparado para graficar
% usando la gráfica de dispersión XY de MS Excel.
total_cols = numel(legend_str);
csvFileName=sprintf('%s\\Graficas_%s-%s_%s.csv',outputDir,yAxis_str,xAxis_str,fecha_calculo);
fid=fopen(csvFileName,'at');
if (fid<0)
    error('No se ha podido abrir para escritura el fichero %s',csvFileName);
end
line = [title_str ';' yAxis_str '\n'];
fprintf(fid,line);
line = [xAxis_str ';' strjoin(legend_str,';') '\n'];
fprintf(fid,line);
for r=1:total_cols
    for c=1:numel(EjeX{r})
        valor_x = EjeX{r}(c);
        valor_y = EjeY{r}(c);
        line = strrep([num2str(valor_x) repmat(';',r,1)' num2str(valor_y) '\n'],'.',',');
        fprintf(fid,line);
    end
end
fclose(fid);
end

function [] = plot_graph(EjeX,EjeY,title_str,xAxis_str,yAxis_str,legend_str,print_to_pdf,output_path)
% PLOT_GRAPH Función auxiliar de genGraph.m que realiza el plot suavizado
    fig = figure();
    title(title_str,'Interpreter', 'none')
    %formats = {'-+','-o','-*','-.','-x','-s','-d','-^','-v','->','-<','-p','-h','--+','--o','--*','--.','--x','--s','--d','--^','--v','-->','--<','--p','--h',':+',':o',':*',':.',':x',':s',':d',':^',':v',':>',':<',':p',':h','-.+','-.o','-.*','-..','-.x','-.s','-.d','-.^','-.v','-.>','-.<','-.p','-.h'};
    lines_vector = {'-','-','-','-','-','-','-','-','-','-','-','-','-','--','--','--','--','--','--','--','--','--','--','--','--','--',':',':',':',':',':',':',':',':',':',':',':',':',':','-.','-.','-.','-.','-.','-.','-.','-.','-.','-.','-.','-.','-.'};
    markers_vector = {'o','+','*','.','x','s','d','^','v','>','<','p','h','o','+','*','.','x','s','d','^','v','>','<','p','h','o','+','*','.','x','s','d','^','v','>','<','p','h','o','+','*','.','x','s','d','^','v','>','<','p','h'};
    colors_vector = [     0    0.4470    0.7410;
              0.8500    0.3250    0.0980;
              0.9290    0.6940    0.1250;
              0.4940    0.1840    0.5560;
              0.4660    0.6740    0.1880;
              0.3010    0.7450    0.9330;
              0.6350    0.0780    0.1840];
    
    ghost_plots = zeros(numel(EjeX),1); % Inicialización del vector de puntos "fantasma"
    for i=1:numel(EjeX)
        % Obtenemos el formato de la gráfica para la curva actual
        selected_color = colors_vector(1 + mod(i-1,size(colors_vector,1)),:);
        selected_LineStyle = lines_vector{i};
        selected_Marker = markers_vector{i};
        
        x = EjeX{i};
        y = EjeY{i};
        
        % Grafico los valores reales en forma de marcadores
        hold on;
        plot(x, y, selected_Marker, 'Color', selected_color);
        
        grid on;
        samplingRateIncrease = 10; % Número de puntos "virtuales" entre dos muestras reales
        newXSamplePoints = [];
        % Para suavizar la curva creo puntos entre las distintas muestras
        % reales. Si solo tengo un único punto, omito este paso.
        if length(x) - 1 > 0
            for i2=1:length(x) - 1
                if i2 == 1
                    newXSamplePoints = linspace(x(i2), x(i2 + 1), samplingRateIncrease);
                else
                    % Concateno los puntos generados. Dado que el último valor
                    % de la anterior iteración es igual al primer valor de esta
                    % iteración, cojo del vector final todos los elementos
                    % excepto el último, para no añadir duplicados.
                    newXSamplePoints = [newXSamplePoints(1:end-1) linspace(x(i2), x(i2 + 1), samplingRateIncrease)];
                end
            end
            % Obtengo los valores del Eje Y suavizados
            smoothedY = pchip(x, y, newXSamplePoints);
            % Hemos optado por pchip en lugar de spline, ya que con spline las gráficas
            % para la métrica MSSSIM tienen forma de polinomio de grado 3

            % Grafico los valores suavizados en forma de líneas
            hold on;
            plot(newXSamplePoints, smoothedY, selected_LineStyle, 'Color', selected_color);
        else
            hold on;
        end
        
        
        % Creo el plot fantama para customizar la leyenda, ya que al hacer
        % dos plots por gráfica (una para los valores reales y otra para 
        % la curva suavizada) el estilo de la leyenda no era correcto.
        ghost_plots(i) = plot(NaN, NaN, 'LineStyle', selected_LineStyle, 'Marker', selected_Marker, 'Color', selected_color);

    end
    legend(ghost_plots,legend_str,'Location','southeast')
    legend boxoff;
    if strcmp(yAxis_str,'PSNR')
        ylabel([yAxis_str ' (dB)'])
    elseif strcmp(yAxis_str,'NFLX_SSIM')
        ylabel('SSIM')
    elseif strcmp(yAxis_str,'NFLX_MSSSIM')
        ylabel('MSSSIM')
    else
        ylabel(yAxis_str)
    end
    if (strcmp(xAxis_str,'Mbps') || strcmp(xAxis_str,'bps') || strcmp(xAxis_str,'kbps'))
        xlabel(['Bit-Rate (' xAxis_str ')'])
    else
        xlabel(xAxis_str)
    end
    hold off
    if print_to_pdf == true
        orient(fig,'landscape')
        set(fig,'Units','Inches');
        set(fig, 'Position',  [0, 0, 4.5, 4.5]);
        %set(gca,'FontSize',12)
        pos = get(fig,'Position');
        set(fig,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])
        titulo = [title_str ' ' yAxis_str '-' xAxis_str];
        titulo = strrep(titulo, ' ', '_');
        titulo = strrep(titulo, '=', '');
        % Creamos el directorio print si no existe
        if  ~exist(strcat(output_path,'\print'),'dir')
            mkdir(strcat(output_path,'\print'));
        end
        saveas(fig, [output_path '\print\' titulo '.svg'])
        print(fig,[output_path '\print\' titulo],'-dpdf','-fillpage')
        orient(fig,'portrait')
        saveas(fig, [output_path '\print\' titulo '.png'])
    end
end

function [ average_metric ] = getMetricAverage( regular_metric, info_metric, sequences, frames )
%GETMETRICAVERAGE Función auxiliar de genGraph.m que realiza el promedio de
%todas las muestras a partir de los frames.

average_metric = {};

num_rows = size(regular_metric,1);
processed_rows = zeros(num_rows,1);

new_row_idx = 1;
for idx=1:num_rows
    if processed_rows(idx) == 1
        continue
    end
    
    sequence = regular_metric{idx,info_metric.SEQUENCE};
    sequence_idx = strcmp(regular_metric(:,info_metric.SEQUENCE),sequence);
    
    % Comprobamos si es una secuencia o frame que el usuario ha introducido
    tmp_seq_idx = find(contains(sequences, sequence), 1);
    if isempty(tmp_seq_idx)
        % Eliminamos la secuencia del cómputo ya que el usuario no desea
        % calcularla
        average_rows = sequence_idx == 1;
        processed_rows(average_rows) = 1;
        continue
    end
    frames_defined_by_user = frames{tmp_seq_idx};
    
    mode = regular_metric{idx,info_metric.MODE};
    ctusize = regular_metric{idx,info_metric.CTUSIZE};
    nlevels = regular_metric{idx,info_metric.NLEVELS};
    pusize = regular_metric{idx,info_metric.PUSIZE};
    qp = regular_metric{idx,info_metric.QP};
    csf = regular_metric{idx,info_metric.CSF};
    bestmodeby = regular_metric{idx,info_metric.BESTMODEBY};
    
    sequence_idx = strcmp(regular_metric(:,info_metric.SEQUENCE),sequence);
    frame_idx = ismember([regular_metric{:,info_metric.FRAME}], frames_defined_by_user)';
    mode_idx = strcmp(regular_metric(:,info_metric.MODE),mode);
    ctusize_idx = ([regular_metric{:,info_metric.CTUSIZE}] == ctusize)';
    nlevels_idx = ([regular_metric{:,info_metric.NLEVELS}] == nlevels)';
    pusize_idx = ([regular_metric{:,info_metric.PUSIZE}] == pusize)';
    qp_idx = ([regular_metric{:,info_metric.QP}] == qp)';
    csf_idx = strcmp(regular_metric(:,info_metric.CSF),csf);
    bestmodeby_idx = strcmp(regular_metric(:,info_metric.BESTMODEBY),bestmodeby);
    
    average_rows = find((sequence_idx & frame_idx & mode_idx & ctusize_idx & nlevels_idx & pusize_idx & qp_idx & ctusize_idx & csf_idx & bestmodeby_idx) == 1);
    num_average_rows = size(average_rows,1);
    
    columnMeans = mean(cell2mat(regular_metric(average_rows,info_metric.RATE_BITS:end)),1);
    
    average_metric{new_row_idx,info_metric.SEQUENCE} = sequence;
    average_metric{new_row_idx,info_metric.MODE} = mode;
    average_metric{new_row_idx,info_metric.FRAME} = -1; % Asignamos -1 a la columna frame
    average_metric{new_row_idx,info_metric.CTUSIZE} = ctusize;
    average_metric{new_row_idx,info_metric.NLEVELS} = nlevels;
    average_metric{new_row_idx,info_metric.PUSIZE} = pusize;
    average_metric{new_row_idx,info_metric.QP} = qp;
    average_metric{new_row_idx,info_metric.CSF} = csf;
    average_metric{new_row_idx,info_metric.BESTMODEBY} = bestmodeby;
    
    
    average_metric(new_row_idx,info_metric.RATE_BITS:numel(fieldnames(info_metric))) = num2cell(columnMeans);
    
    processed_rows(average_rows) = 1;
    new_row_idx = new_row_idx + 1;
    
    % Descartamos los frames que el usuario no ha seleccionado
    not_average_rows = (sequence_idx & ~frame_idx & mode_idx & ctusize_idx & nlevels_idx & pusize_idx & qp_idx & ctusize_idx & csf_idx & bestmodeby_idx) == 1;
    processed_rows(not_average_rows) = 1;
end
end

function [] = generate_Bjontegaard(EjeX,EjeY,title_str,xAxis_str,yAxis_str,legend_str,outputDir,fecha_calculo)
% Función auxiliar de genGraph.m que genera el CSV que obtiene el cálculo
% del Bjontegaard para todas las curvas, tomando la primera como referencia

num_graphs = numel(legend_str);
if num_graphs > 1
%     dsnr = cell(1,num_graphs - 1);
%     rate = cell(1,num_graphs - 1);
    
    csvFileName=sprintf('%s\\Bjontegaard_%s-%s_%s.csv',outputDir,yAxis_str,xAxis_str,fecha_calculo);
    fid=fopen(csvFileName,'at');
    if (fid<0)
        error('No se ha podido abrir para escritura el fichero %s',csvFileName);
    end

    EjeX_ppal = EjeX{1};
    EjeY_ppal = EjeY{1};
    Leyenda_ppal = legend_str{1};
    
    line = [title_str ';BD-' upper(yAxis_str) ';BD-RATE\n'];
    fprintf(fid,line);
    line = [Leyenda_ppal ';0;0\n'];
    fprintf(fid,line);
    
    try
        for i = 2:num_graphs
            EjeX_sec = EjeX{i};
            EjeY_sec = EjeY{i};
            Leyenda_sec = legend_str{i};

            %[dsnr{i-1}, rate{i-1}] = bjontegaardUMH(EjeX_ppal',EjeY_ppal',EjeX_sec',EjeY_sec','pchip');
            [dsnr, rate] = bjontegaardUMH(EjeX_ppal',EjeY_ppal',EjeX_sec',EjeY_sec','pchip');
            line = strrep([Leyenda_sec ';' num2str(dsnr) ';' num2str(rate) '\n'],'.',',');
            fprintf(fid,line);
        end
        fclose(fid);
    catch ME
        % Si hay un error, cerramos el archivo y lo borramos
        fclose(fid);
        fclose('all');
        delete(csvFileName);
        warning(ME.message);
    end
        
    
end
end