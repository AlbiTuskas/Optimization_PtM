clear all
close all

addpath('C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\02_Modell\01_Matlab\10_Projects\Optimization_PtM');

%% Parameter
solverType = "patternsearch";

param.numberOfVariables = 5;
param.numberOfIterations = 1;
param.sampleTime = 60;
param.numberOfHours = 10;
param.tol = 0.0001;

param.lbLeanIn = 100;
param.lbGasIn = 3;
param.lbHydrogenIn = 0.1;
param.lbPowerIn = 0;
param.lbMeohOut = 0;
param.ubLeanIn = 300;
param.ubGasIn = 12;
param.ubHydrogenIn = 1;
param.ubPowerIn = 200;
param.ubMeohOut = 3.3;

param.pvScale = 700;
param.electrolyzer.constant = 286151.3637877446;
param.electrolyzer.modelType = "exp2";

param.tankH2InitialPressure = 30;
param.tankH2Volume = 50;
param.tankMEOHInitialPressure = 15;
param.tankMEOHVolume = 50;

param.tankH2LowerBound = 15;
param.tankH2UpperBound = 35;
param.tankMEOHLowerBound = 5;
param.tankMEOHUpperBound = 20;

param.kgTokmolH2 = 1/2.016;
param.kgTokmolMEOH = 1/32.04;
param.kgTokmolH2O = 1/18.01528;
param.MEOHToWaterRatio = 1.776;
param.R = 8.314;
param.Tamb = 21;
param.T0 = 273.15;

%% Einlesen der Stromdaten

pathToFile = "C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\06_Daten\02_Energie\Solar_Power_modified";
T = readtable(pathToFile, "Sheet", "Tabelle1", 'VariableNamingRule','preserve');

start = 12960;
finish = start + 60*param.numberOfHours;
idx = start:param.sampleTime:finish;
powerAll = T{:,3};

power =zeros(length(idx)-1,1);
for i = 1:length(idx)-1
    power(i) = mean(powerAll(idx(i):idx(i+1)));
end
len = size(power,1);


%% Definition der Optimierungsvariablen

leanIn = optimvar('leanIn', len, 'Type','continuous','LowerBound',param.lbLeanIn, 'UpperBound',param.ubLeanIn);
gasIn = optimvar('gasIn', len, 'Type','continuous','LowerBound',param.lbGasIn, 'UpperBound',param.ubGasIn);
hydrogenIn = optimvar('hydrogenIn', len, 'Type','continuous','LowerBound',param.lbHydrogenIn, 'UpperBound',param.ubHydrogenIn);
powerIn = optimvar('powerIn', len, 'Type', 'continuous','LowerBound',param.lbPowerIn, 'UpperBound',param.ubPowerIn);
meohOut = optimvar('meohOut', len, 'Type','continuous','LowerBound', param.lbMeohOut, 'UpperBound',param.ubMeohOut);

%% Kennfeld der Anlage
mdl = regressionModel();
mdlElectrolyser = modelElectrolyser(param);

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
powerRequired = y1 + y2;

%% Electrolyzer
powerScaled = power * param.pvScale;
powerInNominal = powerIn / 100;

% Modell für die Effizienz des Elektrolyseurs
efficiencyElectrolyzer = calculateEfficiencyElectrolyser(powerInNominal, mdlElectrolyser, param);
hydrogenProdElectrolyzer = powerIn.*efficiencyElectrolyzer*60*param.sampleTime / (param.electrolyzer.constant*100);

