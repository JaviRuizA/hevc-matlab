function SaveMat(output_dir,RunMode, yuvSequenceBasename, frame, vname, v, bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy)
    filePath=sprintf('%s\\%s\\%s',output_dir,yuvSequenceBasename,RunMode);
    eval(sprintf('%s=v;',vname));
    cellFileName=sprintf('%s_%s_%03d_%s_bd%02d_ctu%02d_l%1d_qp%02d_%s_bm%s',RunMode,yuvSequenceBasename,frame,vname,bitDepth,ctuSize,nLevels,Qp,WeightMode,BestModeBy);
    cmd=sprintf('save(''%s\\%s'',''%s'');',filePath,cellFileName,vname);
    eval(cmd);
end