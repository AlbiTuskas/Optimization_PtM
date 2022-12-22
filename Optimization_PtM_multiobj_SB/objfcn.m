function [y1, y2] = objfcn(x,len,mdl,power,param)

leanIn(:,1) = x(1:len);
gasIn(:,1) = x(len+1:2*len);
hydrogenIn(:,1) = x(2*len+1:3*len);
powerIn(:,1) = x(3*len+1:4*len);
meohOut(:,1) = x(4*len+1:5*len);

mdlMassFlowMEOHProd = mdl{1};
mdlPowerRequired1 = mdl{2};
mdlPowerRequired2 = mdl{3};

%% Objective 1
% Methanol Output
%[~, sumy] = calculateMethanolProd(meohOut, mdlMassFlowMEOHProd, len);
sumy = sum(predict(mdlMassFlowMEOHProd,meohOut));
y1 = -sumy;

%% Objective 2
% Power
%[powerRequired1, ~] = calculateRequiredPowerABS_DES_SYNT(leanIn, gasIn, hydrogenIn, mdlPowerRequired1, len);
%[powerRequired2, ~] = calculateRequiredPowerDIST(meohOut,mdlPowerRequired2,len);
%powerRequired = powerRequired1 + powerRequired2;
powerRequired = predict(mdlPowerRequired1,[leanIn, gasIn, hydrogenIn]) + predict(mdlPowerRequired2,meohOut);

powerScaled = power * param.pvScale;
y2 = sum(powerScaled - (powerRequired*0.001 + powerIn));
