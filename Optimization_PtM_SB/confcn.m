function [c, ceq] = confcn(x,len,mdl,param)

leanIn(:,1) = x(1:len);
gasIn(:,1) = x(len+1:2*len);
hydrogenIn(:,1) = x(2*len+1:3*len);
powerInElectrolyser(:,1) = x(3*len+1:4*len);
meohOut(:,1) = x(4*len+1:5*len);
powerInBattery(:,1) = x(5*len+1:6*len);
powerBatteryElectrolyser(:,1) = x(6*len+1:7*len);
powerSold(:,1) = x(7*len+1:8*len);
hydrogenSold(:,1) = x(8*len+1:9*len);


%% Modelle
mdlMassFlowMEOHTankIn = mdl{1};
mdlMassFlowH2OTankIn = mdl{2};
mdlElectrolyser = mdl{8};


%% Electrolyser
powerInNominal = (powerInElectrolyser + param.battery.efficiency*powerBatteryElectrolyser) / 100;

% Modell für die Effizienz des Elektrolyseurs
efficiencyElectrolyser = feval(mdlElectrolyser,powerInNominal);
hydrogenProdElectrolyser = (powerInElectrolyser + param.battery.efficiency*powerBatteryElectrolyser).*efficiencyElectrolyser*60*param.sampleTime / (param.electrolyser.constant*100);

%% Battery
batteryInitialCharge = param.battery.initialCharge;
batteryCharge = zeros(len,1);
batteryCharge(1) = batteryInitialCharge;
for i = 2:len
    batteryCharge(i) = batteryCharge(i-1) + powerInBattery(i)/60*param.sampleTime*param.battery.efficiency - powerBatteryElectrolyser(i)/60*param.sampleTime - powerSold(i)/60*param.sampleTime;
end

%% H2-Tank
tankH2InitialFilling = param.tankH2InitialPressure*10^5*param.tankH2Volume / (param.R*(param.Tamb + param.T0)*1000);
tankH2Filling = zeros(len,1);
tankH2Filling(1) = tankH2InitialFilling;
for i = 2:len
    tankH2Filling(i) = tankH2Filling(i-1) + hydrogenProdElectrolyser(i)/60*param.sampleTime - param.kgTokmolH2*hydrogenIn(i)/60*param.sampleTime - param.kgTokmolH2*hydrogenSold(i)/60*param.sampleTime;
end
tankH2Pressure(1) = tankH2InitialFilling*param.R*(param.Tamb + param.T0) / (param.tankH2Volume*100);
tankH2Pressure(2:len) = tankH2Filling(2:len)*param.R*(param.Tamb + param.T0) / (param.tankH2Volume*100);

%% Methanol Tank
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

%% Operating Point Change
leanInChange = zeros(len-1,1);
gasInChange = zeros(len-1,1);
hydrogenInChange = zeros(len-1,1);
meohOutRestricted = zeros(len-1,1);
for i = 2:len
    %meohOutRestricted = abs(meohOut(i) - meohOut(i-1)) / meohOut(i-1);
    meohOutRestricted(i-1) = abs(meohOut(i) - meohOut(i-1)) / (param.ubMeohOut - param.lbMeohOut)*1000;
    leanInChange(i-1) = abs(leanIn(i) - leanIn(i-1)) / (param.ubLeanIn - param.lbLeanIn);
    gasInChange(i-1) = abs(gasIn(i) - gasIn(i-1)) / (param.ubGasIn - param.lbGasIn);
    hydrogenInChange(i-1) = abs(hydrogenIn(i) - hydrogenIn(i-1)) / (param.ubHydrogenIn - param.lbHydrogenIn);
end

%% Constraints
c(1:len) = param.tankH2LowerBound - tankH2Pressure(:); 
c(len+1:2*len) = tankH2Pressure(:) - param.tankH2UpperBound;
c(2*len+1:3*len) = param.tankMEOHLowerBound - tankMEOHPressure(:);
c(3*len+1:4*len) = tankMEOHPressure(:) - param.tankMEOHUpperBound;
c(4*len+1:5*len) = 10 - batteryCharge(:);
c(5*len+1:6*len) = batteryCharge(:) - param.battery.capacity;
c(6*len+1:7*len) = powerInElectrolyser(:) + powerBatteryElectrolyser(:) - 200;
c(7*len+1:8*len-1) = meohOutRestricted(:) - 50;

ceq = [];
