clear all
close all

addpath('C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\02_Modell\01_Matlab\10_Projects\Optimization_PtM_Costs')

%% Parameter
systemparameter
len = param.len;

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


%% Definition der Optimierungsumgebung
lb(1:len) = param.lbLeanIn;
lb(len+1:2*len) = param.lbGasIn;
lb(2*len+1:3*len) = param.lbHydrogenIn;
lb(3*len+1:4*len) = param.lbPowerInElectrolyser;
lb(4*len+1:5*len) = param.lbMeohOut;
lb(5*len+1:6*len) = param.lbPowerInBattery;
lb(6*len+1:7*len) = param.lbPowerBatteryElectrolyser;
lb(7*len+1:8*len) = param.lbPowerSold;
lb(8*len+1:9*len) = param.lbHydrogenSold;

ub(1:len) = param.ubLeanIn;
ub(len+1:2*len) = param.ubGasIn;
ub(2*len+1:3*len) = param.ubHydrogenIn;
ub(3*len+1:4*len) = param.ubPowerInElectrolyser;
ub(4*len+1:5*len) = param.ubMeohOut;
ub(5*len+1:6*len) = param.ubPowerInBattery;
ub(6*len+1:7*len) = param.ubPowerBatteryElectrolyser;
ub(7*len+1:8*len) = param.ubPowerSold;
ub(8*len+1:9*len) = param.ubHydrogenSold;

FitnessFunction = @(x) objfcn(x,len,mdl,param);
ConstraintFunction = @(x) confcn(x,len,mdl,param);

ObjFunctionSurrogate = @(x) objconstrSurrogate(x,len,{mdlPowerRequired1, mdlPowerRequired2, mdlMassFlowMEOHTankIn, mdlMassFlowH2OTankIn, mdlElectrolyser,mdlMassFlowMEOHProd},power,param);

nvars = param.numberOfVariables*len;

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
        [x,fval] = surrogateopt(ObjFunctionSurrogate,lb,ub);
    elseif param.solverType == "fmincon"
        [sol0, x0] = generateRandomInitialValues(param,len);
        options = optimoptions('fmincon','Display','iter','Algorithm','sqp','MaxIterations',1e6,'MaxFunctionEvaluations',1e9,'UseParallel',true);
        [x(:,i),fval(i)] = fmincon(FitnessFunction,x0,[],[],[],[],lb,ub,ConstraintFunction,options);
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
sol.powerInElectrolyser(:,1) = x(3*len+1:4*len,idxmax);
sol.meohOut(:,1) = x(4*len+1:5*len,idxmax);
sol.powerInBattery(:,1) = x(5*len+1:6*len,idxmax);
sol.powerBatteryElectrolyser(:,1) = x(6*len+1:7*len,idxmax);
sol.powerSold(:,1) = x(7*len+1:8*len,idxmax);
sol.hydrogenSold(:,1) = x(8*len+1:9*len,idxmax);

[result, costs] = calculateResults(sol,len,mdl,param);

%% Visualisierung

visualization(sol,len,result,param);
