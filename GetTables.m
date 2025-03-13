function [ M_Mat, Quant_Mat, Weights_Mat ] = GetTables( TempSize )
    switch TempSize
        case 0 % Todos los modos en arrays
            M_Mat=[1:4];
            Quant_Mat=[1:4];
            Weights_Mat=[1:4];
        case 4
            M_Mat = 1;
            Quant_Mat = 1;
            Weights_Mat = 1;
        case 8
            M_Mat = 2;
            Quant_Mat = 2;
            Weights_Mat = 2;
        case 16
            M_Mat = 3;
            Quant_Mat = 3;
            Weights_Mat = 3;
        case 32
            M_Mat = 4;
            Quant_Mat = 4;
            Weights_Mat = 4;
        otherwise
            error('GetTables: Unsupported matrix Size');
    end
end

