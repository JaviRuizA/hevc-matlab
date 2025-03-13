function  [fs_pxdg, fmax_cydg, vd_cm] = GetFMax(ppi, vd_inch)
% Returns the Max frequency for the calculation of the weighting matrix
% ppi: Pixels per Inchs of the display device
% vd_inch :Visual distance in inches like watson paper "Wavelet Quantization Noise"

% r=88.7904; %My Display resolution in Pixels Per Inchs
inch2mm=25.4; %Inches to milimeters
inch2cm=2.54; %Inches to centimeters

% The limit of human spatial resolution is about 60 cycles/degree.
% This corresponds to a vdr of 300 ppi at a distance of 23 inches 

% We will use f_hvs=64 cycles/degree that corresponds to 600 ppi at 12.23 inches
% We will use f_hvs=60 cycles/degree that corresponds to 575 ppi at 12 inches

f_hvs=64;

r_pxin=ppi;
r_pxcm=ppi/inch2cm; % dvr in pixels/cm

vd_mm=vd_inch*inch2mm;  %Visual distance in milimeters
vd_cm=vd_inch*inch2cm;  %Visual distance in centimeters
vd_m=vd_mm/1000;        %Visual distance in meters


fs_pxdg=((vd_m*tand(1)*r_pxin)/0.0254);
fmax_cydg=fs_pxdg/2;

%Datos del monitor (viene de paper: wang_lee_chang_2001 y
%Gaddipatti_Machiraju_Yagel_2002
h=1920;
v=1200;
diag_inch=25.5; %Diagonal en pulgadas

%Calculamos los pixels/degree en función de:
%   la distancia v en m
%   la resolución en ppi
%con la formula 3.18 de la tesis.

px_dg=(vd_inch*tand(1)*ppi);
%Ahora con la forumla de transformación a cycles/degree 
%de Gaddipatti_Machiraju_Yagel_2002 obtenemos la frecuencia espacia fs

fi=0.5; %La frecuencia de la imagen es 0.5 pues 2 pixels son 1 ciclo.
fn=px_dg;
fs=fi*fn;


% %RESTO DEL CODIGO ES CORRECTO PERO SE COMENTA PORQUE SE HA PUESTO PARA COMPROBAR
% %Calculamos fs con la otra parte de la igualdad.
% p_diag=sqrt(h^2+v^2); % diagonal en pixels
% dotpitch=diag_inch/p_diag; % dpi (pixels(dots) per inch)
% 
% 
% % Visual distance for my monitor with dotpitch 0.0113 inch/pixel to obtain
% % 64.05 cycles/degree
% vd_inch_mymonitor=82.96; 
% 
% d=vd_inch_mymonitor/diag_inch;
% fn2=1/(asind(1/sqrt(1+d^2*(h^2+v^2))));
% fs2=fi*fn2;


end