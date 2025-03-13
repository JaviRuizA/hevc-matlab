function [stream]=TranslateStream(stream)
% El signo define símbolos distintos.
% Convertimos los negativos en positivos por encima del máximo.
highest=max(stream);
new=highest+1;
for s=1:numel(stream)
    simbolo=stream(s);
    if (simbolo<0)
        simbolo=abs(simbolo)+new+1;
        stream(s)=simbolo;
    end
end

[~,simbolos]=hist(double(stream),unique(double(stream)));

for s=1:numel(stream)
    simbolo=stream(s);
    ixSimbolo=find(simbolos==simbolo);
    stream(s)=ixSimbolo;
end

end