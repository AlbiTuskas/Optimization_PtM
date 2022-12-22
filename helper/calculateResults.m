function [result, costs] = calculateResults(sol,len,mdl,param)

mdlMassFlowMEOHTankIn = mdl{1};
mdlMassFlowH2OTankIn = mdl{2};
mdlPowerRequired1 = mdl{3};
mdlMassFlowBiogasOut = mdl{4};
mdlMoleFracCH4BiogasOut = mdl{5};
mdlMassFlowMEOHProd = mdl{6};
mdlPowerRequired2 = mdl{7};
mdlElectrolyser = mdl{8};

% Ergebnisse Anlage
result.powerInPlant = 0.001*predict(mdlPowerRequired1, [sol.leanIn, sol.gasIn, sol.hydrogenIn]) + 0.001*predict(mdlPowerRequired2, [sol.meohOut]);
result.methanolProdcution = predict(mdlMassFlowMEOHProd, [sol.meohOut]);
result.methanolTankIn = predict(mdlMassFlowMEOHTankIn, [sol.leanIn, sol.gasIn, sol.hydrogenIn]);
result.waterTankIn = predict(mdlMassFlowH2OTankIn, [sol.leanIn, sol.gasIn, sol.hydrogenIn]);
result.massFlowBiogasOut = predict(mdlMassFlowBiogasOut, [sol.leanIn, sol.gasIn, sol.hydrogenIn]);
result.moleFracCH4BiogasOut = predict(mdlMoleFracCH4BiogasOut, [sol.leanIn, sol.gasIn, sol.hydrogenIn]);

% Electrolyser
result.powerInNominal = (sol.powerInElectrolyser + param.battery.efficiency*sol.powerBatteryElectrolyser) / 100;
result.powerInNominal = result.powerInNominal';
result.efficiencyElectrolyser = zeros(len,1);
result.efficiencyElectrolyser = feval(mdlElectrolyser,result.powerInNominal);
for i = 1:len
    if result.efficiencyElectrolyser(i) < 0
        result.efficiencyElectrolyser(i) = 0;
    end
end
result.hydrogenProdElectrolyser = (sol.powerInElectrolyser + param.battery.efficiency*sol.powerBatteryElectrolyser).*result.efficiencyElectrolyser*60*param.sampleTime / (param.electrolyser.constant*100);

% Battery
result.batteryInitialCharge = param.battery.initialCharge;
result.batteryCharge = zeros(len,1);
result.batteryChargeValue = zeros(len,1);
result.batteryCharge(1) = result.batteryInitialCharge;
result.batteryChargeValue(1) = result.batteryCharge(1)*param.costs.energy(1);
for i = 2:len
    result.batteryCharge(i) = result.batteryCharge(i-1) + sol.powerInBattery(i)/60*param.sampleTime*param.battery.efficiency - sol.powerBatteryElectrolyser(i)/60*param.sampleTime - sol.powerSold(i)/60*param.sampleTime;
    if result.batteryCharge(i) == 0
        result.batteryCharge(i) = param.tol;
    end
    result.batteryChargeValue(i) = result.batteryChargeValue(i-1) + sol.powerInBattery(i)/60*param.sampleTime*param.battery.efficiency*param.costs.energy(i) - sol.powerBatteryElectrolyser(i)/60*param.sampleTime*result.batteryChargeValue(i-1)/result.batteryCharge(i-1) - sol.powerSold(i)/60*param.sampleTime*result.batteryChargeValue(i-1)/result.batteryCharge(i-1);
end

% H2 Tank
result.tankH2InitialPressure = param.tankH2InitialPressure;
result.tankH2Volume = param.tankH2Volume;
result.tankH2InitialFilling = result.tankH2InitialPressure*10^5*result.tankH2Volume / (param.R*(param.Tamb + param.T0)*1000);
result.tankFilling = zeros(len,1);
result.tankH2Filling(1) = result.tankH2InitialFilling;
for i = 2:len
    result.tankH2Filling(i) = result.tankH2Filling(i-1) + result.hydrogenProdElectrolyser(i)/60*param.sampleTime - param.kgTokmolH2*sol.hydrogenIn(i)/60*param.sampleTime - param.kgTokmolH2*sol.hydrogenSold(i)/60*param.sampleTime;
