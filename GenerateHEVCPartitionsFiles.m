function GenerateHEVCPartitionsFiles( ejecucion, runDir )
%GENERATEHEVCPARTITIONSFILES
%   Obtiene el .Part.dat dado por el HM_UMH

%global HM_UMH_TAppEncoder;
%global encoder_intra_main;
%global save_HM_binary;
%global save_HM_output;

if is64bitComputer()
    HM_UMH_TAppEncoder = [ getPWD() '\tools\TAppEncoder_x64.exe'];
else
    HM_UMH_TAppEncoder = [ getPWD() '\tools\TAppEncoder_x32.exe'];
end
encoder_intra_main = [ getPWD() '\encoder_intra_main.cfg'];
save_HM_binary = true;
save_HM_output = true;

yuvSequenceName = ejecucion{1};
[~,yuvSequenceBasename,~] = fileparts(yuvSequenceName);
frames = ejecucion{2};
WeightMode = ejecucion{10};
Qp = ejecucion{7};
width = ejecucion{3};
height = ejecucion{4};
mode = ejecucion{6};

framerate = 30; % No importa este valor ya que solo queremos generar el particionado QuadTree

SAO = 0;
dDB = 1;
RDOQ = 0;
RDOQTS = 0;
TRSKP = 0;
TRSKPFST = 0;
SBH = 0;

MSK = 0;
CSF = 0;
SCL = 0;

if any(strcmp({'staCSF','CSF'},WeightMode))
    SCL = 1;
end
if any(strcmp({'ourCSF','CSF'},WeightMode))
    CSF = 1;
end

if ~exist(runDir, 'dir')
    mkdir(runDir);
end
if ~exist(sprintf('%s\\%s',runDir,yuvSequenceBasename), 'dir')
    mkdir(sprintf('%s\\%s',runDir,yuvSequenceBasename));
end
if ~exist(sprintf('%s\\%s\\%s',runDir,yuvSequenceBasename,mode), 'dir')
    mkdir(sprintf('%s\\%s\\%s',runDir,yuvSequenceBasename,mode));
end

for i=1:numel(frames)
    frame = frames(i);
    
    % Cada frame se guarda en un fichero donde se añade el numero de frame al nombre de la secuencia
    yuvFrame=sprintf('%s\\%s\\%s_%03d.yuv',runDir,yuvSequenceBasename,yuvSequenceBasename,frame);
    if ~exist(yuvFrame,'file')
        [ Y, U, V ] = GetYuvFrame( yuvSequenceName, width, height, frame);
        SaveYuv(yuvFrame,'w',Y,U,V);
    end
    
    dat_new_name = sprintf('%s\\%s\\%s\\%s_%03d_qp%d_%s.Part.dat',runDir,yuvSequenceBasename,mode,yuvSequenceBasename,frame,Qp,WeightMode);
    if exist(dat_new_name, 'file') == 2
        continue;
    end
    
    dat_name = sprintf('%s\\%s_%03d_SCL%d_CSF%d_MSK%d_SAO%d_dDB%d_QP%d_RDOQ%d_RDOQTS%d_TRSKP%d_TRSKPFST%d_SBH%d.Part.dat',getPWD(),yuvSequenceBasename,frame,SCL,CSF,MSK,SAO,dDB,Qp,RDOQ,RDOQTS,TRSKP,TRSKPFST,SBH);
    if exist(dat_name, 'file') == 2
        % Si existe debemos eliminarlo, ya que HM coge ese fichero y concatena !!
        delete(dat_name);
    end
    
    if save_HM_binary == true
        binary_filename = sprintf('%s\\%s\\%s\\%s_%03d_qp%d_%s.hevc',runDir,yuvSequenceBasename,mode,yuvSequenceBasename,frame,Qp,WeightMode);
    else
        binary_filename = 'nul';
    end
    
    if save_HM_output == true
        output_filename = sprintf('%s\\%s\\%s\\%s_%03d_qp%d_%s.yuv',runDir,yuvSequenceBasename,mode,yuvSequenceBasename,frame,Qp,WeightMode);
    else
        output_filename = 'nul';
    end
    
    command = sprintf('%s -c %s -i %s -f 1 -fs 0 -fr %d -wdt %d -hgt %d -SL %d -CSF %d -MSK %d -SAO %d -dDB %d -q %d -rdoq %d -rdoqts %d -trskp %d -trskpfst %d -SBH %d -exPart 1 -b %s -o %s',HM_UMH_TAppEncoder,encoder_intra_main,yuvFrame,framerate,width,height,SCL,CSF,MSK,SAO,dDB,Qp,RDOQ,RDOQTS,TRSKP,TRSKPFST,SBH,binary_filename,output_filename);
    [status,~]=system(command);
    assert(status==0)
    
    movefile(dat_name,dat_new_name)
end

end
