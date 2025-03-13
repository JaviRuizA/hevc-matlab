function [bps,sbs]=ZeroOrderEntropy(stream,signCoding,noDC,view,title)
    if nargin==3
        view=false;
        title='Simbols Probabilty';
    elseif nargin==4
        title='Simbols Probability';
    end
    %Stream debe ser un array unidimensional de valores sin decimales
    %Puede ser tipo de datos double, pero valores enteros.
    %Si el stream es una matriz lo pasamos a stream (array)
    [nr,nc]=size(stream);
    if nr>1 && nc>1
        stream=reshape(stream,1,numel(stream));
    end
    
    if (noDC)
        stream=stream(2:end);
    end

    %Si el signo cuenta cambiamos los simbolos negativos a simbolos por encima del maximo positivo
    if (signCoding)
        % El signo define simbolos distintos.
        % Convertimos los negativos en positivos por encima del máximo.
        highest=max(stream);
        new=highest+1;
        for s=1:numel(stream)
            simbol=stream(s);
            if (simbol<0)
                simbol=abs(simbol)+new+1;
                stream(s)=simbol;
            end
        end
    else
        % El signao no define simbolos distintos
        stream=abs(stream);
    end
    
    
    if size(stream(stream<0),2)>0
        error('Los valores del stream deben ser positivos o iguales a cero');
    end
    
    [ns]=size(stream,2);
    if ns==0
        bps=0;
        return
    end
    if (min(stream)==0)
        haszeros=true;
        mx=max(stream+1);
    else
        haszeros=false;
        mx=max(stream);
    end
    simb=zeros(1,mx);
    
    if view
        slabel={};
        for s=1:mx
            if haszeros
                label=sprintf('%d',s-1);
            else
                label=sprintf('%d',s);
            end
            slabel=[slabel; label];
        end
    end
    
    for s=1:ns
        if haszeros
            si=stream(1,s)+1;
        else
            si=stream(1,s);
        end
        simb(si)=simb(si)+1;
    end
    ps=zeros(size(simb));
    ps=simb./ns;
    %Detectamos que solo viene un único simbolo, asignamos la entropia a
    %0.08 de manera fija. Se supone que realmente será menor que eso.
    if ns==1
        bps=8;
        return
    end
    bs=zeros(size(simb));
    for s=1:size(simb,2)
        if ps(1,s)>0
            bs(1,s)=-ps(1,s)*log(ps(1,s));
        end
    end
    sbs=sum(bs);
    bps=sbs/log(2);
    if view
        figure;bar([1:mx],ps);
        set(gca,'XTick',[1:mx]);
        set(gca,'XTickLabel',slabel);
        set(gcf,'Name',title);
        bs;
    end
end