%% H2-Tank
tankH2InitialFilling = param.tankH2InitialPressure*10^5*param.tankH2Volume / (param.R*(param.Tamb + param.T0)*1000);
tankH2Filling = optimexpr(len);
tankH2Pressure = optimexpr(len);
tankH2Filling(1) = tankH2InitialFilling;
for i = 2:len
    tankH2Filling(i) = tankH2Filling(i-1) + hydrogenProdElectrolyzer(i)/60*param.sampleTime - param.kgTokmolH2*hydrogenIn(i)/60*param.sampleTime;
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
powerCons = powerIn(:) + powerRequired(:)*0.001 <= powerScaled(:);
tankH2ConsBottom = tankH2Pressure(:) >= param.tankH2LowerBound;
tankH2ConsTop = tankH2Pressure(:) <= param.tankH2UpperBound;
tankMEOHConsBottom = tankMEOHPressure(:) >= param.tankMEOHLowerBound;
tankMEOHConsTop = tankMEOHPressure(:) <= param.tankMEOHUpperBound;

dispatch.Constraints.powerCons = powerCons;
dispatch.Constraints.tankH2ConsBottom = tankH2ConsBottom;
dispatch.Constraints.tankH2ConsTop = tankH2ConsTop;
dispatch.Constraints.tankMEOHConsBottom = tankMEOHConsBottom;
dispatch.Constraints.tankMEOHConsTop = tankMEOHConsTop;

% Fitness Function 
[methanolProduction, sumMethanolProduction] = calculateMethanolProd(meohOut, mdlMassFlowMEOHProd, len);
dispatch.Objective = sumMethanolProduction;

%% Solve 
rng default

if solverType == "ga"
    for i = 1:param.numberOfIterations
        % Anfangsbedingung
        sol0 = generateRandomInitialValues(param, len);
        x0 = optimvalues(dispatch,'leanIn',sol0.leanIn,'gasIn',sol0.gasIn,'hydrogenIn',sol0.hydrogenIn,'powerIn',sol0.powerIn,'meohOut',sol0.meohOut);
        [dispatchsol,fval,exitflag,output] = solve(dispatch,Solver="ga");
        sol(i) = dispatchsol;
        functionValue(i) = fval;
    end
elseif solverType == "patternsearch"
    for i = 1:param.numberOfIterations
        % Anfangsbedingung
        sol0 = generateRandomInitialValues(param, len);
        options = optimoptions('patternsearch','PlotFcn', @psplotbestf);
        [dispatchsol,fval,exitflag,output] = solve(dispatch,sol0,'Options',options,Solver="patternsearch");
        sol(i) = dispatchsol;
        functionValue(i) = fval;
    end
elseif solverType == "GlobalSearch"
    for i = 1:param.numberOfIterations
        % Anfangsbedingung
        sol0 = generateRandomInitialValues(param, len);

%         prob = createOptimProblem('fmincon', ...
%             x0=[sol0])
        options = optimoptions("patternsearch");
        ms = GlobalSearch("StartPointsToRun","bounds-ineqs","MaxTime",3600);
        [dispatchsol,fval,exitflag,output] = solve(dispatch,sol0,ms);
        sol(i) = dispatchsol;
        functionValue(i) = fval;
    end
end

%% Berechnung der Ergebnisse
dispatchsol = sol(1);

result.powerRequired = 0.001*predict(mdlPowerRequired1, [dispatchsol.leanIn, dispatchsol.gasIn, dispatchsol.hydrogenIn]) + 0.001*predict(mdlPowerRequired2, [dispatchsol.meohOut]);
result.methanolProdcution = predict(mdlMassFlowMEOHProd, [dispatchsol.meohOut]);
result.methanolTankIn = predict(mdlMassFlowMEOHTankIn, [dispatchsol.leanIn, dispatchsol.gasIn, dispatchsol.hydrogenIn]);
result.waterTankIn = predict(mdlMassFlowH2OTankIn, [dispatchsol.leanIn, dispatchsol.gasIn, dispatchsol.hydrogenIn]);
result.massFlowBiogasOut = predict(mdlMassFlowBiogasOut, [dispatchsol.leanIn, dispatchsol.gasIn, dispatchsol.hydrogenIn]);
result.moleFracCH4BiogasOut = predict(mdlMoleFracCH4BiogasOut, [dispatchsol.leanIn, dispatchsol.gasIn, dispatchsol.hydrogenIn]);

