function f = fcn(x, mdl, len)

for i = 1:len
    a = [x(i), x(i+len), x(i+2*len)];
    massFlowMEOH(i) = predict(mdl,a);
end

f = sum(massFlowMEOH);

