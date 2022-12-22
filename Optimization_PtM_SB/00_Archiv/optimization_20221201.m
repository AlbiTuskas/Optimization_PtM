clear all

%% Kennfelderstellung
mdl = regressionModel;
mdlH2Des = mdl{1};
mdlCO2Des = mdl{2};
mdlMassFlowMEOH = mdl{3};

%% Einlesen der Stromdaten bzw. des produzierten Wasserstoffs

pathToFile = "C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\06_Daten\Energy\Solar_Power";
T = readtable(pathToFile, "Sheet", "Tabelle1");

idx = 1:60:size(T,1);
power = T{idx,2};
H2Prod = T{idx,8};
len = size(H2Prod,1);

%% Optimierungsproblem

leanIn = optimvar('leanIn', len, 'Type','continuous','LowerBound',100, 'UpperBound', 300);
gasIn = optimvar('gasIn', len, 'Type','continuous','LowerBound',3, 'UpperBound', 12);
hydrogenIn = optimvar('hydrogenIn', len, 'Type','continuous','LowerBound',0.0, 'UpperBound', 1);

hydrogenCons = hydrogenIn(:) <= H2Prod;

mdl = regressionModel();
mdlMassFlow = mdl{3};

%% Kennfeld der Anlage

for i = 1:size(mdlMassFlow.Coefficients,1)
    coef(i) = mdlMassFlow.Coefficients{i,1};
    vars(i) = string(mdlMassFlow.CoefficientNames{i});
end

methanolProduction = zeros(len,1);
for j = 1:1%len
    for i = 1:length(coef)
        if vars(i) == "(Intercept)"
            methanolProduction = methanolProduction + coef(i);
        elseif vars(i) == "x1"
            methanolProduction = methanolProduction + coef(i)*leanIn;
        elseif vars(i) == "x2"
            methanolProduction = methanolProduction + coef(i)*gasIn;
        elseif vars(i) == "x3"
            methanolProduction = methanolProduction + coef(i)*hydrogenIn;
        elseif vars(i) == "x1:x2"
            methanolProduction = methanolProduction + coef(i)*leanIn.*gasIn;
        elseif vars(i) == "x1:x3" 
            methanolProduction = methanolProduction + coef(i)*leanIn.*hydrogenIn;
        elseif vars(i) == "x2:x3" 
            methanolProduction = methanolProduction + coef(i)*gasIn.*hydrogenIn;
        elseif vars(i) == "x1^2" 
            methanolProduction = methanolProduction + coef(i)*leanIn.*leanIn;
        elseif vars(i) == "x2^2" 
            methanolProduction = methanolProduction + coef(i)*gasIn.*gasIn;
        elseif vars(i) == "x3^2"
            methanolProduction = methanolProduction + coef(i)*hydrogenIn.*hydrogenIn;
        end
    end
end

methanol = sum(methanolProduction);
% methanolProduction = 0;
% for i = 1:len
%     methanolProduction = methanolProduction + predict(mdl, [gasIn(i), leanIn(i), hydrogenIn(i)]);
% end

%%
dispatch = optimproblem('ObjectiveSense','maximize');
dispatch.Objective = methanol;
dispatch.Constraints.hydrogenCons = hydrogenCons;

options = optimoptions('intlinprog','Display','final');
[dispatchsol,fval,exitflag,output] = solve(dispatch,'options',options);

