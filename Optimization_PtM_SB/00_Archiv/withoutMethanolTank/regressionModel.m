function mdl = regressionModel()

pathToFile = "C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\02_Modell\02_AspenPlus\99_Daten\AbsorptionDesorption_MethanolSynthese_Distillation_20221204";
T = readtable(pathToFile, "Sheet", "Tabelle1", 'VariableNamingRule','preserve');

counter = 1;
for i = 1:size(T,1)
    if T{i,2}{1} == "Errors"
        
    else
        idx(counter) = i;
        counter = counter + 1;
    end
end

tblMatrix = T{idx,3:end};
X1 = tblMatrix(:,1:3);
massFlowMEOHTankIn = tblMatrix(:,15);
massFlowH2OTankIn = tblMatrix(:,16);
powerRequired1 = abs(tblMatrix(:,19)) + abs(tblMatrix(:,21)) + abs(tblMatrix(:,22))...
            + abs(tblMatrix(:,23)) + abs(tblMatrix(:,25)) + abs(tblMatrix(:,26))...
            + abs(tblMatrix(:,28)) + abs(tblMatrix(:,29));
massFlowBiogasOut = tblMatrix(:,4);
moleFracCH4BiogasOut = tblMatrix(:,5);

massFlowMEOHProd = tblMatrix(:,42);
powerRequired2 = abs(tblMatrix(:,43)) + abs(tblMatrix(:,44)) + abs(tblMatrix(:,45)) + abs(tblMatrix(:,46));


%% Modellerstellung
modelType = 'linear';

mdlMassFlowMEOHTankIn = fitlm(X1,massFlowMEOHTankIn,modelType);
mdlMassFlowH2OTankIn = fitlm(X1,massFlowH2OTankIn,modelType);
mdlPowerRequired1 = fitlm(X1,powerRequired1,modelType);
mdlMassFlowBiogasOut = fitlm(X1,massFlowBiogasOut,modelType);
mdlMoleFracCH4BiogasOut = fitlm(X1,moleFracCH4BiogasOut,modelType);
mdlMassFlowMEOHProd = fitlm(X1,massFlowMEOHProd,modelType);
mdlPowerRequired2 = fitlm(X1,powerRequired2,modelType);

mdl = {mdlMassFlowMEOHTankIn, mdlMassFlowH2OTankIn, mdlPowerRequired1, mdlMassFlowBiogasOut, mdlMoleFracCH4BiogasOut, mdlMassFlowMEOHProd, mdlPowerRequired2};
