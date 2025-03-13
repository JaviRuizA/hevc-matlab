function [PSNR, SSIM, MSSSIM, VIFP, PSNRHVS, PSNRHVSM]=GetVQMTResult(image,distorted,height,width,num_frames,vqmtPath)
%Ejecuta la utilidad vqmt.exe para obtener los valores de las métricas.
%Procesa ficheros yuv
%Abre los ficheros de resultados y captura el valor de calidad para el único frame procesado
%Elimina los ficheros de resultados

PSNR = zeros(num_frames,1);
SSIM = zeros(num_frames,1);
MSSSIM = zeros(num_frames,1);
VIFP = zeros(num_frames,1);
PSNRHVS = zeros(num_frames,1);
PSNRHVSM = zeros(num_frames,1);

% Directorio donde se encuentra el archivo vqmt.exe
if ~exist('vqmtPath','var') || isempty(vqmtPath)
    % Si no se le pasa un directorio determinado, lo obtiene según
    % jerarquía programada.
    %vqmtPath = [ fileparts(which('HEVC_Main.m')) '\tools\VQMTMetric'];
    vqmtPath = [ getPWD() '\tools\VQMTMetric'];
end
currentPath=getPWD();

[original_path,originalBaseName,~] = fileparts(image);
org_image=strcat(original_path,'\',originalBaseName,'.yuv');
if (exist(org_image, 'file') == 0)
    error('La imagen original [%s] no existe',org_image);
elseif (~exist(org_image, 'file') == 2)
    error('La imagen original [%s] no existe en formato yuv',org_image);
end

[distorted_path,distortedBaseName,~] = fileparts(distorted);
dist_image=strcat(distorted_path,'\',distortedBaseName,'.yuv');
if (exist(dist_image, 'file') == 0)
    error('La imagen distorsionada [%s] no existe',dist_image);
elseif (~exist(dist_image, 'file') == 2)
    error('La imagen distorsionada [%s] no existe en formato yuv',dist_image);
end

%Componemos la linea de comando para ejecutar la heramienta vqmt.exe
params = sprintf(' "%s" "%s" %d %d %d 1 %s',org_image,dist_image,height,width,num_frames,distortedBaseName);

metricas=' PSNR SSIM MSSSIM VIFP PSNRHVS PSNRHVSM';
command = strcat(vqmtPath, '\VQMT.exe ', params, metricas);
status=-1; intentos=0;
while(status~=0)
    intentos=intentos+1;
    
    %Ejecutamos el comando
    [status,result]=system(command);
    
    if status == 1
        fprintf('Command: %s\nStatus: %d\nResult: %s\n',command,num2str(status),result);
        if contains(result,'unexpected EOF')
            % El archivo regenerado puede estar corrupto, lo eliminamos
            delete(distorted);
        end
        error(result);
    elseif status ~= 0
        if intentos > 3
            error(['Error en la Ejecución de VQMT: ' result ])
        end
    else
        %Leemos valor de PSNR
        %-----------------------------------------
        filename=strcat(currentPath,'\',distortedBaseName,'_psnr.csv');
        Q=importdata(filename);
        if size(Q.data,1) == num_frames
            PSNR=Q.data(:,2);
        else
            % Tocará implementar función que lea línea a línea y guarde los
            % datos correctos, y los corruptos ponerles NaN.
        end
        DeleteFile(filename);

        %Leemos valor de SSIM
        %-----------------------------------------
        filename=strcat(currentPath,'\',distortedBaseName,'_ssim.csv');
        Q=importdata(filename);
        if size(Q.data,1) == num_frames
            SSIM=Q.data(:,2);
        else
            % Tocará implementar función que lea línea a línea y guarde los
            % datos correctos, y los corruptos ponerles NaN.
        end
        DeleteFile(filename);

        %Leemos valor de MSSSIM
        %-----------------------------------------
        filename=strcat(currentPath,'\',distortedBaseName,'_msssim.csv');
        Q=importdata(filename);
        if size(Q.data,1) == num_frames
            MSSSIM=Q.data(:,2);
        else
            % Tocará implementar función que lea línea a línea y guarde los
            % datos correctos, y los corruptos ponerles NaN.
        end
        DeleteFile(filename);

        %Leemos valor de VIFP
        %-----------------------------------------
        filename=strcat(currentPath,'\',distortedBaseName,'_vifp.csv');
        Q=importdata(filename);
        if size(Q.data,1) == num_frames
            VIFP=Q.data(:,2);
        else
            % Tocará implementar función que lea línea a línea y guarde los
            % datos correctos, y los corruptos ponerles NaN.
        end
        DeleteFile(filename);

        %Leemos valor de PSNRHVS
        %-----------------------------------------
        filename=strcat(currentPath,'\',distortedBaseName,'_psnrhvs.csv');
        Q=importdata(filename);
        if size(Q.data,1) == num_frames
            PSNRHVS=Q.data(:,2);
        else
            % Tocará implementar función que lea línea a línea y guarde los
            % datos correctos, y los corruptos ponerles NaN.
        end
        DeleteFile(filename);

        %Leemos valor de PSNRHVSM
        %-----------------------------------------
        filename=strcat(currentPath,'\',distortedBaseName,'_psnrhvsm.csv');
        Q=importdata(filename);
        if size(Q.data,1) == num_frames
            PSNRHVSM=Q.data(:,2);
        else
            % Tocará implementar función que lea línea a línea y guarde los
            % datos correctos, y los corruptos ponerles NaN.
        end
        DeleteFile(filename);
    end
end

%DeleteFile('ResultFile.txt');

end