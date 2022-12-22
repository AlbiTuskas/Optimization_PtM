function mdl = modelElectrolyzer()

pathToFile = "C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\06_Daten\03_Elektolyseur\Modell_Elektrolyseur";
T = readtable(pathToFile, "Sheet", "Data Tremel", "Range", "A2:C11", 'VariableNamingRule','preserve');

x = T{:,2};
y = T{:,3};

mdl = fit(x,y,'exp2');
