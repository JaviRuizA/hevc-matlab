function [VMAF, PSNR, SSIM, MSSSIM, CIEDE, PSNRHVS, PSNRHVS_Y, frames, frame_per_frames, vmaf_per_frames, psnr_per_frames, ssim_per_frames, msssim_per_frames, ciede_per_frames, psnrhvs_per_frames, psnrhvs_y_per_frames]=GetVMAFResult(image,distorted,width,height,vmafPath)
%Ejecuta la utilidad vmafossexec_*.exe para obtener los valores de las métricas.
% Procesa ficheros yuv
% Abre los ficheros de resultados y captura el valor de calidad para el único frame procesado
% Elimina los ficheros de resultados
% NOTA: La métrica PSNR satura en 60dB
% NOTA2: Desde hace un tiempo no es sencillo compilar el código de VMAF en
% Windows, por lo que lo más sencillo es descargar el compilado de aquí:
%   https://ci.appveyor.com/api/projects/status/68i57b8ssasttngg?svg=true
%   https://ci.appveyor.com/project/li-zhi/vmaf

% Directorio donde se encuentran los archivos vmafossexec_*.exe
if ~exist('vmafPath','var') || isempty(vmafPath)
    % Si no se le pasa un directorio determinado, lo obtiene según
    % jerarquía programada.
    vmafPath = [ getPWD() '\tools\VMAF'];
end
currentPath=getPWD();

