function [sol0, x0] = generateRandomInitialValues(param, len)

lowerBound = param.lb;
upperBound = param.ub;

if param.initialValuesDifferent == true
    init = zeros(len,param.numberOfVariables);
    for i = 1:param.numberOfVariables
        for j = 1:len
            init(j,i) = lowerBound(i) + (upperBound(i) - lowerBound(i)) * rand(1,1);
        end
    end
    sol0.leanIn = init(:,1);
    sol0.gasIn = init(:,2);
    sol0.hydrogenIn = init(:,3);
    sol0.meohTankOut = init(:,4);
    sol0.powerInElectrolyser = init(:,5);
    sol0.powerInBattery = init(:,6);
    sol0.powerBatteryElectrolyser = init(:,7);
    sol0.powerSold = init(:,8);
    sol0.hydrogenSold = init(:,9);
    x0 = [sol0.leanIn; sol0.gasIn; sol0.hydrogenIn; sol0.meohTankOut; sol0.powerInElectrolyser; sol0.powerInBattery; sol0.powerBatteryElectrolyser; sol0.powerSold; sol0.hydrogenSold];
else
    init = lowerBound + (upperBound - lowerBound) .* rand(length(lowerBound),1);
    sol0.leanIn = init(1)*ones(len,1);
    sol0.gasIn = init(2)*ones(len,1);
    sol0.hydrogenIn = init(3)*ones(len,1);
    sol0.meohTankOut = init(4).*ones(len,1);
    sol0.powerInElectrolyser = init(5).*ones(len,1);
    sol0.powerInBattery = init(6).*ones(len,1);
    sol0.powerBatteryElectrolyser = init(7).*ones(len,1);
    sol0.powerSold = init(8).*ones(len,1);
    sol0.hydrogenSold = init(9).*ones(len,1);
    x0 = [sol0.leanIn; sol0.gasIn; sol0.hydrogenIn; sol0.meohTankOut; sol0.powerInElectrolyser; sol0.powerInBattery; sol0.powerBatteryElectrolyser; sol0.powerSold; sol0.hydrogenSold];
end
