clear all
close all

addpath('C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\02_Modell\01_Matlab\10_Projects\Optimization_PtM\helper')

%% Parameter
systemparameter
len = param.len;

%% Kennfeld der Anlage
%mdl = regressionModel();
load('C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\02_Modell\01_Matlab\10_Projects\Optimization_PtM\data\mdl.mat');
mdlElectrolyser = modelElectrolyser(param);
mdl{numel(mdl)+1} = mdlElectrolyser;


%% Definition der Optimierungsumgebung
lb(1:len) = param.lbLeanIn;
lb(len+1:2*len) = param.lbGasIn;
lb(2*len+1:3*len) = param.lbHydrogenIn;
lb(3*len+1:4*len) = param.lbMeohTankOut;
lb(4*len+1:5*len) = param.lbPowerInElectrolyser;
lb(5*len+1:6*len) = param.lbPowerInBattery;
lb(6*len+1:7*len) = param.lbPowerBatteryElectrolyser;
lb(7*len+1:8*len) = param.lbPowerSold;
lb(8*len+1:9*len) = param.lbHydrogenSold;

ub(1:len) = param.ubLeanIn;
ub(len+1:2*len) = param.ubGasIn;
ub(2*len+1:3*len) = param.ubHydrogenIn;
ub(3*len+1:4*len) = param.ubMeohTankOut;
ub(4*len+1:5*len) = param.ubPowerInElectrolyser;
ub(5*len+1:6*len) = param.ubPowerInBattery;
ub(6*len+1:7*len) = param.ubPowerBatteryElectrolyser;
ub(7*len+1:8*len) = param.ubPowerSold;
ub(8*len+1:9*len) = param.ubHydrogenSold;

FitnessFunction = @(x) objfcn(x,len,mdl,param);
ConstraintFunction = @(x) confcn(x,len,mdl,param);

ObjFunctionSurrogate = @(x) objconstrSurrogate(x,len,mdl,param);

nvars = param.numberOfVariables*len;

% Linear inqeuality constraints

A = zeros(5*len-2,nvars);
b = zeros(5*len-2,1);

for i = 1:len
    A(i,4*len+i) = 1;
    A(i,6*len+i) = 1;
end

for i = 1:len
    A(i+len,5*len+1:5*len+i) = param.sampleTime*param.battery.efficiency / 60;
    A(i+len,6*len+1:6*len+i) = - param.sampleTime / 60;
    A(i+len,7*len+1:7*len+i) = - param.sampleTime / 60;

    A(i+len*2,5*len+1:5*len+i) = - param.sampleTime*param.battery.efficiency / 60;
    A(i+len*2,6*len+1:6*len+i) = param.sampleTime / 60;
    A(i+len*2,7*len+1:7*len+i) = param.sampleTime / 60;

    if i < len
        A(i+3*len,3*len+i+1) = 1;
        A(i+3*len,3*len+i) = -1;
    
        A(i-1+4*len,3*len+i+1) = -1;
        A(i-1+4*len,3*len+i) = 1;
    end
end

b(1:len) = 200;
b(len+1:2*len) = param.battery.capacity - param.battery.initialCharge;
b(2*len+1:3*len) = -10 + param.battery.initialCharge;
b(3*len:4*len-1) = 0.05;
b(4*len:5*len-2) = 0.05;

%% Solve 
rng default % For reproducibility

for i = 1:param.numberOfIterations
    if param.solverType == "ga"
        options = optimoptions('ga','Display','iter','ConstraintTolerancFe',1e-6, 'FunctionTolerance',1e-8,'UseParallel',true);
        [x(:,i),fval(i)] = ga(FitnessFunction,nvars,[],[],[],[],lb,ub,ConstraintFunction,options);
    elseif param.solverType == "patternsearch"
        [sol0, x0] = generateRandomInitialValues(param,len);
        options = optimoptions('patternsearch','Display','iter','ConstraintTolerance',1e-6,'UseParallel',true);
        [x,fval] = patternsearch(FitnessFunction,x0,[],[],[],[],lb,ub,ConstraintFunction,options);
    elseif param.solverType == "surrogateopt"
        %options = optimoptions('surrogateopt','Display','iter','UseParallel',true);
        options = optimoptions('surrogateopt','PlotFcn','surrogateoptplot','MaxFunctionEvaluations',1000,'UseParallel',true);
        [x(:,i),fval(i)] = surrogateopt(ObjFunctionSurrogate,lb,ub,options);
        %x = xtemp(1:len)
    elseif param.solverType == "fmincon"
        [sol0, x0] = generateRandomInitialValues(param,len);
        options = optimoptions('fmincon','Display','iter','Algorithm','sqp','MaxIterations',1e6,'MaxFunctionEvaluations',1000,'UseParallel',false);
        [x(:,i),fval(i)] = fmincon(FitnessFunction,x0,A,b,[],[],lb,ub,ConstraintFunction,options);
    elseif param.solverType == "globalSearch"
        [sol0, x0] = generateRandomInitialValues(param,len);
        options = optimoptions('fmincon','Display','iter','Algorithm','sqp','MaxIterations',1e6,'MaxFunctionEvaluations',1e9,'UseParallel',true);
        problem = createOptimProblem("fmincon",...
                    x0=x0,...
                    objective=FitnessFunction,...
                    lb=lb,...
                    ub=ub,...
                    nonlcon=ConstraintFunction,...
                    options=options);
        gs = GlobalSearch('Display','iter');
        [x,fval] = run(gs,problem);
    end
end

%% Berechnung der Ergebnisse
[~, idxmax] = min(fval);

sol.leanIn(:,1) = x(1:len,idxmax);
sol.gasIn(:,1) = x(len+1:2*len,idxmax);
sol.hydrogenIn(:,1) = x(2*len+1:3*len,idxmax);
sol.meohTankOut(:,1) = x(3*len+1:4*len,idxmax);
sol.powerInElectrolyser(:,1) = x(4*len+1:5*len,idxmax);
sol.powerInBattery(:,1) = x(5*len+1:6*len,idxmax);
sol.powerBatteryElectrolyser(:,1) = x(6*len+1:7*len,idxmax);
sol.powerSold(:,1) = x(7*len+1:8*len,idxmax);
sol.hydrogenSold(:,1) = x(8*len+1:9*len,idxmax);

[result, costs] = calculateResults(sol,len,mdl,param);

%% Visualisierung

visualization(sol,len,result,costs,param);
