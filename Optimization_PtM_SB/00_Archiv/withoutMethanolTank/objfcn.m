function y = objfcn(x,len,mdl)

leanIn = x(1:len);
gasIn = x(len+1:2*len);
hydrogenIn = x(2*len+1:3*len);
powerIn = x(3*len+1:4*len);

[y, sumy] = calculateMethanolProd(leanIn, gasIn, hydrogenIn, mdl, len);
y = -sumy;