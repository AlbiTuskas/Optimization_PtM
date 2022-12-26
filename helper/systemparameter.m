% Systemparameter

addpath('C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\02_Modell\01_Matlab\Files extern');

%% Festlegen der Systemparameter
% Solver
param.solverType = "fmincon";
param.numberOfIterations = 1;
param.numberOfVariables = 9;
param.sampleTime = 60;
param.numberOfHours = 5;
param.tol = 0.0001;
param.initialValuesDifferent = true;

% Optimierungsvariablen Grenzen
param.lbLeanIn = 100;
param.lbGasIn = 3;
param.lbHydrogenIn = 0.1;
param.lbMeohTankOut = 0;
param.lbPowerInElectrolyser = 0;
param.lbPowerInBattery = 0;
param.lbPowerBatteryElectrolyser = 0;
param.lbPowerSold = 0;
param.lbHydrogenSold = 0;

param.ubLeanIn = 300;
param.ubGasIn = 12;
param.ubHydrogenIn = 1;
param.ubMeohTankOut = 10;
param.ubPowerInElectrolyser = 200;
param.ubPowerInBattery = 0;
param.ubPowerBatteryElectrolyser = 0;
param.ubPowerSold = 0;
param.ubHydrogenSold = 0;

param.lb = [param.lbLeanIn; param.lbGasIn; param.lbHydrogenIn; param.lbMeohTankOut; param.lbPowerInElectrolyser; param.lbPowerInBattery; param.lbPowerBatteryElectrolyser; param.lbPowerSold; param.lbHydrogenSold];
param.ub = [param.ubLeanIn; param.ubGasIn; param.ubHydrogenIn; param.ubMeohTankOut; param.ubPowerInElectrolyser; param.ubPowerInBattery; param.ubPowerBatteryElectrolyser; param.ubPowerSold; param.ubHydrogenSold];

% Strom/Elektrolyseur
param.pvScale = 700;
param.electrolyser.constant = 286151.3637877446;
param.electrolyser.modelType = "exp2";   % "poly1" für linear
                                         % "exp2" für exponentiell (besserer fit)
% Tanks
param.tankH2LowerBound = 15;
param.tankH2UpperBound = 35;
param.tankMEOHLowerBound = 1;
param.tankMEOHUpperBound = 10;

param.tankH2InitialPressure = 0.5*(param.tankH2UpperBound - param.tankH2LowerBound) + param.tankH2LowerBound;
param.tankH2Volume = 50;
param.tankMEOHInitialPressure = 0.5*(param.tankMEOHUpperBound - param.tankMEOHLowerBound) + param.tankMEOHLowerBound;
param.tankMEOHVolume = 50;

% Batterie
param.battery.capacity = 3000;
param.battery.efficiency = 0.9;
param.battery.auxiliaryPower = 0.05;
param.battery.initialCharge = 0.5*param.battery.capacity;

% Chemische/physikalische/thermodynamische Parameter
param.kgTokmolH2 = 1/2.016;
param.kgTokmolMEOHTank = 1/25.01181;
param.R = 8.314;
param.Tamb = 21;
param.T0 = 273.15;

% Biogas
param.CH4.heizwert = 9.94;          % kWh/m^3
param.CH4.brennwert = 11.07;        % kWh/m^3
param.biogas.heizwert = [4; 7.5];   % kWh/m^3

% Auslastung
param.maxOutputElectrolyser = 2.576;
param.maxOutputDistillation = 6.1150;
param.maxOutputPlant = 3.2;

% Einlesen der Kostendaten
pathToFile = "C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\06_Daten\02_Energie\energy-charts_Stromproduktion_und_Börsenstrompreise_in_Deutschland_in_Woche_49_2021_Excel";
T = readtable(pathToFile, 'VariableNamingRule','preserve');
energyCosts = T{:,6};

start = 2;
finish = start + 4*param.numberOfHours;
idx = start:4:finish;
param.len = length(idx)-1;

