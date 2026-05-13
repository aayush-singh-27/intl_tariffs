
************************************************
**************** UNITED KINGDOM ****************
************************************************

* read in tamar uk tariff data
import excel "intl_tariffs/data/foreign_tariff_rates_final.xlsx", sheet("GBR") cellrange(A2:E187) firstrow clear
keep year tau_gbr_own
rename tau_gbr_own tau_uk_tamar
tempfile tau_tamar
save `tau_tamar'

* read in industrial production data
import delimited "intl_tariffs/data/mitchell/industrial_production_index_europe.csv", clear

keep if country == "United Kingdom"
rename (index_value base) (ind_prod ind_prod_unit)
drop country

* deduplicate: keep the observation with the more recent base for each year
bysort year (ind_prod_unit): keep if _n == _N
tempfile ind_prod
save `ind_prod'

* read in GDP deflator and real GDP from Global Macro Database
import excel "intl_tariffs/data/GMD.xlsx", sheet("deflator") cellrange(C6376:F7135) clear
rename (C D E F) (year gdp_deflator ngdp_gmd rgdp_gmd)
drop ngdp_gmd
tempfile gmd
save `gmd'

* read in general uk data
import delimited "intl_tariffs/data/mitchell/uk.csv", clear
merge 1:1 year using `ind_prod', nogen
merge 1:1 year using `tau_tamar', nogen
merge 1:1 year using `gmd', nogen

* harmonize variable units to get everything in million pounds
replace imports = imports * 1000 if trade_unit == "thousand million pounds"
replace exports = exports * 1000 if trade_unit == "thousand million pounds"

replace govt_revenue_total = govt_revenue_total / 1000 if revenue_unit == "thousand pounds"
replace govt_revenue_total = govt_revenue_total * 1000 if revenue_unit == "thousand million pounds"

replace customs_revenue = customs_revenue / 1000 if revenue_unit == "thousand pounds"
replace customs_revenue = customs_revenue * 1000 if revenue_unit == "thousand million pounds"

replace gdp_gnp = gdp_gnp * 1000 if gdp_gnp_unit == "thousand million pounds"

// tariff rates
gen tau_mitchell = 100 * customs_revenue / imports
gen tau = tau_uk_tamar

sort year
keep if year >= 1700

tempfile uk
save `uk'
