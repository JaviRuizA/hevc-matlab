function [dsnr, rate] = bjontegaardUMH(R1,METRIC1,R2,METRIC2,fitting_method)
%bjontegaardUMH    UMH's version of Bjontegaard metric calculation
%
%   R1,METRIC1 - RD points for curve 1
%   R2,METRIC2 - RD points for curve 2
%   fitting_method - 
%       'spline' - Cubic spline data interpolation
%       'pchip' - Piecewise Cubic Hermite Interpolating Polynomial
%       'poly3' - Polynomial curve fitting degree 3 (Bjontegaard's method)
%   mode - 
%       'dsnr' - average PSNR difference
%       'rate' - percentage of bitrate saving between data set 1 and
%                data set 2
%
%   dsnr - the calculated Bjontegaard metric ('dsnr')
%   rate - the calculated Bjontegaard metric ('rate')
%   
%   (c) 2018 Javier Ruiz
%
%%
%
%   References:
%
%   [1] G. Bjontegaard, Calculation of average PSNR differences between
%       RD-curves (VCEG-M33)
%   [2] S. Pateux, J. Jung, An excel add-in for computing Bjontegaard metric and
%       its evolution
%   [3] VCEG-M34. http://wftp3.itu.int/av-arch/video-site/0104_Aus/VCEG-M34.xls
%   [4] Bjontegaard metric calculation (BD-PSNR).
%       https://es.mathworks.com/matlabcentral/fileexchange/41749-bjontegaard-metric-calculation--bd-psnr-
%   [5] P. Hanhart, T. Ebrahimi, Calculation of average coding efficiency based on
%       subjective quality scores
%

if numel(R1) < 2 || numel(R2) < 2
    error('There should be at least two data points.')
end
if numel(R1) ~= numel(METRIC1)
    error('Data points 1 must have the same length')
end
if numel(R2) ~= numel(METRIC2)
    error('Data points 2 must have the same length')
end

figure_plot = false;

if figure_plot
    figure(1);
    plot(R1,METRIC1,R2,METRIC2);
    title('RD Curves');legend('RD1','RD2','Location','southeast');
    xlabel('Rate');ylabel('Metric');
end

% convert rates in logarithmic units
R1 = log10(R1);
R2 = log10(R2);

% Generating RD curve functions by interpolation
if strcmpi(fitting_method, 'spline')
    function_RD1_dsnr = spline(R1, METRIC1);
    function_RD2_dsnr = spline(R2, METRIC2);
    function_RD1_rate = spline(METRIC1, R1);
    function_RD2_rate = spline(METRIC2, R2);
elseif strcmpi(fitting_method, 'pchip')
    function_RD1_dsnr = pchip(R1, METRIC1);
    function_RD2_dsnr = pchip(R2, METRIC2);
    function_RD1_rate = pchip(METRIC1, R1);
    function_RD2_rate = pchip(METRIC2, R2);
elseif strcmpi(fitting_method, 'poly3')
    coefs_RD1 = polyfit(R1, METRIC1, 3);
    coefs_RD2 = polyfit(R2, METRIC2, 3);
    coefs_RATE1 = polyfit(METRIC1, R1, 3);
    coefs_RATE2 = polyfit(METRIC2, R2, 3);
else
    error('No valid fitting method detected: [%s]', fitting_method);
end

% Setting interpolation points
samplingRateIncrease = 40000;

% Integration interval
min_R = max(min(R1),min(R2));
max_R = min(max(R1),max(R2));
min_METRIC = max(min(METRIC1),min(METRIC2));
max_METRIC = min(max(METRIC1),max(METRIC2));

newRSamplePoints = unique([ linspace(min_R,max_R,samplingRateIncrease) R1(R1 > min_R & R1 < max_R) R2(R2 > min_R & R2 < max_R) ], 'sorted');
newMETRICSamplePoints = unique([ linspace(min_METRIC,max_METRIC,samplingRateIncrease) METRIC1(METRIC1 > min_METRIC & METRIC1 < max_METRIC) METRIC2(METRIC2 > min_METRIC & METRIC2 < max_METRIC) ], 'sorted');

if strcmpi(fitting_method, 'poly3')
    % Calculated only to plot figure 2 or to use trapz integral method
    smoothedMETRIC1 = polyval(coefs_RD1, newRSamplePoints);
    smoothedMETRIC2 = polyval(coefs_RD2, newRSamplePoints);
    smoothedR1 = polyval(coefs_RATE1, newMETRICSamplePoints);
    smoothedR2 = polyval(coefs_RATE2, newMETRICSamplePoints);
else
    smoothedMETRIC1 = ppval(function_RD1_dsnr, newRSamplePoints);
    smoothedMETRIC2 = ppval(function_RD2_dsnr, newRSamplePoints);
    smoothedR1 = ppval(function_RD1_rate, newMETRICSamplePoints);
    smoothedR2 = ppval(function_RD2_rate, newMETRICSamplePoints);
end

if figure_plot
    figure(2);
    plot(newRSamplePoints,smoothedMETRIC1,'-r',newRSamplePoints,smoothedMETRIC2,'-b',R1,METRIC1,'*r',R2,METRIC2,'*b');
    title(['RD Curve Fitting using ' fitting_method]);legend('RD1 points','RD2 points','RD1 fitting to integral dsnr','RD2 fitting to integral dsnr','Location','southeast');
    xlabel('Log_{10}(Rate)');ylabel('Metric');
    figure(3);
    plot(smoothedR1,newMETRICSamplePoints,'-r',smoothedR2,newMETRICSamplePoints,'-b',R1,METRIC1,'*r',R2,METRIC2,'*b');
    title(['RD Curve Fitting using ' fitting_method]);legend('RD1 points','RD2 points','RD1 fitting to integral rate','RD2 fitting to integral rate','Location','southeast');
    xlabel('Log_{10}(Rate)');ylabel('Metric');
    figure(4)
    plot(10.^(newRSamplePoints),smoothedMETRIC1,'-r',10.^(newRSamplePoints),smoothedMETRIC2,'-b',10.^(R1),METRIC1,'*r',10.^(R2),METRIC2,'*b');
    title(['RD Curve Fitting using ' fitting_method]);legend('RD1 points','RD2 points','RD1 fitting to integral dsnr','RD2 fitting to integral dsnr','Location','southeast');
    xlabel('Rate');ylabel('Metric');
    figure(5);
    plot(10.^(smoothedR1),newMETRICSamplePoints,'-r',10.^(smoothedR2),newMETRICSamplePoints,'-b',10.^(R1),METRIC1,'*r',10.^(R2),METRIC2,'*b');
    title(['RD Curve Fitting using ' fitting_method]);legend('RD1 points','RD2 points','RD1 fitting to integral rate','RD2 fitting to integral rate','Location','southeast');
    xlabel('Rate');ylabel('Metric');
end

% Calculating integral
if strcmpi(fitting_method, 'poly3')
    % ... by using second fundamental theorem of calculus
    RD_int1 = polyint(coefs_RD1); % Integral function of RD1
    RD_int2 = polyint(coefs_RD2); % Integral function of RD2
    
    area_RD1 = polyval(RD_int1, max_R) - polyval(RD_int1, min_R);
    area_RD2 = polyval(RD_int2, max_R) - polyval(RD_int2, min_R);
    
    RATE_int1 = polyint(coefs_RATE1);
    RATE_int2 = polyint(coefs_RATE2);
    area_RATE1 = polyval(RATE_int1, max_METRIC) - polyval(RATE_int1, min_METRIC);
    area_RATE2 = polyval(RATE_int2, max_METRIC) - polyval(RATE_int2, min_METRIC);
else
    % ... by using Trapezoidal numerical integration
    % NOTE: this method can be also used by 'poly3' mode, returning the
    % same result
    area_RD1 = trapz(newRSamplePoints, smoothedMETRIC1);
    area_RD2 = trapz(newRSamplePoints, smoothedMETRIC2);
    
    area_RATE1 = trapz(newMETRICSamplePoints, smoothedR1);
    area_RATE2 = trapz(newMETRICSamplePoints, smoothedR2);
end

% Calculating DSNR and RATE
dsnr = ( area_RD2 - area_RD1 ) / ( max_R - min_R );

rate_10 = ( area_RATE2 - area_RATE1 ) / ( max_METRIC - min_METRIC );
rate = (( 10 ^ rate_10 ) - 1 )*100;

end