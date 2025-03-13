function [maskingArray]=GetFrameMaskingArray( frameParts, allParts )
%GETFRAMEMASKINGARRAY( frameParts, allParts )
% Extrae del archivo frameParts en un vector unidimensional los valores de
% masking de un frame.

if ~exist('allParts','var') || isempty(allParts)
  allParts=true;
end

numCTUs=numel(frameParts);
maskingArray=[];

for ctu=1:numCTUs
    ctuParts=frameParts{ctu};
    if allParts % Procesa todos los bloques
        maskingArray = [maskingArray, ctuParts(:,9)'];
    else % No procesa los bloques 4x4
        maskingArray = [maskingArray, ctuParts(ctuParts(:,Indexes.ixTUsize) > 4, Indexes.ixMaskVal)'];
    end
end

end
