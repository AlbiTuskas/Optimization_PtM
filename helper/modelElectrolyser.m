function [mdl] = modelElectrolyser(param)

pathToFile = "C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\06_Daten\03_Elektolyseur\Modell_Elektrolyseur";
T = readtable(pathToFile, "Sheet", "Data Tremel", "Range", "A2:C11", 'VariableNamingRule','preserve');

if param.electrolyser.modelType == "poly1"
    x = T{4:end,2};
    y = T{4:end,3};
elseif param.electrolyser.modelType == "exp2"
    x = T{:,2};
    y = T{:,3};
end

mdl = fit(x,y,param.electrolyser.modelType);
