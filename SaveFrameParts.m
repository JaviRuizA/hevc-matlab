function SaveFrameParts(output_dir, frameParts, hevcCTUSPerFrame, RunMode, yuvSequenceBasename, width, height, frame, bitDepth,Qp,WeightMode,BestModeBy)
    filePath=sprintf('%s\\%s\\%s',output_dir,yuvSequenceBasename,RunMode);
    cellFileName=sprintf('%s_%s_%03d_frameParts_bd%02d_qp%02d_%s_bm%s',RunMode,yuvSequenceBasename,frame,bitDepth,Qp,WeightMode,BestModeBy);
    cmd=sprintf('save(''%s\\%s'',''width'',''height'',''frameParts'',''hevcCTUSPerFrame'');',filePath,cellFileName);
    eval(cmd);
end