function [c, ceq] = confcn(x,len,mdl,power,param)

leanIn(:,1) = x(1:len);
gasIn(:,1) = x(len+1:2*len);
hydrogenIn(:,1) = x(2*len+1:3*len);
powerIn(:,1) = x(3*len+1:4*len);
meohOut(:,1) = x(4*len+1:5*len);

%% Modelle

mdlPowerRequired1 = mdl{1};
mdlPowerRequired2 = mdl{2};
mdlMassFlowMEOHTankIn = mdl{3};
mdlMassFlowH2OTankIn = mdl{4};
mdlElectrolyser = mdl{5};

%% Power
% [y1, ~] = calculateRequiredPowerABS_DES_SYNT(leanIn, gasIn, hydrogenIn, mdlPowerRequired1, len);
% [y2, ~] = calculateRequiredPowerDIST(meohOut,mdlPowerRequired2,len);
% powerRequired = y1 + y2;
powerRequired = predict(mdlPowerRequired1,[leanIn, gasIn, hydrogenIn]) + predict(mdlPowerRequired2,meohOut);

%% Electrolyzer
powerScaled = power * param.pvScale;
powerInNominal = powerIn / 100;

% Modell für die Effizienz des Elektrolyseurs
%efficiencyElectrolyzer = calculateEfficiencyElectrolyser(powerInNominal,mdlElectrolyser,param);
efficiencyElectrolyzer = feval(mdlElectrolyser,powerInNominal);
hydrogenProdElectrolyzer = powerIn.*efficiencyElectrolyzer*60*param.sampleTime / (param.electrolyzer.constant*100);

%% H2-Tank
tankH2InitialFilling = param.tankH2InitialPressure*10^5*param.tankH2Volume / (param.R*(param.Tamb + param.T0)*1000);
tankH2Filling = zeros(len,1);
tankH2Filling(1) = tankH2InitialFilling;
for i = 2:len
    tankH2Filling(i) = tankH2Filling(i-1) + hydrogenProdElectrolyzer(i)/60*param.sampleTime - param.kgTokmolH2*hydrogenIn(i)/60*param.sampleTime;
end
tankH2Pressure(1) = tankH2InitialFilling*param.R*(param.Tamb + param.T0) / (param.tankH2Volume*100);
tankH2Pressure(2:len) = tankH2Filling(2:len)*param.R*(param.Tamb + param.T0) / (param.tankH2Volume*100);

%% Methanol Tank
% [methanolTankIn, ~] = calculateMEOHTankIn(leanIn,gasIn,hydrogenIn,mdlMassFlowMEOHTankIn,len);
% [waterTankIn, ~] = calculateH2OTankIn(leanIn,gasIn,hydrogenIn,mdlMassFlowH2OTankIn,len);
methanolTankIn = predict(mdlMassFlowMEOHTankIn, [leanIn,gasIn,hydrogenIn]);
waterTankIn = predict(mdlMassFlowH2OTankIn, [leanIn,gasIn,hydrogenIn]);

tankMEOHInitialFilling = param.tankMEOHInitialPressure*10^5*param.tankMEOHVolume / (param.R*(param.Tamb + param.T0)*1000);
tankMEOHFilling = zeros(len,1);
tankMEOHFilling(1) = tankMEOHInitialFilling;
for i = 2:len
    tankMEOHFilling(i) = tankMEOHFilling(i-1) + (methanolTankIn(i)*param.kgTokmolMEOH + waterTankIn(i)*param.kgTokmolH2O)/60*param.sampleTime - (param.kgTokmolMEOH*(meohOut(i) - meohOut(i)/(1+param.MEOHToWaterRatio)) + param.kgTokmolH2O*meohOut(i)/(1+param.MEOHToWaterRatio))/60*param.sampleTime;
end
tankMEOHPressure(1) = tankMEOHInitialFilling*param.R*(param.Tamb + param.T0) / (param.tankMEOHVolume*100);
tankMEOHPressure(2:len) = tankMEOHFilling(2:len)*param.R*(param.Tamb + param.T0) / (param.tankMEOHVolume*100);

%% Constraints

c(1:len) = powerIn(:) + powerRequired(:)*0.001 - powerScaled(:);
c(len+1:2*len) = param.tankH2LowerBound - tankH2Pressure(:); 
c(2*len+1:3*len) = tankH2Pressure(:) - param.tankH2UpperBound;
c(3*len+1:4*len) = param.tankMEOHLowerBound - tankMEOHPressure(:);
c(4*len+1:5*len) = tankMEOHPressure(:) - param.tankMEOHUpperBound;


ceq = [];
