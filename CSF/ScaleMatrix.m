function [sm]=ScaleMatrix(m,low,high)
    if low==high
        sm=m;
    else
        
        a=low;
        b=high;
        minM=min(min(m));
        maxM=max(max(m));
        [R,C]=size(m);
        sm=zeros(size(m));
        for r=1:R
            for c=1:C
                sm(r,c)=a+((m(r,c)-minM)*(b-a))/(maxM-minM);
            end
        end
    end
end
