function [ Y, U, V ] = GetYuvFrame( yuvSequence, width, height, frameNum)

dims=[width, height];

[Y,U,V]=yuv_import(yuvSequence,dims,1,frameNum-1,'YUV420_8');
Y=Y{1};
U=U{1};
V=V{1};

end


function n= NumFramesOfSequence(yuvSequence, width, height)

dims=[width, height];
dimsUV = dims / 2;
Yd = zeros(dims);
UVd = zeros(dimsUV);
frelem = numel(Yd) + 2*numel(UVd);

fid = fopen(yuvSequence,'r');
fseek(fid,0,'eof');
n = ftell(fid)/frelem;                   % frame numbers of the file
fclose(fid);
end
