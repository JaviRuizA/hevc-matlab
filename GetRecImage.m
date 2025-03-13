function [RecImage]=GetRecImage(PUCREC)
[pr,pc]=size(PUCREC);
s=size(PUCREC{1,1},1);
ir=pr*s;
ic=pc*s;
RecImage=zeros(ir,ic);
for r=1:pr
    ixr=r*s-(s-1);
    for c=1:pc
        ixc=c*s-(s-1);
        block=PUCREC{r,c};
        RecImage(ixr:ixr+s-1,ixc:ixc+s-1)=block;
    end
end
end

