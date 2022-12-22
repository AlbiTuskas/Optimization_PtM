function mdl = regressionModel()

pathToFile = "C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\06_Daten\01_Aspen Results\AbsorptionDesorption_MethanolSynthese_Distillation_20221204";
T1 = readtable(pathToFile, "Sheet", "Tabelle1", 'VariableNamingRule','preserve');

pathToFile = "C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\06_Daten\01_Aspen Results\Distillation_20221218";
T2 = readtable(pathToFile, "Sheet", "Tabelle1", 'VariableNamingRule','preserve');

counter = 1;
for i = 1:size(T1,1)
    if T1{i,2}{1} == "Errors"
        
    else
        idx(counter) = i;
        counter = counter + 1;
    end
end

tblMatrix1 = T1{idx,3:end};
X1 = tblMatrix1(:,1:3);
massFlowMEOHTankIn = tblMatrix1(:,15);
massFlowH2OTankIn = tblMatrix1(:,16);
powerInPlant1 = abs(tblMatrix1(:,19)) + abs(tblMatrix1(:,21)) + abs(tblMatrix1(:,22))...
            + abs(tblMatrix1(:,23)) + abs(tblMatrix1(:,25)) + abs(tblMatrix1(:,26))...
            + abs(tblMatrix1(:,28)) + abs(tblMatrix1(:,29));
massFlowBiogasOut = tblMatrix1(:,4);
moleFracCH4BiogasOut = tblMatrix1(:,5);

tblMatrix2 = T2{:,3:end};
X2 = tblMatrix2(:,1);
massFlowMEOHProd = tblMatrix2(:,3);
powerInPlant2 = abs(tblMatrix2(:,4)) + abs(tblMatrix2(:,5)) + abs(tblMatrix2(:,6)) + abs(tblMatrix2(:,7));


%% Modellerstellung
modelType = 'linear';

mdlMassFlowMEOHTankIn = fitlm(X1,massFlowMEOHTankIn,modelType);
mdlMassFlowH2OTankIn = fitlm(X1,massFlowH2OTankIn,modelType);
mdlPowerRequired1 = fitlm(X1,powerInPlant1,modelType);
mdlMassFlowBiogasOut = fitlm(X1,massFlowBiogasOut,modelType);
mdlMoleFracCH4BiogasOut = fitlm(X1,moleFracCH4BiogasOut,modelType);

mdlMassFlowMEOHProd = fitlm(X2,massFlowMEOHProd,modelType);
mdlPowerRequired2 = fitlm(X2,powerInPlant2,modelType);

mdl = {mdlMassFlowMEOHTankIn, mdlMassFlowH2OTankIn, mdlPowerRequired1, mdlMassFlowBiogasOut, mdlMoleFracCH4BiogasOut, mdlMassFlowMEOHProd, mdlPowerRequired2};
