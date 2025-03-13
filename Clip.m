function [ value ] = Clip( value )
minVal=-32768;
maxVal= 32767;

value= min(max(value,minVal),maxVal);

end

