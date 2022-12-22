clear all
close all

addpath('C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\02_Modell\01_Matlab\10_Projects\Optimization_PtM_Costs');

%% Parameter
systemparameter
len = param.len;

%% Definition der Optimierungsvariablen

leanIn = optimvar('leanIn', len, 'Type','continuous','LowerBound',param.lbLeanIn, 'UpperBound',param.ubLeanIn);
gasIn = optimvar('gasIn', len, 'Type','continuous','LowerBound',param.lbGasIn, 'UpperBound',param.ubGasIn);
hydrogenIn = optimvar('hydrogenIn', len, 'Type','continuous','LowerBound',param.lbHydrogenIn, 'UpperBound',param.ubHydrogenIn);
powerInElectrolyser = optimvar('powerInElectrolyser', len, 'Type', 'continuous','LowerBound',param.lbPowerInElectrolyser, 'UpperBound',param.ubPowerInElectrolyser);
meohOut = optimvar('meohOut', len, 'Type','continuous','LowerBound', param.lbMeohOut, 'UpperBound',param.ubMeohOut);
powerInBattery = optimvar('powerInBattery', len,'Type','continuous','LowerBound',param.lbPowerInBattery, 'UpperBound',param.ubPowerInBattery);
powerBatteryElectrolyser = optimvar('powerBatteryElectrolyser', len,'Type','continuous','LowerBound',param.lbPowerBatteryElectrolyser, 'UpperBound',param.ubPowerBatteryElectrolyser);
powerSold = optimvar('powerSold', len,'Type','continuous','LowerBound',param.lbPowerSold, 'UpperBound',param.ubPowerSold);
hydrogenSold = optimvar('hydrogenSold', len, 'Type','continuous','LowerBound',param.lbHydrogenSold, 'UpperBound',param.ubHydrogenSold);

%% Kennfeld der Anlage
mdl = regressionModel();
mdlElectrolyser = modelElectrolyser(param);
mdl{8} = mdlElectrolyser;

mdlMassFlowMEOHTankIn = mdl{1};
mdlMassFlowH2OTankIn = mdl{2};
mdlPowerRequired1 = mdl{3};
mdlMassFlowBiogasOut = mdl{4};
mdlMoleFracCH4BiogasOut = mdl{5};
mdlMassFlowMEOHProd = mdl{6};
mdlPowerRequired2 = mdl{7};

%% Power
[y1, ~] = calculateRequiredPowerABS_DES_SYNT(leanIn, gasIn, hydrogenIn, mdlPowerRequired1, len);
[y2, ~] = calculateRequiredPowerDIST(meohOut,mdlPowerRequired2,len);
powerInPlant = (y1 + y2) / 1000;

%% Electrolyser
powerInNominal = (powerInElectrolyser + param.battery.efficiency*powerBatteryElectrolyser) / 100;

% Modell für die Effizienz des Elektrolyseurs
efficiencyElectrolyser = calculateEfficiencyElectrolyser(powerInNominal, mdlElectrolyser, param);
hydrogenProdElectrolyser = (powerInElectrolyser + param.battery.efficiency*powerBatteryElectrolyser).*efficiencyElectrolyser*60*param.sampleTime / (param.electrolyser.constant*100);

%% Battery
batteryInitialCharge = param.battery.initialCharge;
batteryCharge = optimexpr(len);
batteryChargeValue = optimexpr(len);
batteryCharge(1) = batteryInitialCharge;
batteryChargeValue(1) = batteryCharge(1)*param.costs.energy(1);
for i = 2:len
    batteryCharge(i) = batteryCharge(i-1) + powerInBattery(i)/60*param.sampleTime*param.battery.efficiency - powerBatteryElectrolyser(i)/60*param.sampleTime - powerSold(i)/60*param.sampleTime;
    batteryChargeValue(i) = batteryChargeValue(i-1) + powerInBattery(i)/60*param.sampleTime*param.battery.efficiency*param.costs.energy(i) - powerBatteryElectrolyser(i)/60*param.sampleTime*batteryChargeValue(i)/batteryCharge(i) - powerSold(i)/60*param.sampleTime*param.costs.energySold(i);
end

%% H2-Tank
tankH2InitialFilling = param.tankH2InitialPressure*10^5*param.tankH2Volume / (param.R*(param.Tamb + param.T0)*1000);
tankH2Filling = optimexpr(len);
tankH2Pressure = optimexpr(len);
tankH2Filling(1) = tankH2InitialFilling;
for i = 2:len
    tankH2Filling(i) = tankH2Filling(i-1) + hydrogenProdElectrolyser(i)/60*param.sampleTime - param.kgTokmolH2*hydrogenIn(i)/60*param.sampleTime;
end
tankH2Pressure(1) = tankH2InitialFilling*param.R*(param.Tamb + param.T0) / (param.tankH2Volume*100);
tankH2Pressure(2:len) = tankH2Filling(2:len)*param.R*(param.Tamb + param.T0) / (param.tankH2Volume*100);

%% Methanol Tank
[methanolTankIn, ~] = calculateMEOHTankIn(leanIn,gasIn,hydrogenIn,mdlMassFlowMEOHTankIn,len);
[waterTankIn, ~] = calculateH2OTankIn(leanIn,gasIn,hydrogenIn,mdlMassFlowH2OTankIn,len);

