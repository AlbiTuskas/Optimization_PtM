function efficiency = calculateEfficiencyElectrolyser(powerInNominal,mdl,param)

if param.electrolyser.modelType == "poly1"
    efficiency = mdl.p1*powerInNominal + mdl.p2;
elseif param.electrolyser.modelType == "exp2"
    efficiency = mdl.a*exp(mdl.b*powerInNominal) + mdl.c*exp(mdl.d*powerInNominal);
end