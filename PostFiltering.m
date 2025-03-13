function PU=PostFiltering(PU,T,L,mode,dcVal)
%Realiza el postfiltrado para los modos 
%  Horizontal puro (26)  indice 27
%  Vertical puro (10)    indice 11
%  DC                    indice 35

if ~exist('dcVal','var') || isempty(dcVal)
  dcVal=128;
end

s=size(PU,1);

T=double(T);
L=double(L);
dcVal=double(dcVal);

%Postfiltrado para modo Horizontal
switch mode
    case 10 %Horizontal Puro
        for c=1:s
            PU(1,c)=PU(1,c)+ bitshift( T(c+1)-T(1) ,-1,'int32'); 
        end
    case 26 %Vertical Puro
        for r=1:s
            PU(r,1)=PU(r,1)+ bitshift( L(r+1)-L(1) ,-1,'int32'); 
        end
    case 35 %DC
        % Predicted DC value. Three-tap filter applied [1 2 1]/4
        PU(1,1)=bitshift(L(2) + 2*dcVal + T(2) + 2,-2,'int32');
        for i=2:s
            PU(1,i)=bitshift(3*dcVal + T(i+1) + 2,-2,'int32');
            PU(i,1)=bitshift(3*dcVal + L(i+1) + 2,-2,'int32');
        end
        PU(2:s,2:s)=dcVal;
end %switch

end