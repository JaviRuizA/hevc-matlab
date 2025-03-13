function [ mode ] = TranslateModeHM_to_Matlab(HM_mode)
%TRANSLATEMODEHM_TO_MATLAB Cambia el identificador de los modos Intra
%   El modo DC (1 en HM) es cambiado a 35
%   El modo Planar (0 en HM) es cambiado a 1

    switch HM_mode
        case 0
            mode = Indexes.ixPlanarPre;
        case 1
            mode = Indexes.ixDCPre;
        otherwise
            mode = HM_mode;
    end
end

