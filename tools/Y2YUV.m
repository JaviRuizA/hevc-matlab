function  [Y,U,V]=Y2YUV(Y)
   [r,c]=size(Y);
   U=uint8(zeros(r/2,c/2));
   V=uint8(zeros(r/2,c/2));
   U(:,:)=127;
   V(:,:)=127;
end