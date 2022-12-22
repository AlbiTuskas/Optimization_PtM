function [y, sumy] = calculateRequiredPowerDIST(meohOut, mdl, len)

objfcnmdl = mdl;
coef = zeros(size(objfcnmdl.Coefficients,1),1);
vars = strings(size(objfcnmdl.Coefficients,1),1);
for i = 1:length(coef)
    coef(i) = objfcnmdl.Coefficients{i,1};
    vars(i) = string(objfcnmdl.CoefficientNames{i});
end
    
objfcn = zeros(len,1);
for i = 1:length(coef)
    if vars(i) == "(Intercept)"
        objfcn = objfcn + coef(i);
    elseif vars(i) == "x1"
        objfcn = objfcn + coef(i)*meohOut;
    elseif vars(i) == "x1^2"
        objfcn = objfcn + coef(i)*meohOut.*meohOut;
    end
end

sumy = sum(objfcn(:,1));
y = objfcn(:,1);