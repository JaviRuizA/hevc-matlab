function [ currentDir ] = getPWD( )
%GETPWD Obtiene el directorio actual (pwd) en modo MATLAB o el directorio
%  donde se encuentra el .exe en modo compilado

if isdeployed() % Stand-alone mode.
    [~, result] = system('path');
    currentDir = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
else % MATLAB mode.
    currentDir = pwd;
end

end

