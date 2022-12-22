clear all

%% Kennfelderstellung
mdl = regressionModel();
mdlMassFlowMEOH = mdl{1};

%% Einlesen der Stromdaten bzw. des produzierten Wasserstoffs

pathToFile = "C:\Users\uehmt\bwSyncShare\Max_Masterarbeit\06_Daten\02_Energie\Solar_Power";
T = readtable(pathToFile, "Sheet", "Tabelle1");

sampleTime = 60;
start = 12960;
finish = start + 60*12*2;
idx = start:sampleTime:finish;
powerAll = T{:,2};

for i = 1:length(idx)-1
    power(i) = mean(powerAll(idx(i):idx(i+1)));
end
power = power';
len = size(power,1);

mdl = regressionModel();
mdlMassFlow = mdl{3};

%% Electrolyzer

pvScale = 700;
powerScaled = power * pvScale;

%% Optimierung über Zeithorizont

% Anfangsbedingungen
x0(1:len) = 200;
x0(len+1:2*len) = 5;
x0(2*len+1:3*len) = 0.2;
x0(3*len+1:4*len) = 0;

lb(1:len) = 100;
lb(len+1:2*len) = 3;
lb(2*len+1:3*len) = 0.1;
lb(3*len+1:4*len) = 0;

ub(1:len) = 300;
ub(len+1:2*len) = 12;
ub(2*len+1:3*len) = 1;
ub(3*len+1:4*len) = 200;

% Lineare Constraints (Power Input Elektrolyzer)
A = diag(zeros(4*len,1));
b = zeros(4*len,1);
for i = (3*len+1):4*len
    A(i,i) = 1;
    b(i) = powerScaled(i-3*len);
end

Aeq = [];
beq = [];

f = @(x)fcn(x,mdlMassFlow,len);
fun = @(x)-f(x);

fmincon(fun,x0,A,b,Aeq,beq,lb,ub,@mycon)