% Electrolyzer
result.powerScaled = power * param.pvScale;
result.powerInNominal = dispatchsol.powerIn / 100;
result.powerInNominal = result.powerInNominal';
result.efficiencyElectrolyzer = zeros(len,1);
for i = 1:len
    if result.powerInNominal(i) > param.tol 
        result.efficiencyElectrolyzer(i,1) = calculateEfficiencyElectrolyser(result.powerInNominal(i),mdlElectrolyser,param); 
    else
        result.efficiencyElectrolyzer(i,1) = 0;
    end
end
result.hydrogenProdElectrolyzer = dispatchsol.powerIn.*result.efficiencyElectrolyzer*60*param.sampleTime / (param.electrolyzer.constant*100);

% H2 Tank
result.tankH2InitialPressure = param.tankH2InitialPressure;
result.tankH2Volume = param.tankH2Volume;
result.tankH2InitialFilling = result.tankH2InitialPressure*10^5*result.tankH2Volume / (param.R*(param.Tamb + param.T0)*1000);
result.tankFilling = zeros(len,1);
result.tankH2Filling(1) = result.tankH2InitialFilling;
for i = 2:len
    result.tankH2Filling(i) = result.tankH2Filling(i-1) + result.hydrogenProdElectrolyzer(i)/60*param.sampleTime - param.kgTokmolH2*dispatchsol.hydrogenIn(i)/60*param.sampleTime;
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
   result.tankMEOHFilling(i) = result.tankMEOHFilling(i-1) + (result.methanolTankIn(i)*param.kgTokmolMEOH + result.waterTankIn(i)*param.kgTokmolH2O)/60*param.sampleTime - (param.kgTokmolMEOH*(dispatchsol.meohOut(i) - dispatchsol.meohOut(i)/(1+param.MEOHToWaterRatio)) + param.kgTokmolH2O*dispatchsol.meohOut(i)/(1+param.MEOHToWaterRatio))/60*param.sampleTime;
end
result.tankMEOHPressure(2:len) = result.tankMEOHFilling(2:len)*param.R*(param.Tamb + param.T0) / (result.tankMEOHVolume*100);
result.tankMEOHPressure(1) = result.tankMEOHInitialFilling*param.R*(param.Tamb + param.T0) / (result.tankMEOHVolume*100);


%% Visualisierung
X = 1:len;

% Power
figure
plot(X,result.powerScaled,X,dispatchsol.powerIn,X,result.powerRequired);
title("Power");
xlabel("time in h");
ylabel("power in kW");
legend("available power", "power consumption electolyzer", "power consumption plant");

% Electrolyzer 
figure
plot(X,result.efficiencyElectrolyzer)
title("Efficiency Electrolyzer");
xlabel("time in h");
ylabel("efficiency [-]");

% H2 Tank
figure
plot(X,result.tankH2Filling)
title("H2-Tank");
xlabel("time in h");
ylabel("tank level in kmol");

figure
plot(X,result.tankH2Pressure)
title("H2-Tank");
xlabel("time in h");
ylabel("pressure in bar");

figure
plot(X,result.hydrogenProdElectrolyzer/param.kgTokmolH2, X, dispatchsol.hydrogenIn);
title("H2-Tank");
xlabel("time in h");
ylabel("mass flow hydrogen in kg/h");
legend("hydrogen in", "hydrogen out");

% Methanol Tank
figure
plot(X,result.tankMEOHFilling)
title("MEOH-Tank");
xlabel("time in h");
ylabel("tank level in kmol");

figure
plot(X,result.tankMEOHPressure)
title("MEOH-Tank");
xlabel("time in h");
ylabel("pressure in bar");

% Methanol
figure
plot(X,result.methanolProdcution)
title("Methanol Production");
xlabel("time in h");
ylabel("mass flow methanol in kg/h");

