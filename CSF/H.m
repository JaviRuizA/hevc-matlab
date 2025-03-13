function [CSF]=H(f)
    CSF=2.6*(0.0192+0.114*f)*exp(-(0.114*f)^1.1);
end