end
result.tankH2Pressure(1) = result.tankH2InitialFilling*param.R*(param.Tamb + param.T0) / (result.tankH2Volume*100);
result.tankH2Pressure(2:len) = result.tankH2Filling(2:len)*param.R*(param.Tamb + param.T0) / (result.tankH2Volume*100);
result.tankH2Pressure = result.tankH2Pressure';

% Methanol Tank
result.tankMEOHInitialPressure = param.tankMEOHInitialPressure;
result.tankMEOHVolume = param.tankMEOHVolume;
result.tankMEOHInitialFilling = result.tankMEOHInitialPressure*10^5*result.tankMEOHVolume / (param.R*(param.Tamb + param.T0)*1000);
result.tankMEOHFilling = zeros(len,1);
result.tankMEOHFilling(1) = result.tankMEOHInitialFilling;
for i = 2:len
   result.tankMEOHFilling(i) = result.tankMEOHFilling(i-1) + (result.methanolTankIn(i)*param.kgTokmolMEOH + result.waterTankIn(i)*param.kgTokmolH2O)/60*param.sampleTime - (param.kgTokmolMEOH*(sol.meohOut(i) - sol.meohOut(i)/(1+param.MEOHToWaterRatio)) + param.kgTokmolH2O*sol.meohOut(i)/(1+param.MEOHToWaterRatio))/60*param.sampleTime;
end
result.tankMEOHPressure(2:len) = result.tankMEOHFilling(2:len)*param.R*(param.Tamb + param.T0) / (result.tankMEOHVolume*100);
result.tankMEOHPressure(1) = result.tankMEOHInitialFilling*param.R*(param.Tamb + param.T0) / (result.tankMEOHVolume*100);

% Operating Point Change
%% Operating Point Change
leanInChange = zeros(len-1,1);
gasInChange = zeros(len-1,1);
hydrogenInChange = zeros(len-1,1);
meohOutRestricted = zeros(len-1,1);
for i = 2:len
    %meohOutRestricted = abs(meohOut(i) - meohOut(i-1)) / meohOut(i-1);
    meohOutRestricted(i-1) = abs(sol.meohOut(i) - sol.meohOut(i-1)) / (param.ubMeohOut - param.lbMeohOut);
end

% Kosten
costs.methanol = - sum(result.methanolProdcution)*param.costs.methanol;
costs.powerInPlant = + sum(result.powerInPlant.*param.costs.energy);
costs.hydrogenSold = - sum(sol.hydrogenSold*param.costs.hydrogen);
costs.powerInElectrolyser = sum(sol.powerInElectrolyser.*param.costs.energy);
costs.powerInBattery = sum(sol.powerInBattery.*param.costs.energy);
costs.powerSold = - sum(sol.powerSold.*param.costs.energySold);
costs.tankMEOH = - ((((result.tankMEOHFilling(end) - result.tankMEOHFilling(1)) - (result.tankMEOHFilling(end) - result.tankMEOHFilling(1))/(1 + param.MEOHToWaterRatio))*(1/param.kgTokmolMEOH)) + ((result.tankMEOHFilling(end) - result.tankMEOHFilling(1))/(1 + param.MEOHToWaterRatio)*(1/param.kgTokmolH2O)))*param.costs.methanolTank;
costs.tankH2 = - (result.tankH2Filling(end) - result.tankH2Filling(1))*(1/param.kgTokmolH2)*param.costs.hydrogenTank;
costs.battery = - (result.batteryChargeValue(end) - result.batteryChargeValue(1));

costs.operationPointChangePlant =  sum(leanInChange)*param.costs.operatingPointChangePlant...
                                + sum(gasInChange)*param.costs.operatingPointChangePlant...
                                + sum(hydrogenInChange)*param.costs.operatingPointChangePlant;

costs.all = costs.methanol...
            + costs.powerInPlant...
            + costs.hydrogenSold...
            + costs.powerInElectrolyser...
            + costs.powerInBattery...
            + costs.powerSold...
            + costs.tankMEOH...
            + costs.tankH2...
            + costs.battery...
            + costs.operationPointChangePlant;

costs.costsArray = [costs.methanol;...
                costs.powerInPlant;...
                costs.hydrogenSold;...
                costs.powerInElectrolyser;...
                costs.powerInBattery;...
                costs.powerSold;...
                costs.tankMEOH;...
                costs.tankH2;...
                costs.battery;...
                costs.operationPointChangePlant;...
                costs.all];


           

