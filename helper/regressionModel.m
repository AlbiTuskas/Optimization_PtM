% function mdl = regressionModel()
% 
% pathToFile = "C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\06_Daten\01_Aspen Results\AbsorptionDesorption_MethanolSynthese_20221222_1";
% T1 = readtable(pathToFile, "Sheet", "Tabelle1", 'VariableNamingRule','preserve');
% 
% pathToFile = "C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\06_Daten\01_Aspen Results\Distillation_20221222";
% T2 = readtable(pathToFile, "Sheet", "Tabelle1", 'VariableNamingRule','preserve');
% 
% counter = 1;
% for i = 1:size(T1,1)
%     if T1{i,2}{1} == "Errors"
%         
%     else
%         idx(counter) = i;
%         counter = counter + 1;
%     end
% end
% idx = 1:1000;
% 
% tblMatrix1 = T1{idx,3:end};
% X1 = tblMatrix1(:,1:3);
% 
% % Methanol-Water
% massFlowMEOHTankIn = tblMatrix1(:,14);
% moleFlowMEOHTankIn = tblMatrix1(:,15);
% densityMEOHTankIn = tblMatrix1(:,16);
% 
% powerInPlantABSDESSYNT = abs(tblMatrix1(:,23)) + abs(tblMatrix1(:,25)) + abs(tblMatrix1(:,26))...
%             + abs(tblMatrix1(:,27)) + abs(tblMatrix1(:,29)) + abs(tblMatrix1(:,30))...
%             + abs(tblMatrix1(:,32)) + abs(tblMatrix1(:,33));
% 
% massFlowBiogasOut = tblMatrix1(:,4);
% moleFlowBiogasOut = tblMatrix1(:,5);
% denityBiogasOut = tblMatrix1(:,6);
% moleFracCH4BiogasOut = tblMatrix1(:,7);
% 
% tblMatrix2 = T2{:,3:end};
% X2 = tblMatrix2(:,1);
% massFlowMEOHProd = tblMatrix2(:,5);
% moleFlowMEOHTankOut = tblMatrix2(:,3);
% powerInPlantDIS = abs(tblMatrix2(:,6)) + abs(tblMatrix2(:,7)) + abs(tblMatrix2(:,8)) + abs(tblMatrix2(:,9));
% powerInPlantDIS(1) = 0;
% 
% %% Modellerstellung
% Y = [powerInPlantABSDESSYNT, massFlowBiogasOut, moleFlowBiogasOut, denityBiogasOut, moleFracCH4BiogasOut, ...
%         massFlowMEOHTankIn, moleFlowMEOHTankIn, densityMEOHTankIn];
% 
% numberValues = [1,3,4,5,6,7,8,9];
% 
% for idx = 1:size(Y,2)
%     number = numberValues(idx);
%     mse = 10^10;
%     for i = 1:9
%         for j = 1:9
%             for k = 1:9
%                 model = "poly" + string(i) + string(j) + string(k);
%                 mdltmp = fitlm(X1,Y(:,idx),model);
%                 if mdltmp.MSE <= mse
%                     mse = mdltmp.MSE;
%                     finalModel = model;
%                 end
%             end
%         end
%     end
%     mdl{number} = fitlm(X1,Y(:,idx),finalModel);
% end
% 
% modelType = 'quadratic';
% mdl{2} = fitlm(X2,powerInPlantDIS,modelType);
% mdl{10} = fitlm(X2,massFlowMEOHProd,modelType);
% mdl{11} = fitlm(X2,moleFlowMEOHTankOut,modelType);
% 
% % Electrolyser Model
% mdlElectrolyser = modelElectrolyser(param);
% mdl{numel(mdl)+1} = mdlElectrolyser;


%%
load('C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\02_Modell\01_Matlab\10_Projects\Optimization_PtM\data\mdl.mat');
mdlPowerRequiredABSDESSYNT = mdl{1};
mdlPowerRequiredDIS = mdl{2};
mdlMassFlowBiogasOut = mdl{3};
mdlMoleFlowBiogasOut = mdl{4};
mdlDensityBiogasOut = mdl{5};
mdlMoleFractionCH4BiogasOut = mdl{6};
mdlMassFlowMEOHTankIn = mdl{7};
mdlMoleFlowMEOHTankIn = mdl{8};
mdlMassFlowMEOHProd = mdl{10};
mdlMoleFlowMEOHTankOut = mdl{11};
mdlElectrolyser = mdl{end};

