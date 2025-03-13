function rd=QPEntropyDistortion(R,D,QP,modo)
% R/D = D + lambda*R; 
% donde, 
% D = Distorsion, 
% R = Entropia (Rate) (bits del bloque)
% Modo SAD:
%    Lambda = sqrt (0,57 * pow (2, (QP-12)/3)) – Para QP = 32 -> lambda = 7,60975626….
% Modo SSIM:
%    Lambda viene de: 2005_Mai_Yang_Xie
%    Lambda = 1.11 * 2^((QP-60)/5)
% Modo SSIM2:
%    Lambda viene de: 2014_Cen_Lu_Xu
%    Lambda = 0.0515*QP^1.65;
if ~exist('modo','var') || isempty(modo)
   modo='lambdaHEVC';
end
switch (modo)
    case 'lambdaHEVC'
        lambda = sqrt(0.57 * 2^((QP-12)/3));
    case 'lambdaSSIM1'
        lambda = 1.11 * 2^((QP-60)/5);
    case 'lambdaSSIM2'    
        lambda = 0.0515*QP^1.65;
    otherwise
        error('QPEntropyDistortion: Error: El modo debe ser HAD, SSIM1, o SSIM2');
end
rd = D + lambda*R;
end
