function SaveYuv(filename,mode,Y,U,V,chrominance)
    if ~exist('chrominance','var') || isempty(chrominance)
      chrominance=true;
    end
   [fid,errmsg] = fopen(filename,mode);
   if fid~=-1
       for r=1:size(Y,1)
           fwrite(fid,Y(r,:),'uint8');
       end
       if ~chrominance
           U(:,:)=127;
           V(:,:)=127;
       end
       for r=1:size(U,1)
           fwrite(fid,U(r,:),'uint8');
       end
       for r=1:size(V,1)
           fwrite(fid,V(r,:),'uint8');
       end
       fclose(fid);
   else
       errordlg(errmsg);
   end
return