tankMEOHInitialFilling = param.tankMEOHInitialPressure*10^5*param.tankMEOHVolume / (param.R*(param.Tamb + param.T0)*1000);
tankMEOHFilling = optimexpr(len);
tankMEOHPressure = optimexpr(len);
tankMEOHFilling(1) = tankMEOHInitialFilling;
for i = 2:len
    tankMEOHFilling(i) = tankMEOHFilling(i-1) + (methanolTankIn(i)*param.kgTokmolMEOH + waterTankIn(i)*param.kgTokmolH2O)/60*param.sampleTime - (param.kgTokmolMEOH*(meohOut(i) - meohOut(i)/(1+param.MEOHToWaterRatio)) + param.kgTokmolH2O*meohOut(i)/(1+param.MEOHToWaterRatio))/60*param.sampleTime;
end
tankMEOHPressure(1) = tankMEOHInitialFilling*param.R*(param.Tamb + param.T0) / (param.tankMEOHVolume*100);
tankMEOHPressure(2:len) = tankMEOHFilling(2:len)*param.R*(param.Tamb + param.T0) / (param.tankMEOHVolume*100);

%% Optimierungsproblem

dispatch = optimproblem('ObjectiveSense','maximize');

% Constraints
tankH2ConsBottom = tankH2Pressure(:) >= param.tankH2LowerBound;
tankH2ConsTop = tankH2Pressure(:) <= param.tankH2UpperBound;
tankMEOHConsBottom = tankMEOHPressure(:) >= param.tankMEOHLowerBound;
tankMEOHConsTop = tankMEOHPressure(:) <= param.tankMEOHUpperBound;
batteryConsBottom = batteryCharge(:) >= 0;
batteryConsTop = batteryCharge(:) <= param.battery.capacity;
powerInElectrolyserCons = powerInElectrolyser(:) + powerBatteryElectrolyser(:) <= 200;

dispatch.Constraints.tankH2ConsBottom = tankH2ConsBottom;
dispatch.Constraints.tankH2ConsTop = tankH2ConsTop;
dispatch.Constraints.tankMEOHConsBottom = tankMEOHConsBottom;
dispatch.Constraints.tankMEOHConsTop = tankMEOHConsTop;
dispatch.Constraints.batteryConsBottom = batteryConsBottom;
dispatch.Constraints.batteryConsTop = batteryConsTop;
dispatch.Constraints.powerInElectrolyser = powerInElectrolyserCons;

% Fitness Function 
[methanolProduction, sumMethanolProduction] = calculateMethanolProd(meohOut, mdlMassFlowMEOHProd, len);
dispatch.Objective = sum(methanolProduction.*param.costs.methanol)...
    - sum(powerInPlant.*param.costs.energy)...
    + sum(hydrogenSold*param.costs.hydrogen)...
    - sum(powerInElectrolyser.*param.costs.energy)...
    - sum(powerInBattery.*param.costs.energy)...
    + sum(powerSold.*param.costs.energySold)...
    + ((((tankMEOHFilling(end) - tankMEOHFilling(1)) - (tankMEOHFilling(end) - tankMEOHFilling(1))/(1 + param.MEOHToWaterRatio))*(1/param.kgTokmolMEOH)) + ((tankMEOHFilling(end) - tankMEOHFilling(1))/(1 + param.MEOHToWaterRatio)*(1/param.kgTokmolH2O)))*param.costs.methanolTank...
    + (tankH2Filling(end) - tankH2Filling(1))*(1/param.kgTokmolH2)*param.costs.hydrogenTank...
    + (batteryChargeValue(end) - batteryChargeValue(1));

%% Solve 
rng default

if param.solverType == "ga"
    for i = 1:param.numberOfIterations
        % Anfangsbedingung
        %sol0 = generateRandomInitialValues(param, len);
        %x0 = optimvalues(dispatch,'leanIn',sol0.leanIn,'gasIn',sol0.gasIn,'hydrogenIn',sol0.hydrogenIn,'powerIn',sol0.powerIn,'meohOut',sol0.meohOut);
        [sol,fval,exitflag,output] = solve(dispatch,Solver="ga");
        dispatchsol(i) = sol;
        functionValue(i) = fval;
    end
elseif param.solverType == "patternsearch"
    for i = 1:param.numberOfIterations
        % Anfangsbedingung
        sol0 = generateRandomInitialValues(param, len);
        options = optimoptions('patternsearch','PlotFcn', @psplotbestf);
        [sol,fval,exitflag,output] = solve(dispatch,sol0,'Options',options,Solver="patternsearch");
        dispatchsol(i) = sol;
        functionValue(i) = fval;
    end
elseif param.solverType == "GlobalSearch"
    for i = 1:param.numberOfIterations
        % Anfangsbedingung
        sol0 = generateRandomInitialValues(param, len);

%         prob = createOptimProblem('fmincon', ...
%             x0=[sol0])
        options = optimoptions("patternsearch");
        ms = GlobalSearch("StartPointsToRun","bounds-ineqs","MaxTime",3600);
        [sol,fval,exitflag,output] = solve(dispatch,sol0,ms);
        dispatchsol(i) = sol;
        functionValue(i) = fval;
    end
end

%% Berechnung der Ergebnisse
sol = dispatchsol(1);
[result, costs] = calculateResults(sol,len,mdl,param);

%% Visualisierung

visualization(sol,len,result,param);

