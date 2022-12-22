clear all
close all

%% Einlesen der Stromdaten bzw. des produzierten Wasserstoffs

pathToFile = "C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\06_Daten\02_Energie\Solar_Power_modified";
T = readtable(pathToFile, "Sheet", "Tabelle1", 'VariableNamingRule','preserve');

sampleTime = 60;
start = 12960;
finish = start + 60*24*3;
idx = start:sampleTime:finish;
powerAll = T{:,3};

for i = 1:length(idx)-1
    power(i) = mean(powerAll(idx(i):idx(i+1)));
end
power = power';
len = size(power,1);


%% Kennfeld der Anlage
mdl = regressionModel();
mdlMassFlowMEOHTankIn = mdl{1};
mdlMassFlowH2OTankIn = mdl{2};
mdlPowerRequired1 = mdl{3};
mdlMassFlowBiogasOut = mdl{4};
mdlMoleFracCH4BiogasOut = mdl{5};

mdlMassFlowMEOHProd = mdl{6};
mdlPowerRequired2 = mdl{7};

%% Definition der Optimierungsumgebung
lb(1:len) = 100;
lb(len+1:2*len) = 3;
lb(2*len+1:3*len) = 0.1;
lb(3*len+1:4*len) = 0;

ub(1:len) = 300;
ub(len+1:2*len) = 12;
ub(2*len+1:3*len) = 1;
ub(3*len+1:4*len) = 200;

FitnessFunction = @(x) objfcn(x,len,mdlMassFlowMEOHProd);
ConstraintFunction = @(x) confcn(x,len,sampleTime,{mdlPowerRequired1, mdlPowerRequired2},power);

nvars = 4*len;


%% Solve 
rng default % For reproducibility
options = optimoptions('ga','ConstraintTolerance',1e-6,'UseParallel',true);
[x,fval] = ga(FitnessFunction,nvars,[],[],[],[],lb,ub,ConstraintFunction,options)

%% Berechnung der Parameter
tol = 0.0001;
dispatchsol.leanIn = x(1:len);
dispatchsol.gasIn = x(len+1:2*len);
dispatchsol.hydrogenIn = x(2*len+1:3*len);
dispatchsol.powerIn = x(3*len+1:4*len);

pvScale = 700;
powerScaled = power * pvScale;
result.powerInNominal = dispatchsol.powerIn / 100;
result.powerInNominal = result.powerInNominal';
for i = 1:len
    if result.powerInNominal(i) > tol 
        result.efficiencyElectrolyzer(i) = -14.102*result.powerInNominal(i) + 79.576; 
    else
        result.efficiencyElectrolyzer(i) = 0;
    end
end
result.efficiencyElectrolyzer = result.efficiencyElectrolyzer';
result.hydrogenProdElectrolyzer = dispatchsol.powerIn.*result.efficiencyElectrolyzer*60*sampleTime / (286151.3637877446*100);

kgTokmol = 1/2.016;
tankInitialPressure = 45;
tankVolume = 50;
tankInitiH2alFilling = tankInitialPressure*10^5*tankVolume / (8.314*(21+273.15)*1000);
result.tankFilling(2) = tankInitiH2alFilling + result.hydrogenProdElectrolyzer(2)/60*sampleTime - kgTokmol*dispatchsol.hydrogenIn(2)/60*sampleTime;
for i = 3:len
    result.tankFilling(i) = result.tankFilling(i-1) + result.hydrogenProdElectrolyzer(i)/60*sampleTime - kgTokmol*dispatchsol.hydrogenIn(i)/60*sampleTime;
end
result.tankFilling(1) = tankInitiH2alFilling;
result.tankFilling = result.tankFilling';
result.tankPressure(2:len) = result.tankFilling(2:len)*8.314*(21+273.15) / (tankVolume*100);
result.tankPressure(1) = tankInitiH2alFilling*8.314*(21+273.15) / (tankVolume*100);
result.tankPressure = result.tankPressure';

for i = 1:len
    result.powerRequired(i) = 0.001*predict(mdlPowerRequired1, [dispatchsol.leanIn(i), dispatchsol.gasIn(i), dispatchsol.hydrogenIn(i)]);
    result.methanolProdcution(i) = predict(mdlMassFlowMEOHTankIn, [dispatchsol.leanIn(i), dispatchsol.gasIn(i), dispatchsol.hydrogenIn(i)]);
    result.massFlowBiogasOut(i) = predict(mdlMassFlowBiogasOut, [dispatchsol.leanIn(i), dispatchsol.gasIn(i), dispatchsol.hydrogenIn(i)]);
    result.moleFracCH4BiogasOut(i) = predict(mdlMoleFracCH4BiogasOut, [dispatchsol.leanIn(i), dispatchsol.gasIn(i), dispatchsol.hydrogenIn(i)]);
end

%% Visualisierung
X = 1:len;

% Power
figure
plot(X,powerScaled,X,dispatchsol.powerIn,X,result.powerRequired);
xlabel("time in h");
ylabel("power in kW");
legend("available power", "power consumption electolyzer", "power consumption plant");

% Electrolyzer 
figure
plot(X,result.efficiencyElectrolyzer)
xlabel("time in h");
ylabel("efficiency [-]");

% H2 Tank
figure
plot(X,result.tankFilling)
xlabel("time in h");
ylabel("tank level in kmol");

figure
plot(X,result.tankPressure)
xlabel("time in h");
ylabel("pressure in bar");

figure
plot(X,result.hydrogenProdElectrolyzer/kgTokmol, X, dispatchsol.hydrogenIn);
xlabel("time in h");
ylabel("mass flow hydrogen in kg/h");
legend("hydrogen in", "hydrogen out");

% Methanol
figure
plot(X,result.methanolProdcution)
xlabel("time in h");
ylabel("mass flow methanol in kg/h");
