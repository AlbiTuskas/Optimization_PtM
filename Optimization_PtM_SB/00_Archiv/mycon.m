function [c,ceq] = mycon(x)

len = length(x) / 4;

powerIn = x(3*len+1:4*len);
hydrogenIn = x(2*len+1:3*len);

powerInNominal = powerIn / 100;
efficiencyElectrolyzer = -14.102*powerInNominal + 79.576; 
hydrogenProdElectrolyzer = powerIn.*efficiencyElectrolyzer*3600 / (286151.3637877446*100);

% Tank filling
tankInitialPressure = 45;
tankVolume = 50;
tankInitialFilling = tankInitialPressure*10^5*tankVolume / (8.314*(21+273.15)*1000);
tankFilling(1) = tankInitialFilling;

for i = 2:len
    tankFilling(i) = tankFilling(i-1) + hydrogenProdElectrolyzer(i)/60 - hydrogenIn(i)/60;
end

c = -tankFilling + 10;
ceq = [];


