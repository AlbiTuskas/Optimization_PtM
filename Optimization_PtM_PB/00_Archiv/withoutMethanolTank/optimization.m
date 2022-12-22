clear all
close all

%% Einlesen der Stromdaten bzw. des produzierten Wasserstoffs

pathToFile = "C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\06_Daten\02_Energie\Solar_Power_modified";
T = readtable(pathToFile, "Sheet", "Tabelle1", 'VariableNamingRule','preserve');

sampleTime = 60;
start = 12960;
finish = start + 60*24*1;
idx = start:sampleTime:finish';
powerAll = T{:,3};

power =zeros(length(idx)-1);
for i = 1:length(idx)-1
    power(i) = mean(powerAll(idx(i):idx(i+1)));
end
power = power';
len = size(power,1);


%% Definition der Optimierungsvariablen
lowerBound = [100; 3; 0.1; 0];
upperBound = [300; 12; 1; 200];

leanIn = optimvar('leanIn', len, 'Type','continuous','LowerBound',lowerBound(1), 'UpperBound', upperBound(1));
gasIn = optimvar('gasIn', len, 'Type','continuous','LowerBound',lowerBound(2), 'UpperBound', upperBound(2));
hydrogenIn = optimvar('hydrogenIn', len, 'Type','continuous','LowerBound',lowerBound(3), 'UpperBound', upperBound(3));
powerIn = optimvar('powerIn', len, 'Type', 'continuous','LowerBound', lowerBound(4), 'UpperBound', upperBound(4));

%% Electrolyzer

pvScale = 700;
powerScaled = power * pvScale;
powerInNominal = powerIn / 100;

% Modell für die Effizienz des Elektrolyseurs
mdlElectrolyser = modelElectrolyser();
%efficiencyElectrolyzer = mdlElectrolyser.a*exp(mdlElectrolyser.b*powerInNominal) + mdlElectrolyser.c*exp(mdlElectrolyser.d*powerInNominal); 
efficiencyElectrolyzer = -14.102*powerInNominal + 79.576; 
hydrogenProdElectrolyzer = powerIn.*efficiencyElectrolyzer*60*sampleTime / (286151.3637877446*100);

%% Tank
kgTokmol = 2.02;

tankInitialPressure = 45;
tankVolume = 50;
tankInitialFilling = tankInitialPressure*10^5*tankVolume / (8.314*(21+273.15)*1000);
tankFilling(2) = tankInitialFilling + hydrogenProdElectrolyzer(2)/60*sampleTime - kgTokmol*hydrogenIn(2)/60*sampleTime;
for i = 3:len
    tankFilling(i) = tankFilling(i-1) + hydrogenProdElectrolyzer(i)/60*sampleTime - kgTokmol*hydrogenIn(i)/60*sampleTime;
end
tankFilling(1) = tankInitialFilling;
tankFilling = tankFilling';
tankPressure(2:len) = tankFilling(2:len)*8.314*(21+273.15) / (tankVolume*100);
tankPressure(1) = tankInitialFilling*8.314*(21+273.15) / (tankVolume*100);

%% Kennfeld der Anlage

mdl = regressionModel();
mdlMassFlowMEOH = mdl{1};
mdlPowerRequired = mdl{2};
mdlMassFlowBiogasOut = mdl{3};
mdlMoleFracCH4BiogasOut = mdl{4};
objfcnArray = optimexpr([len,length(mdl)]);

for j = 1:length(mdl)
    objfcnmdl = mdl{j};
    coef = zeros(size(objfcnmdl.Coefficients,1),1);
    vars = strings(size(objfcnmdl.Coefficients,1),1);
    for i = 1:length(coef)
        coef(i) = objfcnmdl.Coefficients{i,1};
        vars(i) = string(objfcnmdl.CoefficientNames{i});
    end
    
    objfcn = zeros(len,1);
    for i = 1:length(coef)
        if vars(i) == "(Intercept)"
            objfcn = objfcn + coef(i);
        elseif vars(i) == "x1"
            objfcn = objfcn + coef(i)*leanIn;
        elseif vars(i) == "x2"
            objfcn = objfcn + coef(i)*gasIn;
        elseif vars(i) == "x3"
            objfcn = objfcn + coef(i)*hydrogenIn;
        elseif vars(i) == "x1:x2"
            objfcn = objfcn + coef(i)*leanIn.*gasIn;
        elseif vars(i) == "x1:x3" 
            objfcn = objfcn + coef(i)*leanIn.*hydrogenIn;
        elseif vars(i) == "x2:x3" 
            objfcn = objfcn + coef(i)*gasIn.*hydrogenIn;
        elseif vars(i) == "x1^2" 
            objfcn = objfcn + coef(i)*leanIn.*leanIn;
        elseif vars(i) == "x2^2" 
            objfcn = objfcn + coef(i)*gasIn.*gasIn;
        elseif vars(i) == "x3^2"
            objfcn = objfcn + coef(i)*hydrogenIn.*hydrogenIn;
        end
    end
    objfcnArray(:,j) = objfcn;
