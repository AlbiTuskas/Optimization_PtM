function [c, ceq] = confcn(x,len,sampleTime,mdlPowerRequired,power)

leanIn = x(1:len);
gasIn = x(len+1:2*len);
hydrogenIn = x(2*len+1:3*len);
powerIn = x(3*len+1:4*len);

%% Power
[y, ~] = calculateRequiredPower(leanIn, gasIn, hydrogenIn, mdlPowerRequired, len);
powerRequired = y;

%% Electrolyzer
pvScale = 700;
powerScaled = power * pvScale;
powerInNominal = powerIn / 100;

% Modell für die Effizienz des Elektrolyseurs
mdlElectrolyser = modelElectrolyser();
efficiencyElectrolyzer = mdlElectrolyser.a*exp(mdlElectrolyser.b*powerInNominal) + mdlElectrolyser.c*exp(mdlElectrolyser.d*powerInNominal); 
%efficiencyElectrolyzer = -14.102*powerInNominal + 79.576; 
hydrogenProdElectrolyzer = powerIn.*efficiencyElectrolyzer*60*sampleTime / (286151.3637877446*100);

%% H2-Tank
kgTokmolH2 = 1/2.016;

tankH2InitialPressure = 45;
tankH2Volume = 50;
tankH2InitialFilling = tankH2InitialPressure*10^5*tankH2Volume / (8.314*(21+273.15)*1000);
tankH2Filling(2) = tankH2InitialFilling + hydrogenProdElectrolyzer(2)/60*sampleTime - kgTokmolH2*hydrogenIn(2)/60*sampleTime;
for i = 3:len
    tankH2Filling(i) = tankH2Filling(i-1) + hydrogenProdElectrolyzer(i)/60*sampleTime - kgTokmolH2*hydrogenIn(i)/60*sampleTime;
end
tankH2Filling(1) = tankH2InitialFilling;
tankH2Filling = tankH2Filling';
tankH2Pressure(2:len) = tankH2Filling(2:len)*8.314*(21+273.15) / (tankH2Volume*100);
tankH2Pressure(1) = tankH2InitialFilling*8.314*(21+273.15) / (tankH2Volume*100);

%% Methanol Tank
kgTokmolMEOH = 1/32.04;
kgTokmolH2O = 1/18.01528;
tankMEOHInitialPressure = 20;
tankMEOHVolume = 50;
tankH2InitialFilling = tankH2InitialPressure*10^5*tankH2Volume / (8.314*(21+273.15)*1000);
tankH2Filling(2) = tankH2InitialFilling + hydrogenProdElectrolyzer(2)/60*sampleTime - kgTokmolH2*hydrogenIn(2)/60*sampleTime;
for i = 3:len
    tankH2Filling(i) = tankH2Filling(i-1) + hydrogenProdElectrolyzer(i)/60*sampleTime - kgTokmolH2*hydrogenIn(i)/60*sampleTime;
end
tankH2Filling(1) = tankH2InitialFilling;
tankH2Filling = tankH2Filling';
tankH2Pressure(2:len) = tankH2Filling(2:len)*8.314*(21+273.15) / (tankH2Volume*100);
tankH2Pressure(1) = tankH2InitialFilling*8.314*(21+273.15) / (tankH2Volume*100);

%% Constraints

c(1:len) = powerIn(:) + powerRequired(:)*0.001 - powerScaled(:);
c(len+1:2*len) = 30 - tankH2Pressure(:); 
c(2*len+1:3*len) = tankH2Pressure(:) - 47;

ceq = [];
