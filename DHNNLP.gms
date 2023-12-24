$Title Simple district heating model with discrete choice embedded in intertemporal optimization
* ___________________________________ Options ______________________________________________________________________________________________________________________________________
$oninline
$set debug off
$offlisting
OPTION LIMROW=0,LIMCOL=0,SOLPRINT=OFF,SYSOUT=OFF;
$set solver xpress
$if %debug%==on $onlisting
$if %debug%==on OPTION LIMROW=999,LIMCOL=999,SOLPRINT=ON,SYSOUT=ON;
$if %debug%==on $set solver cplex
option lp=%solver%;
$set Baseyear 2020
$set Horizon  2050
*____________________________________ SETS _________________________________________________________________________________________________________________________________________
Sets
dhtech /boiler, hp/
time t /%Baseyear%*%Horizon%/
Singleton set base(time) /%Baseyear%/
alias (vintage,time),(dhtech,dhtechh)
Parameter
g exponent of discrete choice /-15.5/
demand(time) demand for heat
sh(dhtech,time) calculation of shares to check
invcost(dhtech,time) investment cost in EUR per kW /boiler.(2020*2025) 150,boiler.(2026*2030) 200, hp.(2020*2030) 450/
opercost(dhtech,time) operating costs in EUR per kWh /boiler.2020 0.100, hp.2020 0.010/
cost(dhtech,time) calculation of LCOE to check
surv(vintage,time) capital survival function
preced(vintage,time) precedence function
DHreport
;
*___________________________________________ ASSIGNMENTS - CALCULATIONS BEFORE THE MODEL ___________________________________________________________________________________________
demand("2020") = 100;
Loop(time$(time.val>2020), demand(time)=demand(time-1)*(1+0.02););
Loop(time$(time.val>2020), opercost(dhtech,time)=opercost(dhtech,time-1)*(1+0.04););
cost(dhtech,time)=invcost(dhtech,time)/3500+opercost(dhtech,time);
sh(dhtech,time) = 1/(1+Sum(dhtechh$(dhtechh.pos<>dhtech.pos), exp(g*(cost(dhtechh,time)-cost(dhtech,time)))));
surv(vintage,time)$(vintage.val<=time.val and time.val-vintage.val<=8)=1;
preced(vintage,time)$(vintage.val<=time.val)=1;
*___________________________________________ MODEL__________________________________________________________________________________________________________________________________
Positive variable
V_K(dhtech,vintage,time)
V_I(dhtech,time)
V_G(dhtech,vintage,time)
V_cost(dhtech,time)
V_sh(dhtech,time)
V_Gap(time)
Variable
Totcost
Equations QK,QV,QD,QCap,QGap,QC,Qsh,QOBJ;

QK(dhtech,vintage,time) $(vintage.val<=time.val)..   /* stock of capital per vintage in a year formed by still operating investment */
  V_K(dhtech,vintage,time) =E= V_I(dhtech,vintage)*surv(vintage,time);
QV(dhtech,vintage,time) $(vintage.val<=time.val)..   /* capacity constraint of produciton of heat per technology vintage */
  V_K(dhtech,vintage,time)*3000 =G= V_G(dhtech,vintage,time);
QD(time)..                                           /* heat production has to meet at least demand for heat */
  Sum(dhtech, Sum(vintage $(vintage.val<=time.val),V_G(dhtech,vintage,time))) =G= demand(time);
QCap(dhtech,time)..                                  /* discrete choice applies on investment per technology to fill the gap of missing capacity */
  V_I(dhtech,time)*3000 =E= V_sh(dhtech,time)*V_Gap(time);
QGap(time)..                                         /* gap of missing capacity */
  V_Gap(time) =E= (1+0.15)*demand(time)-Sum(vintage$(vintage.val<=time.val-1),Sum(dhtech,V_I(dhtech,vintage)*surv(vintage,time)))*3000;
QC(dhtech,time)..                                    /* cost of capital and production */
  V_cost(dhtech,time) =E= Sum(vintage$(vintage.val<=time.val),V_I(dhtech,vintage)*surv(vintage,time)*invcost(dhtech,vintage)*0.12
                         +V_G(dhtech,vintage,time)*opercost(dhtech,time));
Qsh(dhtech,time)..                                   /* discrete choice calculates shares of technologies based on relative LCOEs */
  V_sh(dhtech,time) =E= 1/(1+Sum(dhtechh$(dhtechh.pos<>dhtech.pos), exp(g*(cost(dhtechh,time)-cost(dhtech,time)))));
