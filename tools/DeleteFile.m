function [ ] = DeleteFile(filename)
%DELETEFILE Elimina de forma permanente un archivo de disco
%  Guarda el estado de eliminar configurado en Matlab, para luego
%  restablecerlo
if exist(filename, 'file')==2
    % Se guarda el estado de Matlab con respecto a recycle
    state = recycle;
    % Se asigna 'off' como medida de borrado, así los archivos temporales
    % se eliminarán en lugar de ir a la papelera de reciclaje
    recycle('off');
    % Borrado del archivo
    delete(filename);
    % Se restaura el estado original
    recycle(state);
end
end