function [ response ] = is64bitComputer( )
%IS64BITCOMPUTER Obtiene si el PC es de 64 o 32 bits (o la versión de Matlab)
% https://es.mathworks.com/matlabcentral/answers/96172-how-can-i-determine-if-i-am-running-a-32-bit-version-of-matlab-or-a-64-bit-version-of-matlab

[~,maxArraySize]=computer; 
response = maxArraySize> 2^31;

end