[original_path,originalBaseName,~] = fileparts(image);
org_image=strcat(original_path,'\',originalBaseName,'.yuv');
if (exist(org_image, 'file') == 0)
    error('La imagen original [%s] no existe',image);
elseif (~exist(org_image, 'file') == 2)
    error('La imagen original [%s] no existe en formato yuv',image);
end

[distorted_path,distortedBaseName,~] = fileparts(distorted);
dist_image=strcat(distorted_path,'\',distortedBaseName,'.yuv');
if (exist(dist_image, 'file') == 0)
    error('La imagen distorsionada [%s] no existe',image);
elseif (~exist(dist_image, 'file') == 2)
    error('La imagen distorsionada [%s] no existe en formato yuv',dist_image);
end

%Componemos la linea de comando para ejecutar la heramienta vmafossexec.exe

pixel_format = 420;   % pixel_format (420/422/444)
bitdepth = 8;         % bitdepth (8/10/12)
feature = '--feature psnr --feature psnr_hvs --feature float_ssim --feature float_ms_ssim --feature ciede';

% Seleccionamos el modelo entrenado en función de la resolución del vídeo
if width*height > 1920*1080
    % Modelo entrenado para secuencias superiores a 1080p
    model = '--model version=vmaf_4k_v0.6.1';
else
    % Modelo entrenado para secuencias 1080p o inferior
    model = '--model version=vmaf_v0.6.1';
end

% Número máximo de hilos de ejecución (defecto 0 - usa todos los hilos)
threads='--thread 0';

params = sprintf(' --reference %s --distorted %s --width %d --height %d --pixel_format %d --bitdepth %d %s --output %s_vmaf_output.xml --xml %s %s --quiet',org_image,dist_image,width,height,pixel_format,bitdepth,model,distortedBaseName,threads,feature);

if is64bitComputer()
    VMAF_version = 'vmaf.exe';
else
    warning('VMAF only compatible with 64bit system\n');
    VMAF = NaN;
    PSNR = NaN;
    SSIM = NaN;
    MSSSIM = NaN;
    frames = NaN;
    frame_per_frames = NaN;
    vmaf_per_frames = NaN;
    psnr_per_frames = NaN;
    ssim_per_frames = NaN;
    msssim_per_frames = NaN;
    return
end
% command = strcat(vmafPath, '\vmafossexec.exe ', params);
command = strcat(vmafPath, '\', VMAF_version, params);
status=-1; intentos=0;
while(status~=0)
    intentos=intentos+1;
    
    %Ejecutamos el comando
    [status,result]=system(command);
    
    if status == 1
        error('No se encuentra el archivo %s en la ruta\n%s',vmafPath,VMAF_version);
    elseif status ~= 0
        if intentos > 3
            error(['Error en la Ejecución de VMAF: ' result ])
        end
    else
        %Leemos valor de PSNR
        %-----------------------------------------
        filename=strcat(currentPath,'\',distortedBaseName,'_vmaf_output.xml');
        mlStruct = parseXML(filename);
        
        frames = floor(size(mlStruct.Children(6).Children , 2) / 2);
        
        CIEDE = str2double(mlStruct.Children(6).Children(2).Attributes(1).Value);
        MSSSIM = str2double(mlStruct.Children(6).Children(2).Attributes(2).Value);
        SSIM = str2double(mlStruct.Children(6).Children(2).Attributes(3).Value);
        
        frame = str2double(mlStruct.Children(6).Children(2).Attributes(4).Value);
        
        PSNRHVS = str2double(mlStruct.Children(6).Children(2).Attributes(18).Value);
        PSNRHVS_Y = str2double(mlStruct.Children(6).Children(2).Attributes(21).Value);
        PSNR = str2double(mlStruct.Children(6).Children(2).Attributes(22).Value);
        
        VMAF = str2double(mlStruct.Children(6).Children(2).Attributes(23).Value);
        
        if frames > 1
            ciede_per_frames = zeros(frames,1);
            msssim_per_frames = zeros(frames,1);
            ssim_per_frames = zeros(frames,1);
            
            frame_per_frames = zeros(frames,1);
            
            psnrhvs_per_frames = zeros(frames,1);
            psnrhvs_y_per_frames = zeros(frames,1);
            psnr_per_frames = zeros(frames,1);
            
            vmaf_per_frames = zeros(frames,1);
            
            idx = 1;
            for i=2:2:2*frames
                ciede_per_frames(idx) = str2double(mlStruct.Children(6).Children(i).Attributes(1).Value);
                msssim_per_frames(idx) = str2double(mlStruct.Children(6).Children(i).Attributes(2).Value);
                ssim_per_frames(idx) = str2double(mlStruct.Children(6).Children(i).Attributes(3).Value);
                frame_per_frames(idx) = str2double(mlStruct.Children(6).Children(i).Attributes(4).Value) + 1;
                
                psnrhvs_per_frames(idx) = str2double(mlStruct.Children(6).Children(i).Attributes(18).Value);
                psnrhvs_y_per_frames(idx) = str2double(mlStruct.Children(6).Children(i).Attributes(21).Value);
                psnr_per_frames(idx) = str2double(mlStruct.Children(6).Children(i).Attributes(22).Value);
                
                vmaf_per_frames(idx) = str2double(mlStruct.Children(6).Children(i).Attributes(23).Value);
                idx = idx + 1;
            end
        else
            ciede_per_frames = CIEDE;
            msssim_per_frames = MSSSIM;
            ssim_per_frames = SSIM;
            
            frame_per_frames = frame;
            
            psnrhvs_per_frames = PSNRHVS;
            psnrhvs_y_per_frames = PSNRHVS_Y;
            psnr_per_frames = PSNR;
            
            vmaf_per_frames = VMAF;
        end
        
        % A veces VMAF devuelve NaN cuando la calidad es muy mala,
        % reemplazamos por 0 para evitar errores al guardar CSV
        ciede_per_frames(isnan(ciede_per_frames))=0;
        msssim_per_frames(isnan(msssim_per_frames))=0;
        ssim_per_frames(isnan(ssim_per_frames))=0;

        psnrhvs_per_frames(isnan(psnrhvs_per_frames))=0;
        psnrhvs_y_per_frames(isnan(psnrhvs_y_per_frames))=0;
        psnr_per_frames(isnan(psnr_per_frames))=0;

        vmaf_per_frames(isnan(vmaf_per_frames))=0;
        
        % Eliminamos el XML temporal
        DeleteFile(filename);
    end
end

end
