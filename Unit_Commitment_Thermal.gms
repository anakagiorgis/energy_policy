Option LP=xpress;
Sets
u thermal and hydro us /AD14,AGD5,MEGL,MELI,PTOL,PTOG,KOM,LAVR,ELPE,IRON,KORI,AGNI,MYTI,NEW,GT,HYDR/
h time slices /1*8760/
hr(h) time slices /1*8760/
r reserves /AVRR,AFRR,MFRR/
;
Alias (h, h1),(hr,hr1);
Table ld(h,*)
$ondelim
$include UCdata.8760.csv
;
Table ud(u,*)
$include UCdata.unit.csv
;
$offdelim
Parameters
         Load(h)         load and losses in GW per h
         RES(h)          production by variable RES in GW per h
         vc_min(u)       generation cost
         vc_mrg(u)       running cost
         vctmin(u)
         vctmax(u)
         supc(u)         start-up cost
         shdc(u)         shutdown cost
         Toff(u)         minimum off-state duration
         rd(r)           reserve requirement /AVRR 0.05,AFRR 0.10,MFRR 0.12/
         etsprice        eur per t CO2  /00/
         PVpromotion     multiplier for PV RES  /1/
         WDpromotion     multiplier for WIND RES  /1/
         cardh           number of time slices to run
report
;
cardh       =card(hr);
Load     (h)=ld(h,"Load");
RES      (h)=min(PVpromotion*ld(h,"PV")+WDpromotion*ld(h,"WIND"),0.99*ld(h,"Load"));
vc_min   (u)=ud(u,"VarC")+ud(u,"Hrmin")*(ud(u,"FUELPR")+ud(u,"emf")*etsprice);
vc_mrg   (u)=ud(u,"VarC")+(ud(u,"Hrmax")-ud(u,"Hrmin"))/(ud(u,"MaxCap")-ud(u,"MinCap"))
                 *(ud(u,"FUELPR")+ud(u,"emf")*etsprice);
supc     (u)=ud(u,"StupCost");
shdc     (u)=ud(u,"StupCost")/5;
vctmin   (u) $ud(u,"MinCap")=(vc_min(u)*ud(u,"MinCap")+vc_mrg(u)*(ud(u,"MaxCap")-ud(u,"MinCap")))/ud(u,"MinCap");
vctmax   (u)=(vc_min(u)*ud(u,"MaxCap")+vc_mrg(u)*(ud(u,"MaxCap")-ud(u,"MaxCap")))/ud(u,"MaxCap");
Toff     (u)=ud(u,"Minup");

Positive Variables
V_NLD(h)  net load
V_DR(h)   demand response
V_GN(u,h) generation variable
V_RN(u,h) running capacity variable
V_DP(u,h) positive part of difference in running capacity variable
V_DM(u,h) positive part of difference in shutdown power variable
V_OF(u,h) capacity of off-state
;

Variable TC              total cost

Equation Q_TC            objective function
         Q_NLD(h)        net load
         Q_DC(h)         demand cut constraint
         Q_DEM(h)        demand supply balance
         Q_ENE(u)        energy constraint
         Q_RUN(u,h)      generation bounded by running capacity
         Q_CAP(u,h)      running capacity bounded by available installed capacity
         Q_MIN(u,h)      minimum stable generation constraint
         Q_DP(u,h)       positive difference of running state
         Q_DM(u,h)       negative difference of running state
         Q_DR(u,h)       difference of running state
         Q_DT(u,h)       minimum off-state duration constraint
         Q_RD(h)         reserve requirement constraint
;
Q_TC..              TC  =E= sum((u,hr(h)),
                            vc_min(u)* V_GN(u,h)
                          + vc_mrg(u)*(V_RN(u,h)-V_GN(u,h))
                          + supc(u)  * V_DP(u,h)
                          + shdc(u)  * V_DM(u,h))
                          + sum(hr(h),3.500* V_DR(h));
