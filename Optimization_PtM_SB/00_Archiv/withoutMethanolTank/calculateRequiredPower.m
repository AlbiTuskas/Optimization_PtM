function [y, sumy] = calculateRequiredPower(leanIn, gasIn, hydrogenIn, mdl, len)

for j = 1:length(mdl)
    objfcnmdl = mdl{j};
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
            objfcn = objfcn + coef(i)*leanIn;
        elseif vars(i) == "x2"
            objfcn = objfcn + coef(i)*gasIn;
        elseif vars(i) == "x3"
            objfcn = objfcn + coef(i)*hydrogenIn;
        elseif vars(i) == "x1:x2"
            objfcn = objfcn + coef(i)*leanIn.*gasIn;
        elseif vars(i) == "x1:x3" 
            objfcn = objfcn + coef(i)*leanIn.*hydrogenIn;
        elseif vars(i) == "x2:x3" 
            objfcn = objfcn + coef(i)*gasIn.*hydrogenIn;
        elseif vars(i) == "x1^2" 
            objfcn = objfcn + coef(i)*leanIn.*leanIn;
        elseif vars(i) == "x2^2" 
            objfcn = objfcn + coef(i)*gasIn.*gasIn;
        elseif vars(i) == "x3^2"
            objfcn = objfcn + coef(i)*hydrogenIn.*hydrogenIn;
        end
    end
    
    objfcnArray(:,j) = objfcn(:,1)
end

sumy = 0;
y = zeros(len,1);
for i = 1:length(mdl)
    sumy = sumy + sum(objfcnArray(:,i))
    y = y + objfcn(:,i)
end
