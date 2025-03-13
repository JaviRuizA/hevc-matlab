function [ coefs ] = HEVC_InvTransformation(src, M_Mat, BitDepth_B)
                
%     DTrans = M_Mat';
%     INvstage1 = DTrans * InvQuant;
%     
%     INvstage2 = bitshift(fix(INvstage1),-7,'int64');
%     
%     Invstage3 = INvstage2 * M_Mat;
%     
%     Final = bitshift(Invstage3,-(20-BitDepth_B),'int32');
%     
%     ReconstructMatx = round (Final);
    
    
%     ------------------------------------------------------

iHeight=size(src,1);
iWidth=size(src,2);
% M=log2(size(src,1)); %Asumimos Bloques cuadradros

rBlock=reshape(src',1,numel(src));
tmp=zeros(1,numel(rBlock));

SHIFT_INV_1ST=7;
SHIFT_INV_2ND=12;

shift_1st=SHIFT_INV_1ST;
shift_2nd=SHIFT_INV_2ND - (BitDepth_B-8);

switch iWidth
    case 4
         tmp  =fastInverseDst(rBlock,shift_1st);
         coefs=fastInverseDst(tmp   ,shift_2nd);
    case 8
        tmp  =partialButterflyInverse8(rBlock,shift_1st,iWidth,M_Mat);
        coefs=partialButterflyInverse8(tmp,shift_2nd,iHeight,M_Mat);
    case 16
        tmp  =partialButterflyInverse16(rBlock,shift_1st,iWidth,M_Mat);
        coefs=partialButterflyInverse16(tmp,shift_2nd,iHeight,M_Mat);
    case 32
        tmp  =partialButterflyInverse32(rBlock,shift_1st,iWidth,M_Mat);
        coefs=partialButterflyInverse32(tmp,shift_2nd,iHeight,M_Mat);
    otherwise
        error('HEVC_InvTransormation: Tamaño incorrecto de bloque');
end
    
coefs=reshape(coefs,iHeight,iWidth)';

end

function rBlock = fastInverseDst(rTmp,shift)
    c=zeros(1,4);
    rnd_factor = bitshift(1,shift-1,'int32');
    
    rBlock=zeros(1,4^2);
    for i=1:4
        %Intermediate Variables
        c(1) = rTmp(  (i-1)+1) + rTmp( 8+(i-1)+1);
        c(2) = rTmp(8+(i-1)+1) + rTmp(12+(i-1)+1);
        c(3) = rTmp(  (i-1)+1) - rTmp(12+(i-1)+1);
        c(4) = 74*rTmp(4+(i-1)+1);
        
        rBlock(4*(i-1)+0+1) = Clip(bitshift(29*c(1) + 55*c(2) + c(4) + rnd_factor,-shift,'int32'));
        rBlock(4*(i-1)+1+1) = Clip(bitshift(55*c(3) - 29*c(2) + c(4) + rnd_factor,-shift,'int32'));
        rBlock(4*(i-1)+2+1) = Clip(bitshift(74*(rTmp((i-1)+1)-rTmp(8+(i-1)+1)+rTmp(12+(i-1)+1))+rnd_factor,-shift,'int32'));
        rBlock(4*(i-1)+3+1) = Clip(bitshift(55*c(1) + 29*c(3) - c(4) + rnd_factor,-shift,'int32'));

%         rBlock(4*(i-1)+0+1) = Clip((29*c(1) + 55*c(2) + c(4) + rnd_factor)/2^shift);
%         rBlock(4*(i-1)+1+1) = Clip((55*c(3) - 29*c(2) + c(4) + rnd_factor)/2^shift);
%         rBlock(4*(i-1)+2+1) = Clip((74*(rTmp((i-1)+1)-rTmp(8+(i-1)+1)+rTmp(12+(i-1)+1))+rnd_factor)/2^shift);
%         rBlock(4*(i-1)+3+1) = Clip((55*c(1) + 29*c(3) - c(4) + rnd_factor)/2^shift);
% 
    end
end

function dst = partialButterflyInverse8(rSrc,shift,line,aiT8)
    E=zeros(1,4);     O=zeros(1,4);
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
        src=rSrc(1,ixSrc:end);
        for k=1:4
            O(k)=aiT8( 2,k)*src( 1*line+1) + aiT8( 4,k)*src( 3*line+1) + ...
                 aiT8( 6,k)*src( 5*line+1) + aiT8( 8,k)*src( 7*line+1);
        end
        
        EO(1)=aiT8(3,1)*src(2*line+1) + aiT8(7,1)*src(6*line+1);
        EO(2)=aiT8(3,2)*src(2*line+1) + aiT8(7,2)*src(6*line+1);
        EE(1)=aiT8(1,1)*src(       1) + aiT8(5,1)*src(4*line+1);
        EE(2)=aiT8(1,2)*src(       1) + aiT8(5,2)*src(4*line+1);

        E(1) = EE(1) + EO(1);
        E(4) = EE(1) - EO(1);
        E(2) = EE(2) + EO(2);
        E(3) = EE(2) - EO(2);
        
        dstDin=dst(ixDst:ixDst+7);
        
        for k=1:4
            dstDin(k)  =Clip(bitshift( E(k    ) + O(k    ) + addVal,-shift,'int32'));
            dstDin(k+4)=Clip(bitshift (E(4-k+1) - O(4-k+1) + addVal,-shift,'int32'));
        end
        
        dst(1,ixDst:ixDst+7)=dstDin;
        ixSrc=ixSrc+1;
        ixDst=ixDst+8;
    end
end



function dst = partialButterflyInverse16(rSrc,shift,line,aiT16)
    E=zeros(1,8);     O=zeros(1,8);
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
        src=rSrc(1,ixSrc:end);
        for k=1:8
            O(k)=aiT16( 2,k)*src( 1*line+1) + aiT16( 4,k)*src( 3*line+1) + ...
                 aiT16( 6,k)*src( 5*line+1) + aiT16( 8,k)*src( 7*line+1) + ...
                 aiT16(10,k)*src( 9*line+1) + aiT16(12,k)*src(11*line+1) + ...
                 aiT16(14,k)*src(13*line+1) + aiT16(16,k)*src(15*line+1);
        end
        for k=1:4
            EO(k)=aiT16( 3,k)*src( 2*line+1) + aiT16( 7,k)*src( 6*line+1) + ...
                  aiT16(11,k)*src(10*line+1) + aiT16(15,k)*src(14*line+1);
        end
        
        EEO(1)=aiT16( 5,1)*src(4*line+1) + aiT16(13,1)*src(12*line+1);
        EEE(1)=aiT16( 1,1)*src(       1) + aiT16( 9,1)*src( 8*line+1);
        EEO(2)=aiT16( 5,2)*src(4*line+1) + aiT16(13,2)*src(12*line+1);
        EEE(2)=aiT16( 1,2)*src(       1) + aiT16( 9,2)*src( 8*line+1);

        for k=1:2
            EE(k)  =EEE(k)     + EEO(k);
            EE(k+2)=EEE(2-k+1) - EEO(2-k+1);
        end
        
        for k=1:4
            E(k  )=EE(k    ) + EO(k);
            E(k+4)=EE(4-k+1) - EO(4-k+1);
        end
        
        dstDin=dst(ixDst:ixDst+15);
        
        for k=1:8
            dstDin(k)  =Clip(bitshift( E(k    ) + O(k    ) + addVal,-shift,'int32'));
            dstDin(k+8)=Clip(bitshift (E(8-k+1) - O(8-k+1) + addVal,-shift,'int32'));
        end
        
        dst(1,ixDst:ixDst+15)=dstDin;
        ixSrc=ixSrc+1;
        ixDst=ixDst+16;

    end
    
end


function dst = partialButterflyInverse32(rSrc,shift,line,aiT32)
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
        src=rSrc(1,ixSrc:end);
        
        for k=1:16
            O(k)=aiT32( 2,k)*src( 1*line+1) + aiT32( 4,k)*src( 3*line+1) + ...
                 aiT32( 6,k)*src( 5*line+1) + aiT32( 8,k)*src( 7*line+1) + ...
                 aiT32(10,k)*src( 9*line+1) + aiT32(12,k)*src(11*line+1) + ...
                 aiT32(14,k)*src(13*line+1) + aiT32(16,k)*src(15*line+1) + ...
                 aiT32(18,k)*src(17*line+1) + aiT32(20,k)*src(19*line+1) + ...
                 aiT32(22,k)*src(21*line+1) + aiT32(24,k)*src(23*line+1) + ...
                 aiT32(26,k)*src(25*line+1) + aiT32(28,k)*src(27*line+1) + ...
                 aiT32(30,k)*src(29*line+1) + aiT32(32,k)*src(31*line+1);
        end
        for k=1:8
            EO(k)=aiT32( 3,k)*src( 2*line+1) + aiT32( 7,k)*src( 6*line+1) + ...
                  aiT32(11,k)*src(10*line+1) + aiT32(15,k)*src(14*line+1) + ...
                  aiT32(19,k)*src(18*line+1) + aiT32(23,k)*src(22*line+1) + ...
                  aiT32(27,k)*src(26*line+1) + aiT32(31,k)*src(30*line+1);
        end
        for k=1:4
            EEO(k)=aiT32( 5,k)*src( 4*line+1) + aiT32(13,k)*src(12*line+1) + ...
                   aiT32(21,k)*src(20*line+1) + aiT32(29,k)*src(28*line+1);
        end
        EEEO(1)=aiT32( 9,1)*src( 8*line+1) + aiT32(25,1)*src(24*line+1);
        EEEO(2)=aiT32( 9,2)*src( 8*line+1) + aiT32(25,2)*src(24*line+1);
        EEEE(1)=aiT32( 1,1)*src(        1) + aiT32(17,1)*src(16*line+1);
        EEEE(2)=aiT32( 1,2)*src(        1) + aiT32(17,2)*src(16*line+1);

        EEE(1)=EEEE(1)+EEEO(1);
        EEE(4)=EEEE(1)-EEEO(1);
        EEE(2)=EEEE(2)+EEEO(2);
        EEE(3)=EEEE(2)-EEEO(2);
        
        for k=1:4
            EE(k)  =EEE(k)     + EEO(k);
            EE(k+4)=EEE(4-k+1) - EEO(4-k+1);
        end
        
        for k=1:8
            E(k  )=EE(k    ) + EO(k);
            E(k+8)=EE(8-k+1) - EO(8-k+1);
        end
        
        dstDin=dst(ixDst:ixDst+31);
        for k=1:16
            dstDin(k)   =Clip(bitshift( E(k     ) + O(k     ) + addVal,-shift,'int32'));
            dstDin(k+16)=Clip(bitshift (E(16-k+1) - O(16-k+1) + addVal,-shift,'int32'));
        end
        
        dst(1,ixDst:ixDst+31)=dstDin;
        ixSrc=ixSrc+1;
        ixDst=ixDst+32;
        
    end
        
end