param.costs.energy = energyCosts(idx(1:end-1)) / 1000;      % in EUR/kWh      
param.costs.methanol = 4;                         % in EUR/kg     "www.statista.de"      535 €/ton
param.costs.hydrogen = 1;                                   % in EUR/kg
param.costs.biogas = 0.2;                                   % in EUR/kWh   
param.costs.carbondioxide = 0; 
param.costs.methanolTank = param.costs.methanol / 2;        % in EUR/kg
param.costs.hydrogenTank = param.costs.hydrogen;            % in EUR/kg
param.costs.energySoldFactor = 0.8;
param.costs.energySold = param.costs.energy*param.costs.energySoldFactor;         % in EUR/kWh




param.ArrayAll = [param.solverType;
                    param.numberOfIterations;
                    param.numberOfVariables;
                    param.sampleTime;
                    param.numberOfHours;
                    param.tol;
                    param.initialValuesDifferent;
                    
                    param.lbLeanIn;
                    param.lbGasIn;
                    param.lbHydrogenIn;
                    param.lbPowerInElectrolyser;
                    param.lbMeohTankOut;
                    param.lbPowerInBattery;
                    param.lbPowerBatteryElectrolyser;
                    param.lbPowerSold;
                    param.lbHydrogenSold;
                    
                    param.ubLeanIn;
                    param.ubGasIn;
                    param.ubHydrogenIn;
                    param.ubPowerInElectrolyser;
                    param.ubMeohTankOut;
                    param.ubPowerInBattery;
                    param.ubPowerBatteryElectrolyser;
                    param.ubPowerSold;
                    param.ubHydrogenSold;
                    
                    param.pvScale;
                    param.electrolyser.constant;
                    param.electrolyser.modelType;  
               
                    param.tankH2LowerBound;
                    param.tankH2UpperBound;
                    param.tankMEOHLowerBound;
                    param.tankMEOHUpperBound;
                    
                    param.tankH2InitialPressure;
                    param.tankH2Volume;
                    param.tankMEOHInitialPressure;
                    param.tankMEOHVolume;
                    
                    param.battery.capacity;
                    param.battery.efficiency;
                    param.battery.auxiliaryPower;
                    param.battery.initialCharge;
                    
                    param.kgTokmolH2;
                    param.R;
                    param.Tamb;
                    param.T0;
                    
                    param.len;
                         
                    param.costs.methanol;
                    param.costs.hydrogen;                      
                    param.costs.biogas;
                    param.costs.carbondioxide; 
                    param.costs.methanolTank;    
                    param.costs.hydrogenTank;  
                    param.costs.energySoldFactor];

param.validationArray = [param.lbLeanIn;
                    param.lbGasIn;
                    param.lbHydrogenIn;
                    param.lbPowerInElectrolyser;
                    param.lbMeohTankOut;
                    param.lbPowerInBattery;
                    param.lbPowerBatteryElectrolyser;
                    param.lbPowerSold;
                    param.lbHydrogenSold;
                    
                    param.ubLeanIn;
                    param.ubGasIn;
                    param.ubHydrogenIn;
                    param.ubPowerInElectrolyser;
                    param.ubMeohTankOut;
                    param.ubPowerInBattery;
                    param.ubPowerBatteryElectrolyser;
                    param.ubPowerSold;
                    param.ubHydrogenSold;
                    
                    param.electrolyser.modelType;  
               
                    param.tankH2LowerBound;
                    param.tankH2UpperBound;
                    param.tankMEOHLowerBound;
                    param.tankMEOHUpperBound;
                    
                    param.tankH2InitialPressure;
                    param.tankH2Volume;
                    param.tankMEOHInitialPressure;
                    param.tankMEOHVolume;
                    
                    param.battery.capacity;
                    param.battery.efficiency;
                    param.battery.auxiliaryPower;
                    param.battery.initialCharge;
                         
                    param.costs.methanol;
                    param.costs.hydrogen;                      
                    param.costs.biogas;
                    param.costs.carbondioxide; 
                    param.costs.methanolTank;    
                    param.costs.hydrogenTank;  
                    param.costs.energySoldFactor];
