function y = objfcn(x,len,mdl,param)

leanIn(:,1) = x(1:len);
gasIn(:,1) = x(len+1:2*len);
hydrogenIn(:,1) = x(2*len+1:3*len);
meohTankOut(:,1) = x(3*len+1:4*len);
powerInElectrolyser(:,1) = x(4*len+1:5*len);
powerInBattery(:,1) = x(5*len+1:6*len);
powerBatteryElectrolyser(:,1) = x(6*len+1:7*len);
powerSold(:,1) = x(7*len+1:8*len);
hydrogenSold(:,1) = x(8*len+1:9*len);

mdlPowerRequiredABSDESSYNT = mdl{1};
mdlPowerRequiredDIS = mdl{2};
mdlMassFlowBiogasOut = mdl{3};
mdlDensityBiogasOut = mdl{5};
mdlMoleFracCH4BiogasOut = mdl{6};
mdlMoleFlowMEOHTankIn = mdl{8};
mdlMassFlowMEOHProd = mdl{10};
mdlMoleFlowMEOHTankOut = mdl{11};
mdlElectrolyser = mdl{end};


%% Power
powerInPlant = (predict(mdlPowerRequiredABSDESSYNT,[leanIn, gasIn, hydrogenIn]) + predict(mdlPowerRequiredDIS,meohTankOut)) / 1000;

%% Electrolyser
powerInNominal = (powerInElectrolyser + param.battery.efficiency*powerBatteryElectrolyser) / 100;

% Modell für die Effizienz des Elektrolyseurs
efficiencyElectrolyser = feval(mdlElectrolyser,powerInNominal);
for i = 1:len
    if efficiencyElectrolyser(i) < 0
        efficiencyElectrolyser(i) = 0;
    end
end
hydrogenProdElectrolyser = (powerInElectrolyser + param.battery.efficiency*powerBatteryElectrolyser).*efficiencyElectrolyser*60*param.sampleTime / (param.electrolyser.constant*100);

%% Battery
batteryInitialCharge = param.battery.initialCharge;
batteryCharge = zeros(len,1);
batteryChargeValue = zeros(len,1);
batteryCharge(1) = batteryInitialCharge;
batteryChargeValue(1) = batteryCharge(1)*param.costs.energy(1);
for i = 2:len
    batteryCharge(i) = batteryCharge(i-1) + powerInBattery(i)/60*param.sampleTime*param.battery.efficiency - powerBatteryElectrolyser(i)/60*param.sampleTime - powerSold(i)/60*param.sampleTime;
    if batteryCharge(i) == 0
        batteryCharge(i) = 1;
    end
    batteryChargeValue(i) = batteryChargeValue(i-1) + powerInBattery(i)/60*param.sampleTime*param.battery.efficiency*param.costs.energy(i) - powerBatteryElectrolyser(i)/60*param.sampleTime*batteryChargeValue(i-1)/batteryCharge(i-1) - powerSold(i)/60*param.sampleTime*batteryChargeValue(i-1)/batteryCharge(i-1);
end

%% H2-Tank
tankH2InitialFilling = param.tankH2InitialPressure*10^5*param.tankH2Volume / (param.R*(param.Tamb + param.T0)*1000);
tankH2Filling = zeros(len,1);
tankH2Filling(1) = tankH2InitialFilling;
for i = 2:len
    tankH2Filling(i) = tankH2Filling(i-1) + hydrogenProdElectrolyser(i)/60*param.sampleTime - param.kgTokmolH2*hydrogenIn(i)/60*param.sampleTime - param.kgTokmolH2*hydrogenSold(i)/60*param.sampleTime;
end

%% Methanol Tank
moleFlowMEOHTankIn = predict(mdlMoleFlowMEOHTankIn, [leanIn,gasIn,hydrogenIn]);
%moleFlowMEOHTankOut = predict(mdlMoleFlowMEOHTankOut, meohTankOut);

tankMEOHInitialFilling = param.tankMEOHInitialPressure*10^5*param.tankMEOHVolume / (param.R*(param.Tamb + param.T0)*1000);
tankMEOHFilling = zeros(len,1);
tankMEOHFilling(1) = tankMEOHInitialFilling;
for i = 2:len
    tankMEOHFilling(i) = tankMEOHFilling(i-1) + moleFlowMEOHTankIn(i)/60*param.sampleTime - meohTankOut(i)*param.kgTokmolMEOHTank/60*param.sampleTime;
end

%% Biogas
massFlowBiogas = predict(mdlMassFlowBiogasOut, [leanIn,gasIn,hydrogenIn]);
densityBiogas = predict(mdlDensityBiogasOut, [leanIn,gasIn,hydrogenIn]);
moleFractionCH4Biogas = predict(mdlMoleFracCH4BiogasOut, [leanIn,gasIn,hydrogenIn]);

%% Methanol
massFlowMethanolProd = predict(mdlMassFlowMEOHProd,meohTankOut);

%% Objective Function
y = - sum(massFlowMethanolProd)*param.costs.methanol...
    - sum(massFlowBiogas./densityBiogas.*moleFractionCH4Biogas*param.CH4.brennwert)*param.costs.biogas...
    + sum(powerInPlant.*param.costs.energy)...
    - sum(hydrogenSold*param.costs.hydrogen)...
    + sum(powerInElectrolyser.*param.costs.energy)...
    + sum(powerInBattery.*param.costs.energy)...
    - sum(powerSold.*param.costs.energySold)...
    - (tankMEOHFilling(end) - tankMEOHFilling(1))*(1/param.kgTokmolMEOHTank)*param.costs.methanolTank...
    - (tankH2Filling(end) - tankH2Filling(1))*(1/param.kgTokmolH2)*param.costs.hydrogenTank...
    - (batteryChargeValue(end) - batteryChargeValue(1));

