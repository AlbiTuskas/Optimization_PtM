function [] = writeToExcel(param, costs, result, variables, column)

filename = 'C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\07_Szenarien\Validierungsfälle_20221222.xlsx';

rangeRowStart = [3,7,19,33,36];
rangeRowEnd = [5,15,29,33,38];
rangeColumn = column;
sheetName = 'Validierungsfälle_100%_Batterie';

prices = [param.costs.methanol; param.costs.biogas; param.costs.hydrogen];

writematrix(result.loadFactor,filename,'Sheet',sheetName,'Range', rangeColumn + int2str(rangeRowStart(1)) + ":" + rangeColumn + int2str(rangeRowEnd(1)));
writematrix(variables,filename,'Sheet',sheetName,'Range', rangeColumn + int2str(rangeRowStart(2)) + ":" + rangeColumn + int2str(rangeRowEnd(2)));
writematrix(costs.costsArray,filename,'Sheet',sheetName,'Range', rangeColumn + int2str(rangeRowStart(3)) + ":" + rangeColumn + int2str(rangeRowEnd(3)));
%writematrix(errorFlag,filename,'Sheet',sheetName,'Range', rangeColumn + int2str(rangeRowStart(4)) + ":" + rangeColumn + int2str(rangeRowEnd(4)));
writematrix(prices,filename,'Sheet',sheetName,'Range', rangeColumn + int2str(rangeRowStart(5)) + ":" + rangeColumn + int2str(rangeRowEnd(5)));
