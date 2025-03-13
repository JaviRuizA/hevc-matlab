
function [coefs] = HEVC_Transformation( bitDetpth, tMat, src )
%src=ones(32,32)*-256;
iHeight=size(src,1);
iWidth=size(src,2);
M=log2(size(src,1)); %Asumimos Bloques cuadradros

Shift1 = M - 1 + bitDetpth-8;
Shift2 = M + 6;

rBlock=reshape(src',1,numel(src));
tmp=zeros(1,numel(rBlock));

switch iWidth
    case 4
         tmp  =fastForwardDst(rBlock,Shift1);
         coefs=fastForwardDst(tmp   ,Shift2);
    case 8
         tmp  =partialButterfly8(rBlock,Shift1,iHeight,tMat);
         coefs=partialButterfly8(tmp,Shift2,iWidth,tMat);
    case 16
         tmp  =partialButterfly16(rBlock,Shift1,iHeight,tMat);
         coefs=partialButterfly16(tmp,Shift2,iWidth,tMat);
    case 32
        tmp  =partialButterfly32(rBlock,Shift1,iHeight,tMat);
        coefs=partialButterfly32(tmp,Shift2,iWidth,tMat);
    otherwise
        error('HEVC_Transormation: Tamaño incorrecto de bloque');
end

coefs=reshape(coefs,iHeight,iWidth)';

end

function coeff = fastForwardDst(rBlock,shift)
    c=zeros(1,4);
    rnd_factor = bitshift(1,shift-1,'int32');
    
    coeff=zeros(1,4^2);
    for i=1:4
        %Intermediate Variables
        c(1) = rBlock(4*(i-1)+0+1) + rBlock(4*(i-1)+3+1);
        c(2) = rBlock(4*(i-1)+1+1) + rBlock(4*(i-1)+3+1);
        c(3) = rBlock(4*(i-1)+0+1) - rBlock(4*(i-1)+1+1);
        c(4) = 74*rBlock(4*(i-1)+2+1);
        
        coeff(   i) = bitshift(29*c(1) + 55*c(2) + c(4) + rnd_factor,-shift,'int64');
        coeff( 4+i) = bitshift(74*(rBlock(4*(i-1)+0+1)+rBlock(4*(i-1)+1+1)-rBlock(4*(i-1)+3+1))+rnd_factor,-shift,'int64');
        coeff( 8+i) = bitshift(29*c(3) + 55*c(1) - c(4) + rnd_factor,-shift,'int64');
        coeff(12+i) = bitshift(55*c(3) - 29*c(2) + c(4) + rnd_factor,-shift,'int64');
    end
end

function dst = partialButterfly8(rSrc,shift,line,aiT8)
    E=zeros(1,4);    O=zeros(1,4);
    EE=zeros(1,2);    EO=zeros(1,2);
    
    if shift > 0
        addVal=bitshift(1,shift-1,'int32');
    else
        addVal=0;
    end

    dst=zeros(1,line^2);
    ixSrc=1;
    ixDst=1;

    for j=1:line
        src=rSrc(ixSrc:ixSrc+7);

        % E and O
        for k=1:4
            E(k)=src(k)+src(8-k+1);
            O(k)=src(k)-src(8-k+1);
        end
        % EE and EO
        EE(1)=E(1)+E(4);
        EO(1)=E(1)-E(4);
        EE(2)=E(2)+E(3);
        EO(2)=E(2)-E(3);

        dstDin=dst(1,ixDst:end);

        dstDin(0*line+1)=bitshift(aiT8(1,1)*EE(1) + aiT8(1,2)*EE(2) + addVal,-shift,'int32');
        dstDin(4*line+1)=bitshift(aiT8(5,1)*EE(1) + aiT8(5,2)*EE(2) + addVal,-shift,'int32');
        dstDin(2*line+1)=bitshift(aiT8(3,1)*EO(1) + aiT8(3,2)*EO(2) + addVal,-shift,'int32');
        dstDin(6*line+1)=bitshift(aiT8(7,1)*EO(1) + aiT8(7,2)*EO(2) + addVal,-shift,'int32');
        
%         for k=2:4:15
%             dstDin(k*line+1)=bitshift(aiT8(k+1,1)*EO(1)+aiT8(k+1,2)*EO(2)+ ...
%                                       aiT8(k+1,3)*EO(3)+aiT8(k+1,4)*EO(4)+ ... 
%                                       addVal,-shift,'int32');
%         end

        dstDin(1*line+1)=bitshift(aiT8(2,1)*O(1)+aiT8(2,2)*O(2)+ ...
                                  aiT8(2,3)*O(3)+aiT8(2,4)*O(4)+ ... 
                                  addVal,-shift,'int32');
        dstDin(3*line+1)=bitshift(aiT8(4,1)*O(1)+aiT8(4,2)*O(2)+ ...
                                  aiT8(4,3)*O(3)+aiT8(4,4)*O(4)+ ... 
                                  addVal,-shift,'int32');
        dstDin(5*line+1)=bitshift(aiT8(6,1)*O(1)+aiT8(6,2)*O(2)+ ...
                                  aiT8(6,3)*O(3)+aiT8(6,4)*O(4)+ ... 
                                  addVal,-shift,'int32');
        dstDin(7*line+1)=bitshift(aiT8(8,1)*O(1)+aiT8(8,2)*O(2)+ ...
                                  aiT8(8,3)*O(3)+aiT8(8,4)*O(4)+ ... 
                                  addVal,-shift,'int32');
        
        ixSrc=ixSrc+8;
        dst(1,ixDst:end)=dstDin;
        ixDst=ixDst+1;
    end
    
end


function dst = partialButterfly16(rSrc,shift,line,aiT16)
    E=zeros(1,8);    O=zeros(1,8);
    EE=zeros(1,4);    EO=zeros(1,4);
    EEE=zeros(1,2);   EEO=zeros(1,2);
    
    if shift > 0
        addVal=bitshift(1,shift-1,'int32');
    else
        addVal=0;
    end

    dst=zeros(1,line^2);
    ixSrc=1;
    ixDst=1;

    for j=1:line
        src=rSrc(ixSrc:ixSrc+15);

        % E and O
        for k=1:8
            E(k)=src(k)+src(16-k+1);
            O(k)=src(k)-src(16-k+1);
        end
        % EE and EO
        for k=1:4
            EE(k)=E(k)+E(8-k+1);
            EO(k)=E(k)-E(8-k+1);
        end
        % EEE and EEO
        EEE(1)=EE(1)+EE(4);
        EEO(1)=EE(1)-EE(4);
        EEE(2)=EE(2)+EE(3);
        EEO(2)=EE(2)-EE(3);

        dstDin=dst(1,ixDst:end);

        dstDin( 0*line+1)=bitshift(aiT16( 1,1)*EEE(1) + aiT16( 1,2)*EEE(2) + addVal,-shift,'int32');
        dstDin( 8*line+1)=bitshift(aiT16( 9,1)*EEE(1) + aiT16( 9,2)*EEE(2) + addVal,-shift,'int32');
        dstDin( 4*line+1)=bitshift(aiT16( 5,1)*EEO(1) + aiT16( 5,2)*EEO(2) + addVal,-shift,'int32');
        dstDin(12*line+1)=bitshift(aiT16(13,1)*EEO(1) + aiT16(13,2)*EEO(2) + addVal,-shift,'int32');
        
        for k=2:4:15
            dstDin(k*line+1)=bitshift(aiT16(k+1,1)*EO(1)+aiT16(k+1,2)*EO(2)+ ...
                                      aiT16(k+1,3)*EO(3)+aiT16(k+1,4)*EO(4)+ ... 
                                      addVal,-shift,'int32');
        end

        for k=1:2:15
            dstDin(k*line+1)=bitshift(aiT16(k+1,1)*O(1)+aiT16(k+1,2)*O(2)+ ...
                                      aiT16(k+1,3)*O(3)+aiT16(k+1,4)*O(4)+ ... 
                                      aiT16(k+1,5)*O(5)+aiT16(k+1,6)*O(6)+ ... 
                                      aiT16(k+1,7)*O(7)+aiT16(k+1,8)*O(8)+ ... 
                                      addVal,-shift,'int32');
        end

        ixSrc=ixSrc+16;
        dst(1,ixDst:end)=dstDin;
        ixDst=ixDst+1;
        
    end
    
end

function dst = partialButterfly32(rSrc,shift,line,aiT32)
    E=zeros(1,16);    O=zeros(1,16);
    EE=zeros(1,8);    EO=zeros(1,8);
    EEE=zeros(1,4);   EEO=zeros(1,4);
    EEEE=zeros(1,2);  EEEO=zeros(1,2);
    
    if shift > 0
        addVal=bitshift(1,shift-1,'int32');
    else
        addVal=0;
    end
    
    dst=zeros(1,line^2);
    ixSrc=1;
    ixDst=1;
    
    for j=1:line
        %fprintf('j=%d ixSrc=%d  line=%d\n',j,ixSrc,j);
        
        src=rSrc(ixSrc:ixSrc+31);
        
        % E and O
        for k=1:16
            E(k)=src(k)+src(32-k+1);
            O(k)=src(k)-src(32-k+1);
        end
        % EE and EO
        for k=1:8
            EE(k)=E(k)+E(16-k+1);
            EO(k)=E(k)-E(16-k+1);
        end
        % EEE and EEO
        for k=1:4
            EEE(k)=EE(k)+EE(8-k+1);
            EEO(k)=EE(k)-EE(8-k+1);
        end
        % EEEE and EEEO
        EEEE(1)=EEE(1)+EEE(4);
        EEEO(1)=EEE(1)-EEE(4);
        EEEE(2)=EEE(2)+EEE(3);
        EEEO(2)=EEE(2)-EEE(3);
        
        dstDin=dst(1,ixDst:end);
        
        dstDin( 0*line+1)=bitshift(aiT32(1 ,1)*EEEE(1) + aiT32(1 ,2)*EEEE(2) + addVal,-shift,'int32');
        dstDin(16*line+1)=bitshift(aiT32(17,1)*EEEE(1) + aiT32(17,2)*EEEE(2) + addVal,-shift,'int32');
        dstDin( 8*line+1)=bitshift(aiT32(9 ,1)*EEEO(1) + aiT32(9 ,2)*EEEO(2) + addVal,-shift,'int32');
        dstDin(24*line+1)=bitshift(aiT32(25,1)*EEEO(1) + aiT32(25,2)*EEEO(2) + addVal,-shift,'int32');
        
        for k=4:8:31
            dstDin(k*line+1)=bitshift(aiT32(k+1,1)*EEO(1)+aiT32(k+1,2)*EEO(2)+ ...
                                    aiT32(k+1,3)*EEO(3)+aiT32(k+1,4)*EEO(4)+addVal,-shift,'int32');
        end
        
        for k=2:4:31
            dstDin(k*line+1)=bitshift(aiT32(k+1,1)*EO(1)+aiT32(k+1,2)*EO(2)+aiT32(k+1,3)*EO(3)+aiT32(k+1,4)*EO(4)+ ... 
                                    aiT32(k+1,5)*EO(5)+aiT32(k+1,6)*EO(6)+aiT32(k+1,7)*EO(7)+aiT32(k+1,8)*EO(8)+addVal,-shift,'int32');
            
        end
        
        for k=1:2:31
            dstDin(k*line+1)=bitshift(aiT32(k+1, 1)*O( 1)+aiT32(k+1, 2)*O( 2)+aiT32(k+1, 3)*O( 3)+aiT32(k+1, 4)*O( 4)+ ... 
                                    aiT32(k+1, 5)*O( 5)+aiT32(k+1, 6)*O( 6)+aiT32(k+1, 7)*O( 7)+aiT32(k+1, 8)*O( 8)+ ...
                                    aiT32(k+1, 9)*O( 9)+aiT32(k+1,10)*O(10)+aiT32(k+1,11)*O(11)+aiT32(k+1,12)*O(12)+ ...
                                    aiT32(k+1,13)*O(13)+aiT32(k+1,14)*O(14)+aiT32(k+1,15)*O(15)+aiT32(k+1,16)*O(16)+addVal,-shift,'int32');
            
        end
       
        ixSrc=ixSrc+32;
        dst(1,ixDst:end)=dstDin;
        ixDst=ixDst+1;
    end
    
end

