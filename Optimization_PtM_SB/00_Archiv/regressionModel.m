function mdl = regressionModel()

variableColumns = [3,4,5];
variableNamesNew = ["Mass flow in liquid [kg/hr]", "Mass flow in gas [kg/hr]", "Mass flow in H2 [kg/hr]"];
pathToFile = "C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\02_Modell\02_AspenPlus\99_Daten\AbsorptionDesorption_MethanolSynthese_20221204";
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
X = tblMatrix(:,1:3);
massFlowMEOH = tblMatrix(:,15);
powerRequired = abs(tblMatrix(:,19)) + abs(tblMatrix(:,20)) + abs(tblMatrix(:,21)) + abs(tblMatrix(:,22))...
            + abs(tblMatrix(:,23)) + abs(tblMatrix(:,24)) + abs(tblMatrix(:,25)) + abs(tblMatrix(:,26))...
            + abs(tblMatrix(:,27)) + abs(tblMatrix(:,28)) + abs(tblMatrix(:,29));
massFlowBiogasOut = tblMatrix(:,4);
moleFracCH4BiogasOut = tblMatrix(:,5);

tbl.Properties.VariableNames(1) = "LEANIN";
tbl.Properties.VariableNames(2) = "GASIN";
tbl.Properties.VariableNames(3) = "H2IN";

%mdl = fitlm(tbl,'FracH2DES ~ LEANIN + GASIN + H2IN + LEANIN*GASIN + LEANIN*H2IN + GASIN*H2IN + LEANIN^2 + GASIN^2 + H2IN^2')
mdlMassFlowMEOH = fitlm(X,massFlowMEOH,'quadratic');
mdlPowerRequired = fitlm(X,powerRequired,'quadratic');
mdlMassFlowBiogasOut = fitlm(X,massFlowBiogasOut,'quadratic');
mdlMoleFracCH4BiogasOut = fitlm(X,moleFracCH4BiogasOut,'quadratic');

mdl = {mdlMassFlowMEOH, mdlPowerRequired, mdlMassFlowBiogasOut, mdlMoleFracCH4BiogasOut};
