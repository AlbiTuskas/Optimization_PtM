% Erstellen der Validierungsfälle
clear all

%% Parameter
systemparameter
len = param.len;

%% Kennfeld der Anlage
%mdl = regressionModel();
load('C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\02_Modell\01_Matlab\10_Projects\Optimization_PtM\data\mdl.mat');
mdlElectrolyser = modelElectrolyser(param);
mdl{numel(mdl)+1} = mdlElectrolyser;

mdlPowerRequiredABSDESSYNT = mdl{1};
mdlPowerRequiredDIS = mdl{2};
mdlMassFlowBiogasOut = mdl{3};
mdlMoleFlowBiogasOut = mdl{4};
mdlDensityBiogasOut = mdl{5};
mdlMoleFracCH4BiogasOut = mdl{6};
mdlMassFlowMEOHTankIn = mdl{7};
mdlMoleFlowMEOHTankIn = mdl{8};
mdlDensityMEOHTankIn = mdl{9};
mdlMassFlowMEOHProd = mdl{10};
mdlMoleFlowMEOHTankOut = mdl{11};

%% Erstellen der Validierungsfälle

numberOfFactorLevels = 10;
dFF = fullfact([numberOfFactorLevels numberOfFactorLevels numberOfFactorLevels]);
numberOfCases = size(dFF,1);

leanInValues = linspace(100,300,11);
gasInValues = linspace(3,12,11);
powerInElectrolyserValues = [0;15.5;27;40;54;72;90;112;135;165;200];
powerInBatteryValues = linspace(0,0,numberOfCases);
powerBatteryElectrolyserValues = linspace(0,0,numberOfCases);
powerSoldValues = linspace(0,0,numberOfCases);

leanInArray = 100 + (dFF(:,1) - 1)*(300-100) / (numberOfFactorLevels - 1);
gasInArray = 3 + (dFF(:,2) - 1)*(12-3) / (numberOfFactorLevels - 1);
% powerInElectrolyserArray =  0 + (dFF(:,3) - 1)*(200-0) / (numberOfFactorLevels - 1);
% powerInBatteryArray = powerInElectrolyserArray/param.battery.efficiency;
% powerBatteryElectrolyserArray = powerInElectrolyserArray;
powerInElectrolyserArray = linspace(0,0,numberOfCases);
powerInBatteryArray = 0 + (dFF(:,3) - 1)*(200-0) / (numberOfFactorLevels - 1) / param.battery.efficiency;
powerBatteryElectrolyserArray = powerInBatteryArray * param.battery.efficiency;
% powerInBatteryArray = linspace(0,0,numberOfCases);
% powerBatteryElectrolyserArray = linspace(0,0,numberOfCases);
% powerSoldArray = linspace(0,0,numberOfCases);

% numberOfCases = 10;
% 
% leanInValues = linspace(100,300,11);
% gasInValues = linspace(3,12,11);
% powerInElectrolyserValues = [0;15.5;27;40;54;72;90;112;135;165;200];
% powerInBatteryValues = linspace(0,0,numberOfCases);
% powerBatteryElectrolyserValues = linspace(0,0,numberOfCases);
% powerSoldValues = linspace(0,0,numberOfCases);
% 
% leanInArray = leanInValues;
% gasInArray = gasInValues;
% powerInElectrolyserArray =  powerInElectrolyserValues;
% powerInBatteryArray = linspace(0,0,numberOfCases);
% powerBatteryElectrolyserArray = linspace(0,0,numberOfCases);
% powerSoldArray = linspace(0,0,numberOfCases);

counter = 1;
overallCosts = zeros(numberOfCases,1);

dFFprices = fullfact([10 10]);
methanolPrice = 1 + (dFFprices(:,1) - 1)*(100-10) / (10 - 1);
biogasPrice = 0.1 + (dFFprices(:,2) - 1)*(10-1) / (10 - 1);

% write variables to local variables for speed
batteryEfficiency = param.battery.efficiency;
sampleTime = param.sampleTime;
electrolyserConstant = param.electrolyser.constant;
kgTokmolH2 = param.kgTokmolH2;
kgTokmolMEOHTank = param.kgTokmolMEOHTank;
sol.leanIn(:,1) = zeros(len,1);
sol.gasIn(:,1) = zeros(len,1);
sol.hydrogenIn(:,1) = zeros(len,1);
sol.meohTankOut(:,1) = zeros(len,1);
sol.powerInElectrolyser(:,1) = zeros(len,1);
sol.powerInBattery(:,1) = zeros(len,1);
sol.powerBatteryElectrolyser(:,1) = zeros(len,1);
sol.powerSold(:,1) = zeros(len,1);
sol.hydrogenSold(:,1) = zeros(len,1);
sol = repmat(sol,numberOfCases,1);