QOBJ..                                               /* total heat system costs */
  Totcost =E= Sum(time, (1+0.03)**(-(time.val-2020))*Sum(dhtech,V_cost(dhtech,time)));

V_G.FX(dhtech,vintage,time) $(vintage.val>time.val)=0;
V_K.FX(dhtech,vintage,time) $(vintage.val>time.val)=0;
Model DHNLP /QV,QD,Qsh,QC,QK,QCap,QGap,QOBJ/;
option nlp=conopt4;
V_sh.L(dhtech,time)=1/(1+Sum(dhtechh$(dhtechh.pos<>dhtech.pos), exp(g*(cost(dhtechh,time)-cost(dhtech,time)))));
V_cost.L(dhtech,time)= cost(dhtech,time);
Solve DHNLP min TOTCOST using NLP;
*_____________________________________ REPORTING ___________________________________________________________________________________________________________________________________
DHreport("Demand","Total",time)= demand(time);
DHreport("Production Heat",dhtech,time)= Sum(vintage $(vintage.val<=time.val),V_G.L(dhtech,vintage,time));
DHreport("Production Heat","Total",time)= Sum(dhtech, Sum(vintage $(vintage.val<=time.val),V_G.L(dhtech,vintage,time)));
DHreport("Capital stock",dhtech,time)= Sum(vintage $(vintage.val<=time.val),V_K.L(dhtech,vintage,time));
DHreport("Capital stock","Total",time)= Sum(dhtech, Sum(vintage $(vintage.val<=time.val),V_K.L(dhtech,vintage,time)));
DHreport("Investment",dhtech,time)= Sum(vintage $(vintage.val<=time.val),V_I.L(dhtech,vintage));
DHreport("Investment","Total",time)= Sum(dhtech, Sum(vintage $(vintage.val<=time.val),V_I.L(dhtech,vintage)));
DHreport("Capital stock Gap","Total",time)= V_Gap.L(time);
DHreport("Technology shares from discrete choice",dhtech,time)= V_sh.L(dhtech,time);
DHreport("Technology shares from discrete choice","Total",time)= Sum(dhtech, V_sh.L(dhtech,time));
DHreport("Technology shares in production",dhtech,time)= Sum(vintage $(vintage.val<=time.val),V_G.L(dhtech,vintage,time))/demand(time);
DHreport("Technology shares in production","Total",time)= Sum(dhtech, Sum(vintage $(vintage.val<=time.val),V_G.L(dhtech,vintage,time))/demand(time));
DHreport("Technology shares in capital stock",dhtech,time)= Sum(vintage $(vintage.val<=time.val),V_K.L(dhtech,vintage,time))
     /Sum(dhtechh,Sum(vintage $(vintage.val<=time.val),V_K.L(dhtechh,vintage,time)));
DHreport("Technology shares in capital stock","Total",time)= Sum(dhtech, Sum(vintage $(vintage.val<=time.val),V_K.L(dhtech,vintage,time)))
     /Sum(dhtechh,Sum(vintage $(vintage.val<=time.val),V_K.L(dhtechh,vintage,time)));
DHreport("Technology shares in investment",dhtech,time)= Sum(vintage $(vintage.val<=time.val),V_I.L(dhtech,vintage))
     /Sum(dhtechh,Sum(vintage $(vintage.val<=time.val),V_I.L(dhtechh,vintage)));
DHreport("Technology shares in investment","Total",time)= Sum(dhtech, Sum(vintage $(vintage.val<=time.val),V_I.L(dhtech,vintage)))
     /Sum(dhtechh,Sum(vintage $(vintage.val<=time.val),V_I.L(dhtechh,vintage)));
DHreport("Costs",dhtech,time)= V_cost.L(dhtech,time);
DHreport("Costs","Total",time)= Sum(dhtech, V_cost.L(dhtech,time));
DHreport("Unit Costs",dhtech,time)= (V_cost.L(dhtech,time)/Sum(vintage $(vintage.val<=time.val),V_G.L(dhtech,vintage,time)))
     $Sum(vintage $(vintage.val<=time.val),V_G.L(dhtech,vintage,time));
DHreport("Unit Costs","Total",time)= Sum(dhtech, V_cost.L(dhtech,time))/demand(time);
DHreport("Marginal Cost of Demand","Total",time)= QD.M(time);


