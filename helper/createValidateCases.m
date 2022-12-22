% Erstellen der Validierungsfälle
clear all

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

%% Erstellen der Validierungsfälle

% leanInValues = linspace(100,300,11);
% gasInValues = linspace(3,12,11);
% hydrogenInValues = linspace(0.1,1,11);
% powerInElectrolyserValues = [0;15.5;27;40;54;72;90;112;135;165;200];
% % powerInElectrolyserValues = powerInElectrolyserValues / 2;
% meohOutValues = [0;1;2;3;4;5;6;7;8;9;10];
% powerInBatteryValues = zeros(11,1);%powerInElectrolyserValues;
% powerBatteryElectrolyserValues = zeros(11,1);%powerInElectrolyserValues / 2;
% powerSoldValues = zeros(11,1);
% hydrogenSoldValues = 0;
% 
% counter = 1;
% 
% for idx = 1:length(leanInValues)
%     for jdx = 1:length(powerInElectrolyserValues)
%         for kdx = 1:length(meohOutValues)
%             x(1:len) = leanInValues(idx);
%             x(len+1:2*len) = gasInValues(idx);
%             x(2*len+1:3*len) = hydrogenInValues(idx);
%             x(3*len+1:4*len) = powerInElectrolyserValues(jdx);
%             x(4*len+1:5*len) = meohOutValues(kdx);
%             x(5*len+1:6*len) = powerInBatteryValues(jdx);
%             x(6*len+1:7*len) = powerBatteryElectrolyserValues(jdx);
%             x(7*len+1:8*len) = powerSoldValues(jdx);
%             x(8*len+1:9*len) = hydrogenSoldValues;

leanInValues = linspace(100,300,11);
gasInValues = linspace(3,12,10);
hydrogenInValues = linspace(0.1,1,10);
powerInElectrolyserValues = [0;15.5;27;40;54;72;90;112;135;165;200];
meohOutValues = linspace(0,10,11);
powerInBatteryValues = linspace(0,200,11);
powerBatteryElectrolyserValues = linspace(0,200,11);
powerSoldValues = linspace(0,200,11);
hydrogenSoldValues = linspace(0,10,11);

counter = 1;
a = 1;

for idx1 = 1:length(leanInValues)
    for idx2 = 1:length(gasInValues)
        for idx3 = 1:length(hydrogenInValues)
            for idx4 = 1:length(powerInElectrolyserValues)
                for idx5 = 1:length(meohOutValues)
                    for idx6 = 1:length(powerInBatteryValues)
                        for idx7 = 1:length(powerBatteryElectrolyserValues)
                            for idx8 = 1:length(powerSoldValues)
                                for idx9 = 1:length(hydrogenSoldValues)
                                    x(1:len) = leanInValues(idx1);
                                    x(len+1:2*len) = gasInValues(idx2);
                                    x(2*len+1:3*len) = hydrogenInValues(idx3);
                                    x(3*len+1:4*len) = powerInElectrolyserValues(idx4);
                                    x(4*len+1:5*len) = meohOutValues(idx5);
                                    x(5*len+1:6*len) = powerInBatteryValues(idx6);
                                    x(6*len+1:7*len) = powerBatteryElectrolyserValues(idx7);
                                    x(7*len+1:8*len) = powerSoldValues(idx8);
                                    x(8*len+1:9*len) = hydrogenSoldValues(idx9);
                                    a = a + 1;
        

% x(1:len) = 300;
% x(len+1:2*len) = 12;
% x(2*len+1:3*len) = 1;
% x(3*len+1:4*len) = 100;
% x(4*len+1:5*len) = 5;
% x(5*len+1:6*len) = 100;
% x(6*len+1:7*len) = 100;
% x(7*len+1:8*len) = 0;
% x(8*len+1:9*len) = 0;

%% Berechnung der Ergebnisse
sol.leanIn(:,1) = x(1:len);
sol.gasIn(:,1) = x(len+1:2*len);
sol.hydrogenIn(:,1) = x(2*len+1:3*len);
sol.powerInElectrolyser(:,1) = x(3*len+1:4*len);
sol.meohOut(:,1) = x(4*len+1:5*len);
sol.powerInBattery(:,1) = x(5*len+1:6*len);
sol.powerBatteryElectrolyser(:,1) = x(6*len+1:7*len);
sol.powerSold(:,1) = x(7*len+1:8*len);
sol.hydrogenSold(:,1) = x(8*len+1:9*len);

[result, costs] = calculateResults(sol,len,mdl,param);

flag = true;
for i = 1:len
    if result.batteryCharge(i) > param.battery.capacity || result.batteryCharge(i) < 0
        flag = false;
    end
    if result.tankH2Pressure(i) > param.tankH2UpperBound || result.tankH2Pressure(i) < param.tankH2LowerBound
        flag = false;
    end
    if result.tankMEOHPressure(i) > param.tankMEOHUpperBound || result.tankMEOHPressure(i) < param.tankMEOHLowerBound
        flag = false;
    end
    if sol.powerInElectrolyser(i) + sol.powerBatteryElectrolyser(i) > 200
        flag = false;
    end
end

%% Visualisierung

%visualization(sol,len,result,param)

%% In Excel schreiben

if flag == true
    counter = counter + 1
    maxElectrolyser = 2.576;
    maxDistillation = 6.1150;
    maxPlant = 3.2;
    
    loadFactor(1:3,1) = [(result.methanolTankIn(1,1) + result.waterTankIn(1,1)) / maxPlant * 100; result.methanolProdcution(1,1) / maxDistillation * 100; result.hydrogenProdElectrolyser(1,1)/ param.kgTokmolH2 / maxElectrolyser * 100];
    
    column = string(xlscol(counter));
    
    variables(1:9,1) = [sol.leanIn(1,1); sol.gasIn(1,1); sol.hydrogenIn(1,1); sol.powerInElectrolyser(1,1); sol.meohOut(1,1); sol.powerInBattery(1,1); sol.powerBatteryElectrolyser(1,1); sol.powerSold(1,1); sol.hydrogenSold(1,1)];
    
%     writeToExcel(param,costs,flag,variables,column,loadFactor);
end

%         end
%     end
% end

                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

