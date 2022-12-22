% Systemparameter

addpath('C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\02_Modell\01_Matlab\Files extern');

%% Festlegen der Systemparameter
% Solver
param.solverType = "fmincon";
param.numberOfIterations = 1;
param.numberOfVariables = 9;
param.sampleTime = 60;
param.numberOfHours = 167;
param.tol = 0.0001;
param.initialValuesDifferent = true;

% Optimierungsvariablen Grenzen
param.lbLeanIn = 100;
param.lbGasIn = 3;
param.lbHydrogenIn = 0.1;
param.lbPowerInElectrolyser = 0;
param.lbMeohOut = 0;
param.lbPowerInBattery = 0;
param.lbPowerBatteryElectrolyser = 0;
param.lbPowerSold = 0;
param.lbHydrogenSold = 0;

param.ubLeanIn = 300;
param.ubGasIn = 12;
param.ubHydrogenIn = 1;
param.ubPowerInElectrolyser = 200;
param.ubMeohOut = 10;
param.ubPowerInBattery = 200;
param.ubPowerBatteryElectrolyser = 200;
param.ubPowerSold = 100;
param.ubHydrogenSold = 5;

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
param.kgTokmolMEOH = 1/32.04;
param.kgTokmolH2O = 1/18.01528;
param.MEOHToWaterRatio = 1.776;
param.R = 8.314;
param.Tamb = 21;
param.T0 = 273.15;


% Einlesen der Kostendaten
pathToFile = "C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\06_Daten\02_Energie\energy-charts_Stromproduktion_und_Börsenstrompreise_in_Deutschland_in_Woche_49_2021_Excel";
T = readtable(pathToFile, 'VariableNamingRule','preserve');
energyCosts = T{:,6};

start = 2;
finish = start + 4*param.numberOfHours;
idx = start:4:finish;
param.len = length(idx)-1;

param.costs.energy = energyCosts(idx(1:end-1)) / 1000;   % in EUR/kwh      
param.costs.methanol = 7535 / 1000;              % in EUR/kg     "www.statista.de"
param.costs.hydrogen = 8;                      % in EUR/kg
param.costs.biogas = 0;
param.costs.carbondioxide = 0; 
param.costs.methanolTank = param.costs.methanol / 2;    % in EUR/kg
param.costs.hydrogenTank = param.costs.hydrogen;    % in EUR/kg
param.costs.energySoldFactor = 0.8;
param.costs.energySold = param.costs.energy*param.costs.energySoldFactor;         % in EUR/kwh

param.costs.operatingPointChangePlant = 0;

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
                    param.lbMeohOut;
                    param.lbPowerInBattery;
                    param.lbPowerBatteryElectrolyser;
                    param.lbPowerSold;
                    param.lbHydrogenSold;
                    
                    param.ubLeanIn;
                    param.ubGasIn;
                    param.ubHydrogenIn;
                    param.ubPowerInElectrolyser;
                    param.ubMeohOut;
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
                    
                    param.kgTokmolH2
                    param.kgTokmolMEOH;
                    param.kgTokmolH2O;
                    param.MEOHToWaterRatio;
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
                    param.costs.energySoldFactor;
                    param.costs.operatingPointChangePlant];

param.validationArray = [param.lbLeanIn;
                    param.lbGasIn;
                    param.lbHydrogenIn;
                    param.lbPowerInElectrolyser;
                    param.lbMeohOut;
                    param.lbPowerInBattery;
                    param.lbPowerBatteryElectrolyser;
                    param.lbPowerSold;
                    param.lbHydrogenSold;
                    
                    param.ubLeanIn;
                    param.ubGasIn;
                    param.ubHydrogenIn;
                    param.ubPowerInElectrolyser;
                    param.ubMeohOut;
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
                    param.costs.energySoldFactor;
                    param.costs.operatingPointChangePlant];