for idx = 1:1
    idx
    param.costs.methanol = methanolPrice(idx);
    param.costs.biogas = biogasPrice(idx);
    param.costs.hydrogen = 1;

    for i = 1:numberOfCases
        %i
        leanIn = leanInArray(i)*ones(len,1);
        gasIn = gasInArray(i)*ones(len,1);
        powerInElectrolyser = powerInElectrolyserArray(i)*ones(len,1);
        powerInBattery = powerInBatteryArray(i)*ones(len,1);
        powerBatteryElectrolyser = powerBatteryElectrolyserArray(i)*ones(len,1);
    
        powerInNominal = (powerInElectrolyser + batteryEfficiency*powerBatteryElectrolyser) / 100;
        efficiencyElectrolyser = feval(mdlElectrolyser,powerInNominal);
        for j = 1:len
            if efficiencyElectrolyser(j) < 0
                efficiencyElectrolyser(j) = 0;
            end
        end
        hydrogenProdElectrolyser = (powerInElectrolyser + batteryEfficiency*powerBatteryElectrolyser).*efficiencyElectrolyser*60*sampleTime / (electrolyserConstant*100);
        hydrogenProdElectrolyser = hydrogenProdElectrolyser*(1/kgTokmolH2);
        hydrogenIn = max(min(hydrogenProdElectrolyser/kgTokmolH2,1),0.1);
        hydrogenSold = max(0,hydrogenProdElectrolyser - hydrogenIn);
        powerSold = max(powerInBattery*batteryEfficiency - powerBatteryElectrolyser,0);
        
        moleFlowMEOHTankIn = feval(mdlMoleFlowMEOHTankIn, [leanIn,gasIn,hydrogenIn]);
        meohTankOut = moleFlowMEOHTankIn*(1/kgTokmolMEOHTank);
        
        sol(i).leanIn(:,1) = leanIn;
        sol(i).gasIn(:,1) = gasIn;
        sol(i).hydrogenIn(:,1) = hydrogenIn;
        sol(i).meohTankOut(:,1) = meohTankOut;
        sol(i).powerInElectrolyser(:,1) = powerInElectrolyser;
        sol(i).powerInBattery(:,1) = powerInBattery;
        sol(i).powerBatteryElectrolyser(:,1) = powerBatteryElectrolyser;
        sol(i).powerSold(:,1) = powerSold;
        sol(i).hydrogenSold(:,1) = hydrogenSold;
        
        [result(i), costs(i)] = calculateResults(sol(i),len,mdl,param);
        overallCosts(i) = costs(i).sum.all;
    end
    
    [~, indexMin] = min(overallCosts);
    resultFinal = result(indexMin);
    costsFinal = costs(indexMin);
    solFinal = sol(indexMin);

    counter = counter + 1;
    column = string(xlscol(counter));
    variables(1:9,1) = [solFinal.leanIn(1,1); solFinal.gasIn(1,1); solFinal.hydrogenIn(1,1); solFinal.meohTankOut(1,1); solFinal.powerInElectrolyser(1,1); solFinal.powerInBattery(1,1); solFinal.powerBatteryElectrolyser(1,1); solFinal.powerSold(1,1); solFinal.hydrogenSold(1,1)];
    
    writeToExcel(param,costsFinal,resultFinal,variables,column);
end

for i = 1:numberOfCases
    ydataAll(i) = costs(i).sum.all;
    ydataMethanol(i) = costs(i).sum.methanol;
    ydataBiogas(i) = costs(i).sum.biogas;
    ydataPowerPlant(i) = costs(i).sum.powerInPlant;
    ydataPowerElectrolyser(i) = costs(i).sum.powerInElectrolyser;
    ydataTankMEOH(i) = costs(i).sum.tankMEOH;
    ydataHydrogenSold(i) = costs(i).sum.hydrogenSold;
end

xdata = 1:numberOfCases;

figure
plot(xdata,ydataAll);
hold on
plot(xdata,ydataMethanol);
plot(xdata,ydataBiogas);
plot(xdata,ydataPowerPlant);
plot(xdata,ydataPowerElectrolyser);
plot(xdata,ydataHydrogenSold);
legend("All","Methanol","Biogas","Power Plant","Power Electrolyser","Hydrogen Sold");