end
methanolProduction = sum(objfcnArray(:,1));
powerRequired = objfcnArray(:,2);
massFlowBiogasOut = objfcnArray(:,3);
moleFracCH4BiogasOut = objfcnArray(:,4);


%% Constraints
powerCons1 = powerIn(:) + powerRequired(:)*0.001 <= powerScaled(:);
%powerCons2 = powerRequired(:)
tankConsFilling = tankFilling(:) >= 10;
tankConsBottom = tankPressure(:) >= 30;
tankConsTop = tankPressure(:) <= 47;


dispatch = optimproblem('ObjectiveSense','maximize');
dispatch.Objective = methanolProduction;
dispatch.Constraints.powerCons = powerCons1;
% dispatch.Constraints.tankConsFilling = tankConsFilling;
dispatch.Constraints.tankConsBottom = tankConsBottom;
dispatch.Constraints.tankConsTop = tankConsTop;

%% Solve 
numberOfIterations = 1;
%options = optimoptions('intlinprog','Display','final');

for i = 1:numberOfIterations
    % Anfangsbedingung
    init = generateRandomInitialValues(lowerBound, upperBound, len);
    sol0.leanIn = init(1)*ones(len,1);
    sol0.gasIn = init(2)*ones(len,1);
    sol0.hydrogenIn = init(3)*ones(len,1);
    %sol0.powerIn = init(4).*ones(len,1);
    sol0.powerIn = 20.*ones(len,1);
    
    % sol0.leanIn = 100*ones(len,1);
    % sol0.gasIn = 6*ones(len,1);
    % sol0.hydrogenIn = 0.5*ones(len,1);
    % sol0.powerIn = powerScaled.*ones(len,1);

    %[dispatchsol,fval,exitflag,output] = solve(dispatch, sol0,'options',options);
    [dispatchsol,fval,exitflag,output] = solve(dispatch,sol0,Solver="Patternsearch");
    sol(i) = dispatchsol;
    methanolProduced(i) = fval;
end

%% Berechnung der Parameter
tol = 0.0001;
dispatchsol = sol(1);


result.powerInNominal = dispatchsol.powerIn / 100;
for i = 1:len
    if result.powerInNominal(i) > tol 
        result.efficiencyElectrolyzer(i) = -14.102*result.powerInNominal(i) + 79.576; 
    else
        result.efficiencyElectrolyzer(i) = 0;
    end
end
result.efficiencyElectrolyzer = result.efficiencyElectrolyzer';
result.hydrogenProdElectrolyzer = dispatchsol.powerIn.*result.efficiencyElectrolyzer*60*sampleTime / (286151.3637877446*100);


result.tankFilling(2) = tankInitialFilling + result.hydrogenProdElectrolyzer(2)/60*sampleTime - kgTokmol*dispatchsol.hydrogenIn(2)/60*sampleTime;
for i = 3:len
    result.tankFilling(i) = result.tankFilling(i-1) + result.hydrogenProdElectrolyzer(i)/60*sampleTime - kgTokmol*dispatchsol.hydrogenIn(i)/60*sampleTime;
end
result.tankFilling(1) = tankInitialFilling;
result.tankFilling = result.tankFilling';
result.tankPressure(2:len) = result.tankFilling(2:len)*8.314*(21+273.15) / (tankVolume*100);
result.tankPressure(1) = tankInitialFilling*8.314*(21+273.15) / (tankVolume*100);
result.tankPressure = result.tankPressure';

for i = 1:len
    result.powerRequired(i) = 0.001*predict(mdlPowerRequired, [dispatchsol.leanIn(i), dispatchsol.gasIn(i), dispatchsol.hydrogenIn(i)]);
    result.methanolProdcution(i) = predict(mdlMassFlowMEOH, [dispatchsol.leanIn(i), dispatchsol.gasIn(i), dispatchsol.hydrogenIn(i)]);
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

% Tank
figure
plot(X,result.tankFilling)
xlabel("time in h");
ylabel("tank level in kmol");

figure
plot(X,result.tankPressure)
xlabel("time in h");
ylabel("pressure in bar");

% Methanol
figure
plot(X,result.methanolProdcution)
xlabel("time in h");
ylabel("mass flow methanol in kg/h");
