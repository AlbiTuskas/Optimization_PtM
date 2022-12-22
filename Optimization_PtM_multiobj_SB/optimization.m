clear all
close all

addpath('C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\02_Modell\01_Matlab\10_Projects\Optimization_PtM');

%% Parameter
solverType = "ga";

param.numberOfVariables = 5;
param.sampleTime = 60;
param.numberOfHours = 168;
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

power = zeros(1,length(idx)-1);
for i = 1:length(idx)-1
    power(i) = mean(powerAll(idx(i):idx(i+1)));
end
power = power';
len = size(power,1);

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

%% Definition der Optimierungsumgebung
lb(1:len) = param.lbLeanIn;
lb(len+1:2*len) = param.lbGasIn;
lb(2*len+1:3*len) = param.lbHydrogenIn;
lb(3*len+1:4*len) = param.lbPowerIn;
lb(4*len+1:5*len) = param.lbMeohOut;

ub(1:len) = param.ubLeanIn;
ub(len+1:2*len) = param.ubGasIn;
ub(2*len+1:3*len) = param.ubHydrogenIn;
ub(3*len+1:4*len) = param.ubPowerIn;
ub(4*len+1:5*len) = param.ubMeohOut;

FitnessFunction = @(x) objfcn(x,len,{mdlMassFlowMEOHProd, mdlPowerRequired1, mdlPowerRequired2},power,param);
ConstraintFunction = @(x) confcn(x,len,{mdlPowerRequired1, mdlPowerRequired2, mdlMassFlowMEOHTankIn, mdlMassFlowH2OTankIn, mdlElectrolyser},power,param);

nvars = param.numberOfVariables*len;

%% Solve 
%rng default % For reproducibility

if solverType == "ga"
    options = optimoptions('gamultiobj','ConstraintTolerance',1e-6,'UseParallel',true);
    [x,fval] = gamultiobj(FitnessFunction,nvars,[],[],[],[],lb,ub,ConstraintFunction,options);
end

%% Berechnung der Ergebnisse
dispatchsol.leanIn = x(1:len)';
dispatchsol.gasIn = x(len+1:2*len)';
dispatchsol.hydrogenIn = x(2*len+1:3*len)';
dispatchsol.powerIn = x(3*len+1:4*len)';
dispatchsol.meohOut = x(4*len+1:5*len)';

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
