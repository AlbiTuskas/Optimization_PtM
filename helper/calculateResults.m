function [result, costs] = calculateResults(sol,len,mdl,param)

mdlPowerRequiredABSDESSYNT = mdl{1};
mdlPowerRequiredDIS = mdl{2};
mdlMassFlowBiogasOut = mdl{3};
mdlDensityBiogasOut = mdl{5};
mdlMoleFractionCH4BiogasOut = mdl{6};
mdlMassFlowMEOHTankIn = mdl{7};
mdlMoleFlowMEOHTankIn = mdl{8};
mdlMassFlowMEOHProd = mdl{10};
mdlElectrolyser = mdl{end};

% Ergebnisse Anlage
result.powerInPlant = 0.001*predict(mdlPowerRequiredABSDESSYNT, [sol.leanIn, sol.gasIn, sol.hydrogenIn]) + 0.001*predict(mdlPowerRequiredDIS, [sol.meohTankOut]);
result.methanolProdcution = predict(mdlMassFlowMEOHProd, [sol.meohTankOut]);
result.moleFlowMEOHTankIn = predict(mdlMoleFlowMEOHTankIn, [sol.leanIn, sol.gasIn, sol.hydrogenIn]);
result.massFlowMEOHTankIn = predict(mdlMassFlowMEOHTankIn, [sol.leanIn, sol.gasIn, sol.hydrogenIn]);

% Electrolyser
result.powerInNominal = (sol.powerInElectrolyser + param.battery.efficiency*sol.powerBatteryElectrolyser) / 100;
%result.powerInNominal = result.powerInNominal';
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
result.tankH2Filling = zeros(len,1);
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
result.tankMEOHPressure = zeros(len,1);
result.tankMEOHFilling(1) = result.tankMEOHInitialFilling;
for i = 2:len
    result.tankMEOHFilling(i) = result.tankMEOHFilling(i-1) + result.moleFlowMEOHTankIn(i)/60*param.sampleTime - sol.meohTankOut(i)*param.kgTokmolMEOHTank/60*param.sampleTime; 
end
result.tankMEOHPressure(2:len) = result.tankMEOHFilling(2:len)*param.R*(param.Tamb + param.T0) / (result.tankMEOHVolume*100);
result.tankMEOHPressure(1) = result.tankMEOHInitialFilling*param.R*(param.Tamb + param.T0) / (result.tankMEOHVolume*100);

%% Biogas
result.massFlowBiogas = predict(mdlMassFlowBiogasOut, [sol.leanIn,sol.gasIn,sol.hydrogenIn]);
result.densityBiogas = predict(mdlDensityBiogasOut,[sol.leanIn,sol.gasIn,sol.hydrogenIn]);
result.moleFractionCH4Biogas = predict(mdlMoleFractionCH4BiogasOut, [sol.leanIn,sol.gasIn,sol.hydrogenIn]);

%% Auslastung
result.loadFactorPlant = result.moleFlowMEOHTankIn*(1/param.kgTokmolMEOHTank) / param.maxOutputPlant * 100;
result.loadFactorDistillation = result.methanolProdcution / param.maxOutputDistillation * 100;
result.loadFactorElectrolyser = result.hydrogenProdElectrolyser / param.kgTokmolH2 / param.maxOutputElectrolyser * 100;
result.loadFactor = [result.loadFactorPlant(1,1); result.loadFactorDistillation(1,1); result.loadFactorElectrolyser(1,1)];


%% Kosten
costs.methanol = - result.methanolProdcution*param.costs.methanol;
costs.biogas = - result.massFlowBiogas./result.densityBiogas.*result.moleFractionCH4Biogas*param.CH4.brennwert*param.costs.biogas;
costs.powerInPlant = + result.powerInPlant.*param.costs.energy;
costs.hydrogenSold = - sol.hydrogenSold*param.costs.hydrogen;
costs.powerInElectrolyser = sol.powerInElectrolyser.*param.costs.energy;
costs.powerInBattery = sol.powerInBattery.*param.costs.energy;
costs.powerSold = - sol.powerSold.*param.costs.energySold;
costs.tankMEOH = - (result.tankMEOHFilling(end) - result.tankMEOHFilling(1))*(1/param.kgTokmolMEOHTank)*param.costs.methanolTank;
costs.tankH2 = - (result.tankH2Filling(end) - result.tankH2Filling(1))*(1/param.kgTokmolH2)*param.costs.hydrogenTank;
costs.battery = - (result.batteryChargeValue(end) - result.batteryChargeValue(1));

costs.sum.methanol = sum(costs.methanol);
costs.sum.biogas = sum(costs.biogas);
costs.sum.powerInPlant = sum(costs.powerInPlant);
costs.sum.hydrogenSold = sum(costs.hydrogenSold);
costs.sum.powerInElectrolyser = sum(costs.powerInElectrolyser);
costs.sum.powerInBattery = sum(costs.powerInBattery);
costs.sum.powerSold = sum(costs.powerSold);
costs.sum.tankMEOH = costs.tankMEOH;
costs.sum.tankH2 = costs.tankH2;
costs.sum.battery = costs.battery;
costs.sum.all = sum(costs.methanol)...
            + sum(costs.biogas)...
            + sum(costs.powerInPlant)...
            + sum(costs.hydrogenSold)...
            + sum(costs.powerInElectrolyser)...
            + sum(costs.powerInBattery)...
            + sum(costs.powerSold)...
            + costs.tankMEOH...
            + costs.tankH2...
            + costs.battery;

costs.costsArray = [sum(costs.methanol);...
                sum(costs.biogas);...
                sum(costs.powerInPlant);...
                sum(costs.hydrogenSold);...
                sum(costs.powerInElectrolyser);...
                sum(costs.powerInBattery);...
                sum(costs.powerSold);...
                costs.tankMEOH;...
                costs.tankH2;...
                costs.battery;...
                costs.sum.all];


           

