function txtModo= GetTxtModo(modo)
    txtModo='';
    if (modo==1) txtModo='Planar';
    elseif (modo==35) txtModo='DC';
    elseif (modo>=2 && modo<=10) txtModo='H+';
    elseif (modo>=11 && modo<=17) txtModo='H-';
    elseif (modo>=18 && modo<=25) txtModo='V-';
    elseif (modo>=26 && modo<=34) txtModo='V+';
    end
end
