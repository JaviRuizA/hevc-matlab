function [ row,col ] = ZScan_QuadTree( idx, CTU_size )
%ZSCAN_QUADTREE Devuelve la posición inicial del TU dentro de un CTU
% a partir del archivo .dat exportado del HM

x = idx;

row = 1;
col = 1;

if CTU_size == 64
    
    x_tmp = floor((x-1)/64);

    switch x_tmp
        case 1
            col = col + 8;
        case 2
            row = row + 8;
        case 3
            row = row + 8;
            col = col + 8;
    end
    x = x - x_tmp*64;
    
end

if CTU_size >= 32
    
    x_tmp = floor((x-1)/16);

    switch x_tmp
        case 1
            col = col + 4;
        case 2
            row = row + 4;
        case 3
            row = row + 4;
            col = col + 4;
    end
    x = x - x_tmp*16;
    
end

if CTU_size >= 16
    
    x_tmp = floor((x-1)/4);

    switch x_tmp
        case 1
            col = col + 2;
        case 2
            row = row + 2;
        case 3
            row = row + 2;
            col = col + 2;
    end
    x = x - x_tmp*4;
    
end

if CTU_size >= 8

    switch x
        case 2
            col = col + 1;
        case 3
            row = row + 1;
        case 4
            row = row + 1;
            col = col + 1;
    end
    
end

% Dado que un índice corresponde aun bloque de 
row = 1 + ((row - 1) * 4);
col = 1 + ((col - 1) * 4);

end

