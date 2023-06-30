Sets
years /1985,1995,2010,2015,2020*2050/
generation_plants /AD14,AGD5,MEGL,MELI,PTOL,PTOG,MYTI,NEW,HYDR/
demand_profiles /CONSUMER1,CONSUMER2,CONSUMER3/
;
Parameters
P_UnitFixedCost(generation_plants,years)
P_UnitVariableCost(generation_plants,years)
P_UnitCapitalCost(generation_plants,years)
P_UnitReliabilityConsumer(demand_profiles,years)
P_UnitContractedConsumer(demand_profiles,years)
P_UnitEmissionCost(generation_plants,years)
P_UnitCapacity(generation_plants,years)
P_UnitGeneration(generation_plants,years)
generation(generation_plants,years)
demand(generation_plants,years)
;
$gdxin
$gdxin UCgeneration.gdx
$load generation=generation
$gdxin
$gdxin UCdemand.gdx
$load demand=demand
$gdxin
$gdxin
$gdxin UCcapcost.gdx
$load P_UnitCapitalCost=capitalcost
$gdxin
$gdxin UCfixedcost.gdx
$load P_UnitFixedCost=fixedcost
$gdxin
$gdxin UCvariablecost.gdx
$load P_UnitVariableCost=variablecost
$gdxin
$gdxin
$gdxin UCreliabilityconsumer.gdx
$load P_UnitReliabilityConsumer=reliabilityconsumer
$gdxin
$gdxin
$gdxin UCcontractedconsumer.gdx
$load P_UnitContractedConsumer=contractedconsumer
$gdxin
$gdxin UCemissioncost.gdx
$load P_UnitEmissionCost=emissioncost
$gdxin
Variable
V_Electricity(demand_profiles,years)
V_Energy(generation_plants,years)
Utility
;
Equations
Q_UtilityCalculation
Q_ProductionConstraint(generation_plants)
Q_DemandConstraint(generation_plants)
Q_MatchingConstraint(demand_profiles)
;
Q_UtilityCalculation ..
Utility =E= sum(years,sum(generation_plants,V_Energy(generation_plants,years)*(P_UnitEmissionCost(generation_plants,years)+P_UnitFixedCost(generation_plants,years)+P_UnitVariableCost(generation_plants,years)+P_UnitCapitalCost(generation_plants,years)))
+sum(years,sum(demand_profiles,V_Electricity(demand_profiles,years)*P_UnitContractedConsumer(demand_profiles,years)));
Q_ProductionConstraint(generation_plants) ..
sum(years,V_Energy(generation_plants,years)*P_UnitCapacity(generation_plants,years)) =L= sum(years,generation(generation_plants,years));
Q_DemandConstraint(generation_plants) ..
sum(years,V_Energy(generation_plants,years)*P_UnitGeneration(generation_plants,years)) =G= sum(years,demand(generation_plants,years));
Q_MatchingConstraint(demand_profiles) ..
sum(years,sum(generation_plants,V_Energy(generation_plants,years)*P_UnitContractedConsumer(demand_profiles,years)) =E= sum(years,V_Electricity(demand_profiles,years)*P_UnitReliabilityConsumer(demand_profiles,years));
Model EnergyContract
/all/
Solve EnergyContract Min Utility using LP;
