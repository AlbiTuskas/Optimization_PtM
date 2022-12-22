function [] = visualization(sol,len,result,param)

close all

%% Visualisierung
X = 1:len;

% Power
figure
plot(X,sol.powerInBattery,X,sol.powerInElectrolyser,X,sol.powerBatteryElectrolyser,X,result.powerInPlant,X,sol.powerSold);
title("Power");
xlabel("time in h");
ylabel("power in kW");
legend("power in battery", "power in electrolyser", "power from battery to electrolyser", "power in plant", "power sold");

% % Electrolyzer 
% figure
% plot(X,result.efficiencyElectrolyser)
% title("Efficiency Electrolyser");
% xlabel("time in h");
% ylabel("efficiency [-]");

% Battery
figure
plot(X,result.batteryCharge)
title("Battery Charge");
xlabel("time in h");
ylabel("battery charge [kWh]");

% H2 Tank
% figure
% plot(X,result.tankH2Filling)
% title("H2-Tank");
% xlabel("time in h");
% ylabel("tank level in kmol");

figure
plot(X,result.tankH2Pressure)
title("H2-Tank");
xlabel("time in h");
ylabel("pressure in bar");

figure
plot(X,result.hydrogenProdElectrolyser/param.kgTokmolH2,X,sol.hydrogenSold,X,sol.hydrogenIn);
title("H2-Production");
xlabel("time in h");
ylabel("mass flow hydrogen in kg/h");
legend("hydrogen produced", "hydrogen sold", "hydrogen in plant");

% Methanol Tank
% figure
% plot(X,result.tankMEOHFilling)
% title("MEOH-Tank");
% xlabel("time in h");
% ylabel("tank level in kmol");

figure
plot(X,result.tankMEOHPressure)
title("MEOH-Tank");
xlabel("time in h");
ylabel("pressure in bar");

figure
plot(X,result.methanolTankIn + result.waterTankIn, X, sol.meohOut)
title("MEOH-Tank");
xlabel("time in h");
ylabel("mass flow in kg/h");
legend("methanol-water tank in", "methanol-water tank out");

% Methanol
figure
plot(X,result.methanolProdcution)
title("Methanol-Production");
xlabel("time in h");
ylabel("mass flow methanol in kg/h");

% Kosten
figure
plot(X,result.methanolProdcution.*param.costs.methanol,X,sol.hydrogenSold.*param.costs.hydrogen,X,sol.powerSold.*param.costs.energy*0.5,X,result.powerInPlant.*param.costs.energy,X,sol.powerInBattery.*param.costs.energy,X,sol.powerInElectrolyser.*param.costs.energy)
title("Costs");
xlabel("time in h");
ylabel("Euro");
legend("methanol", "hydrogen", "power", "power needed plant", "power needed battery", "power needed electrolyser");
