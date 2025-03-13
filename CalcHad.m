function [ sad ] = CalcHad( oBlock, pBlock)

[r,c]=size(oBlock);
pusize=r;
if (pusize==4)
    sad=CalcHad4(oBlock,pBlock);
else
    switch pusize
        case 8
            sad=CalcHad8(oBlock,pBlock);
        otherwise
            sad=0;
            numParts=pusize/8;
            for r=1:numParts
                for c=1:numParts
                    rinit=8*(r-1)+1;
                    cinit=8*(c-1)+1;
                    rend=rinit+8-1;
                    cend=cinit+8-1;
                    oPart=oBlock(rinit:rend,cinit:cend);
                    pPart=pBlock(rinit:rend,cinit:cend);
                    sad=sad+CalcHad8(oPart,pPart);
                end
            end
    end
end
end

function [ sad ] = CalcHad8( oBlock, pBlock)

m1=zeros(8);
m2=zeros(8);
m3=zeros(8);

%diferencias
diff=oBlock-pBlock;
diff=reshape(diff',1,64);

%horizontal
for c=1:8
    cc=bitshift(c-1,3)+1;
    m2(c,1)=diff(cc  )+diff(cc+4);
    m2(c,2)=diff(cc+1)+diff(cc+5);
    m2(c,3)=diff(cc+2)+diff(cc+6);
    m2(c,4)=diff(cc+3)+diff(cc+7);
    m2(c,5)=diff(cc  )-diff(cc+4);
    m2(c,6)=diff(cc+1)-diff(cc+5);
    m2(c,7)=diff(cc+2)-diff(cc+6);
    m2(c,8)=diff(cc+3)-diff(cc+7);

    m1(c,1)=m2(c,1)+m2(c,3);
    m1(c,2)=m2(c,2)+m2(c,4);
    m1(c,3)=m2(c,1)-m2(c,3);
    m1(c,4)=m2(c,2)-m2(c,4);
    m1(c,5)=m2(c,5)+m2(c,7);
    m1(c,6)=m2(c,6)+m2(c,8);
    m1(c,7)=m2(c,5)-m2(c,7);
    m1(c,8)=m2(c,6)-m2(c,8);
    
    m2(c,1)=m1(c,1)+m1(c,2);
    m2(c,2)=m1(c,1)-m1(c,2);
    m2(c,3)=m1(c,3)+m1(c,4);
    m2(c,4)=m1(c,3)-m1(c,4);
    m2(c,5)=m1(c,5)+m1(c,6);
    m2(c,6)=m1(c,5)-m1(c,6);
    m2(c,7)=m1(c,7)+m1(c,8);
    m2(c,8)=m1(c,7)-m1(c,8);
end

%vertical
for r=1:8
    m3(1,r)=m2(1,r)+m2(5,r);
    m3(2,r)=m2(2,r)+m2(6,r);
    m3(3,r)=m2(3,r)+m2(7,r);
    m3(4,r)=m2(4,r)+m2(8,r);
    m3(5,r)=m2(1,r)-m2(5,r);
    m3(6,r)=m2(2,r)-m2(6,r);
    m3(7,r)=m2(3,r)-m2(7,r);
    m3(8,r)=m2(4,r)-m2(8,r);

    m1(1,r)=m3(1,r)+m3(3,r);
    m1(2,r)=m3(2,r)+m3(4,r);
    m1(3,r)=m3(1,r)-m3(3,r);
    m1(4,r)=m3(2,r)-m3(4,r);
    m1(5,r)=m3(5,r)+m3(7,r);
    m1(6,r)=m3(6,r)+m3(8,r);
    m1(7,r)=m3(5,r)-m3(7,r);
    m1(8,r)=m3(6,r)-m3(8,r);

    m2(1,r)=m1(1,r)+m1(2,r);
    m2(2,r)=m1(1,r)-m1(2,r);
    m2(3,r)=m1(3,r)+m1(4,r);
    m2(4,r)=m1(3,r)-m1(4,r);
    m2(5,r)=m1(5,r)+m1(6,r);
    m2(6,r)=m1(5,r)-m1(6,r);
    m2(7,r)=m1(7,r)+m1(8,r);
    m2(8,r)=m1(7,r)-m1(8,r);
end

sad=sum(sum(abs(m2)));

sad=bitshift(sad+2,-2);

end



function [ sad ] = CalcHad4( oBlock, pBlock)

m=zeros(16,1);
d=zeros(16,1);

%diferencias
diff=oBlock-pBlock;
diff=reshape(diff',1,16);

m( 1)=diff(1)+diff(13);
m( 2)=diff(2)+diff(14);
m( 3)=diff(3)+diff(15);
m( 4)=diff(4)+diff(16);
m( 5)=diff(5)+diff( 9);
m( 6)=diff(6)+diff(10);
m( 7)=diff(7)+diff(11);
m( 8)=diff(8)+diff(12);
m( 9)=diff(5)-diff( 9);
m(10)=diff(6)-diff(10);
m(11)=diff(7)-diff(11);
m(12)=diff(8)-diff(12);
m(13)=diff(1)-diff(13);
m(14)=diff(2)-diff(14);
m(15)=diff(3)-diff(15);
m(16)=diff(4)-diff(16);

d( 1)=m( 1)+m( 5);
d( 2)=m( 2)+m( 6);
d( 3)=m( 3)+m( 7);
d( 4)=m( 4)+m( 8);
d( 5)=m( 9)+m(13);
d( 6)=m(10)+m(14);
d( 7)=m(11)+m(15);
d( 8)=m(12)+m(16);
d( 9)=m( 1)-m( 5);
d(10)=m( 2)-m( 6);
d(11)=m( 3)-m( 7);
d(12)=m( 4)-m( 8);
d(13)=m(13)-m( 9);
d(14)=m(14)-m(10);
d(15)=m(15)-m(11);
d(16)=m(16)-m(12);

m( 1)=d( 1)+d( 4);
m( 2)=d( 2)+d( 3);
m( 3)=d( 2)-d( 3);
m( 4)=d( 1)-d( 4);
m( 5)=d( 5)+d( 8);
m( 6)=d( 6)+d( 7);
m( 7)=d( 6)-d( 7);
m( 8)=d( 5)-d( 8);
m( 9)=d( 9)+d(12);
m(10)=d(10)+d(11);
m(11)=d(10)-d(11);
m(12)=d( 9)-d(12);
m(13)=d(13)+d(16);
m(14)=d(14)+d(15);
m(15)=d(14)-d(15);
m(16)=d(13)-d(16);

d( 1)=m( 1)+m( 2);
d( 2)=m( 1)-m( 2);
d( 3)=m( 3)+m( 4);
d( 4)=m( 4)-m( 3);
d( 5)=m( 5)+m( 6);
d( 6)=m( 5)-m( 6);
d( 7)=m( 7)+m( 8);
d( 8)=m( 8)-m( 7);
d( 9)=m( 9)+m(10);
d(10)=m( 9)-m(10);
d(11)=m(11)+m(12);
d(12)=m(12)-m(11);
d(13)=m(13)+m(14);
d(14)=m(13)-m(14);
d(15)=m(15)+m(16);
d(16)=m(16)-m(15);

sad=sum(abs(d));

sad=bitshift(sad+1,-1);

end