leanIn = 100:1:300;
gasIn = 3:0.1:12;
hydrogenIn = 0.1:0.01:1;
L = numel(leanIn);
G = numel(gasIn);
H = numel(hydrogenIn);

lookupTablePowerRequiredABSDESSYNT = zeros(L,G,H);
lookupTableMassFlowBiogasOut = zeros(L,G,H);
lookupTablePowerRequiredABSDESSYNT = zeros(L,G,H);
lookupTablePowerRequiredABSDESSYNT = zeros(L,G,H);
lookupTablePowerRequiredABSDESSYNT = zeros(L,G,H);
lookupTablePowerRequiredABSDESSYNT = zeros(L,G,H);
lookupTablePowerRequiredABSDESSYNT = zeros(L,G,H);
for i = 1:L
    i
    for j = 1:G
        for k = 1:H
            lookupTablePowerRequiredABSDESSYNT(i,j,k) = predict(mdlPowerRequiredABSDESSYNT,[leanIn(i),gasIn(j),hydrogenIn(k)]);
            lookupTableMassFlowBiogasOut(i,j,k) = predict(mdlMassFlowBiogasOut ,[leanIn(i),gasIn(j),hydrogenIn(k)]);
            lookupTableMoleFlowBiogasOut(i,j,k) = predict(mdlMoleFlowBiogasOut,[leanIn(i),gasIn(j),hydrogenIn(k)]);
            lookupTableDensityBiogasOut(i,j,k) = predict(mdlDensityBiogasOut,[leanIn(i),gasIn(j),hydrogenIn(k)]);
            lookupTableMoleFractionCH4BiogasOut(i,j,k) = predict(mdlMoleFractionCH4BiogasOut,[leanIn(i),gasIn(j),hydrogenIn(k)]);
            lookupTableMassFlowMEOHTankIn(i,j,k) = predict(mdlMassFlowMEOHTankIn,[leanIn(i),gasIn(j),hydrogenIn(k)]);
            lookupTableMoleFlowMEOHTankIn(i,j,k) = predict(mdlMoleFlowMEOHTankIn,[leanIn(i),gasIn(j),hydrogenIn(k)]);
            lookupTableMassFlowMEOHProd(i,j,k) = predict(mdlMassFlowMEOHProd,[leanIn(i),gasIn(j),hydrogenIn(k)]);
            lookupTableMoleFlowMEOHTankOut(i,j,k) = predict(mdlMoleFlowMEOHTankOut,[leanIn(i),gasIn(j),hydrogenIn(k)]);
        end
    end
end

% mdlMassFlowMEOHTankIn = fitlm(X1,massFlowMEOHTankIn,modelType);
% mdlMoleFlowMEOHTankIn = fitlm(X1,moleFlowMEOHTankIn,modelType);
% mdlDensityMEOHTankIn = fitlm(X1,densityMEOHTankIn,modelType);
% mdlPowerRequiredABSDESSYNT = fitlm(X1,powerInPlantABSDESSYNT,modelType);
% mdlMassFlowBiogasOut = fitlm(X1,massFlowBiogasOut,modelType)
% mdlMoleFlowBiogasOut = fitlm(X1,moleFlowBiogasOut,modelType);
% mdlDensityBiogasOut = fitlm(X1,denityBiogasOut,modelType);
% mdlMoleFracCH4BiogasOut = fitlm(X1,moleFracCH4BiogasOut,modelType);
% 
% mdlMassFlowMEOHProd = fitlm(X2,massFlowMEOHProd,modelType);
% mdlMoleFlowMEOHTankOut = fitlm(X2,moleFlowMEOHTankOut,modelType);
% mdlPowerRequiredDIS = fitlm(X2,powerInPlantDIS,modelType);
% 
% mdl = {mdlPowerRequiredABSDESSYNT,...
%         mdlPowerRequiredDIS,...
%         mdlMassFlowBiogasOut,...
%         mdlMoleFlowBiogasOut,...
%         mdlDensityBiogasOut,...
%         mdlMoleFracCH4BiogasOut,...
%         mdlMassFlowMEOHTankIn,...
%         mdlMoleFlowMEOHTankIn,...
%         mdlDensityMEOHTankIn,...
%         mdlMassFlowMEOHProd,...
%         mdlMoleFlowMEOHTankOut};

