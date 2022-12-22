function [] = writeToExcel(param, costs, errorFlag, variables, column, loadfactor)

filename = 'C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\07_Szenarien\Validierungsfälle.xlsx';

rangeRowStart = [3,8,20,33,37];
rangeRowEnd = [5,16,30,33,75];
rangeColumn = column;
sheetName = 'Validierungsfälle Test_1';

writematrix(loadfactor,filename,'Sheet',sheetName,'Range', rangeColumn + int2str(rangeRowStart(1)) + ":" + rangeColumn + int2str(rangeRowEnd(1)));
writematrix(variables,filename,'Sheet',sheetName,'Range', rangeColumn + int2str(rangeRowStart(2)) + ":" + rangeColumn + int2str(rangeRowEnd(2)));
writematrix(costs.costsArray,filename,'Sheet',sheetName,'Range', rangeColumn + int2str(rangeRowStart(3)) + ":" + rangeColumn + int2str(rangeRowEnd(3)));
writematrix(errorFlag,filename,'Sheet',sheetName,'Range', rangeColumn + int2str(rangeRowStart(4)) + ":" + rangeColumn + int2str(rangeRowEnd(4)));
writematrix(param.validationArray,filename,'Sheet',sheetName,'Range', rangeColumn + int2str(rangeRowStart(5)) + ":" + rangeColumn + int2str(rangeRowEnd(5)));