Q_NLD(hr(h))..      V_NLD(h) =E= ld(h,"load")-RES(h);
Q_DC(hr(h))..       V_DR(h)  =L= V_NLD(h);
Q_DEM(hr(h))..      sum(u,V_GN(u,h)) =E= V_NLD(h)-V_DR(h);
Q_ENE(u)..          ud(u,"MaxEn")*cardh/8760 =G= sum(hr(h),V_GN(u,h));
Q_RUN(u,hr(h))..    V_RN(u,h) =G= V_GN(u,h);
Q_CAP(u,hr(h))..    ud(u,"MaxCap")*ud(u,"AvL") =G= V_RN(u,h);
Q_MIN(u,hr(h))$ud(u,"MinCap")..  V_GN(u,h) =G= ud(u,"MinCap")*V_RN(u,h);
Q_DP(u,hr(h)) $ud(u,"MinCap")..  V_DP(u,h) =G= V_RN(u,h) - V_RN(u,h--1);
Q_DM(u,hr(h)) $ud(u,"MinCap")..  V_DM(u,h) =G= V_RN(u,h--1) - V_RN(u,h);
Q_DR(u,hr(h)) $ud(u,"MinCap")..  V_DP(u,h) - V_DM(u,h) =E= V_RN(u,h) - V_RN(u,h--1);

Q_DT(u,hr(h))$ud(u,"MinCap")..   V_OF(u,h) - V_OF(u,h--1) + V_DP(u,h) =E=
                    Sum(hr1(h1) $(h1.val=h.val+1-Toff(u)), V_DM(u,h1));

Q_RD(hr(h))..       sum(u,V_RN(u,h) - V_GN(u,h)) =G= rd("AFRR")*V_NLD(h);

V_DP.FX(u,hr(h))$(not ud(u,"MinCap")) = 0;
V_DM.FX(u,hr(h))$(not ud(u,"MinCap")) = 0;
V_OF.FX(u,hr(h))$(not ud(u,"MinCap")) = 0;

Model UCTH /Q_TC,Q_NLD,Q_DEM,Q_DC,Q_ENE,Q_RUN,Q_CAP,Q_MIN,Q_DP,Q_DM,Q_DR,Q_DT,Q_RD/;
UCTH.optfile=1;

*-----------------------------------------------------------------------------------------
$setglobal scen ETS0RES1
etsprice     =0;
PVpromotion  =1;
WDpromotion  =1;
$batinclude Unit_commitment_BATinclude.gms %scen%
*-----------------------------------------------------------------------------------------
$setglobal scen ETS40RES1
etsprice     =40;
PVpromotion  =1;
WDpromotion  =1;
$batinclude Unit_commitment_BATinclude.gms %scen%
*-----------------------------------------------------------------------------------------
$setglobal scen ETS80RES1
etsprice     =80;
PVpromotion  =1;
WDpromotion  =1;
$batinclude Unit_commitment_BATinclude.gms %scen%
*-----------------------------------------------------------------------------------------
$setglobal scen ETS40RES2
etsprice     =40;
PVpromotion  =2;
WDpromotion  =2;
$batinclude Unit_commitment_BATinclude.gms %scen%
*-----------------------------------------------------------------------------------------
$setglobal scen ETS40RES2
etsprice     =40;
PVpromotion  =2;
WDpromotion  =2;
$batinclude Unit_commitment_BATinclude.gms %scen%
*-----------------------------------------------------------------------------------------
$setglobal scen ETS40RES3
etsprice     =40;
PVpromotion  =3;
WDpromotion  =3;
$batinclude Unit_commitment_BATinclude.gms %scen%
*-----------------------------------------------------------------------------------------
$setglobal scen ETS80RES4
etsprice     =80;
PVpromotion  =4;
WDpromotion  =4;
$batinclude Unit_commitment_BATinclude.gms %scen%
*-----------------------------------------------------------------------------------------
