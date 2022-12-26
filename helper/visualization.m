function [] = visualization(sol,len,result,costs,param)

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
plot(X,result.hydrogenProdElectrolyser*(1/param.kgTokmolH2),X,sol.hydrogenSold,X,sol.hydrogenIn);
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
plot(X,result.moleFlowMEOHTankIn*(1/param.kgTokmolH2), X, sol.meohTankOut)
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

% Biogas
figure
plot(X,result.massFlowBiogas)
title("Biogas-Production");
xlabel("time in h");
ylabel("mass flow biogas in kg/h");

% Kosten
figure
plot(X,costs.methanol,...
        X,costs.biogas,...
        X,costs.hydrogenSold,...
        X,costs.powerSold,...
        X,costs.powerInElectrolyser,...
        X,costs.powerInPlant.*param.costs.energy,...
        X,costs.powerInBattery.*param.costs.energy);
title("Costs");
xlabel("time in h");
ylabel("Euro");
legend("methanol", "biogas", "hydrogen", "power sold", "power needed electrolyser", "power needed plant", "power needed battery");
