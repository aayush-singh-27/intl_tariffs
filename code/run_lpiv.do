
* read in tamar uk tariff data
import excel "intl_tariffs/data/foreign_tariff_rates_final.xlsx", sheet("GBR") cellrange(A2:E187) firstrow clear
keep year tau_gbr_own
rename tau_gbr_own tau_uk_tamar
tempfile tau_tamar
save `tau_tamar'

* read in industrial production data
import delimited "intl_tariffs/data/industrial_production_index_europe.csv", clear

keep if country == "United Kingdom"
rename (index_value base) (ind_prod ind_prod_unit)
drop country
drop if year == 1949 & ind_prod_unit == "1937=100"
tempfile ind_prod
save `ind_prod'

* read in general uk data
import delimited "intl_tariffs/data/intermediate_data/uk.csv", clear
merge 1:m year using `ind_prod', nogen
merge m:1 year using `tau_tamar', nogen

* harmonize variable units to get everything in million pounds
replace imports = imports * 1000 if trade_unit == "thousand million pounds"
replace exports = exports * 1000 if trade_unit == "thousand million pounds"

replace govt_revenue_total = govt_revenue_total / 1000 if revenue_unit == "thousand pounds"
replace govt_revenue_total = govt_revenue_total * 1000 if revenue_unit == "thousand million pounds"

replace customs_revenue = customs_revenue / 1000 if revenue_unit == "thousand pounds"
replace customs_revenue = customs_revenue * 1000 if revenue_unit == "thousand million pounds"

replace gdp_gnp = gdp_gnp * 1000 if gdp_gnp_unit == "thousand million pounds"

// generate tariff rate
gen tau_uk_mitchell = 100 * customs_revenue / imports

* make variables real
gen rgdp = gdp_gnp / cpi
gen rimports = imports / cpi
gen rexports = exports / cpi

* growth variables (setting year where base changes to missing)
sort year

gen cpi_growth = log(cpi) - log(cpi[_n-1])
replace cpi_growth = . if cpi_base != cpi_base[_n-1]

gen ip_growth = log(ind_prod) - log(ind_prod[_n-1])
replace ip_growth = . if ind_prod_unit != ind_prod_unit[_n-1]

replace cpi = . if cpi_base != cpi_base[_n-1] & year > 1781
replace ind_prod = . if ind_prod_unit != ind_prod_unit[_n-1] & year > 1801

// take logs
gen lrgdp = log(rgdp)
gen lrimports = log(rimports)
gen lrexports = log(rexports)
gen lip = log(ind_prod)
gen lcpi = log(cpi)

* responses for local projections
tsset year
tsfill

forvalues h = 0/8 {

	// GDP response
	gen dgdp`h' = F`h'.lrgdp - L1.lrgdp

	// industrial production response
	gen dip`h' = F`h'.lip - L1.lip

	// price level response
	gen dcpi`h' = F`h'.lcpi - L1.lcpi

	// unemployment response
	gen dunemp`h' = F`h'.unemployment_rate_pct - L1.unemployment_rate_pct
}


* assign time-weighted tariff shocks
gen tariff_shock = 0
	replace tariff_shock = -1 * (365-188)/365 if year == 1853 // gladstone 1853 budget
	replace tariff_shock = -1 * (366-182)/366 if year == 1860 // gladstone 1860 budget
	replace tariff_shock = -1 if year == 1948 		  // GATT
	replace tariff_shock = -1 * (366-182)/366 if year == 1960 // EFTA
	replace tariff_shock = -1 * (366-182)/366 if year == 1968 // kennedy round
	replace tariff_shock = -1 if year == 1973 		  // EC
	replace tariff_shock = -1 if year == 1980 		  // tokyo round
	replace tariff_shock = -1 if year == 1995 		  // WTO membership

************************************************************
* CLEANUP / FIXES
************************************************************

* use chained/clean CPI before deflating
replace rgdp = . if missing(cpi)
replace rimports = . if missing(cpi)
replace rexports = . if missing(cpi)

* scale LP responses to percent
forvalues h = 0/8 {

    replace dgdp`h' = 100 * dgdp`h'
    replace dip`h'  = 100 * dip`h'
    replace dcpi`h' = 100 * dcpi`h'
}

************************************************************
* CREATE CONTROL VARIABLES
************************************************************

* annual GDP growth
gen d_lrgdp = D.lrgdp

* annual inflation
gen infl = D.lcpi

* annual IP growth
gen d_lip = D.lip

************************************************************
* INSTALL LP PACKAGE (IF NEEDED)
************************************************************

capture which newey
if _rc ssc install newey

************************************************************
* STORAGE VARIABLES FOR IRFs
************************************************************

gen horizon = .
gen b_gdp = .
gen se_gdp = .

gen b_ip = .
gen se_ip = .

gen b_cpi = .
gen se_cpi = .

gen b_unemp = .
gen se_unemp = .

************************************************************
* LOCAL PROJECTIONS
************************************************************

forvalues h = 0/8 {

    di "Running horizon `h'"

    ********************************************************
    * GDP RESPONSE
    ********************************************************

    ivreg2 dgdp`h' ///
        tariff_shock ///
        L(1/2).d_lrgdp ///
        L(1/2).infl ///
        L(1/2).unemployment_rate_pct, ///
        lag(`h')

    replace horizon = `h' in `=`h'+1'
    replace b_gdp = _b[tariff_shock] in `=`h'+1'
    replace se_gdp = _se[tariff_shock] in `=`h'+1'

    ********************************************************
    * INDUSTRIAL PRODUCTION RESPONSE
    ********************************************************

    newey dip`h' ///
        tariff_shock ///
        L(1/2).d_lip ///
        L(1/2).infl ///
        L(1/2).unemployment_rate_pct, ///
        lag(`h')

    replace b_ip = _b[tariff_shock] in `=`h'+1'
    replace se_ip = _se[tariff_shock] in `=`h'+1'

    ********************************************************
    * CPI RESPONSE
    ********************************************************

    newey dcpi`h' ///
        tariff_shock ///
        L(1/2).infl ///
        L(1/2).d_lrgdp ///
        L(1/2).unemployment_rate_pct, ///
        lag(`h')

    replace b_cpi = _b[tariff_shock] in `=`h'+1'
    replace se_cpi = _se[tariff_shock] in `=`h'+1'

    ********************************************************
    * UNEMPLOYMENT RESPONSE
    ********************************************************

    newey dunemp`h' ///
        tariff_shock ///
        L(1/2).d_lrgdp ///
        L(1/2).infl ///
        L(1/2).unemployment_rate_pct, ///
        lag(`h')

    replace b_unemp = _b[tariff_shock] in `=`h'+1'
    replace se_unemp = _se[tariff_shock] in `=`h'+1'
}

************************************************************
* CONFIDENCE INTERVALS
************************************************************

foreach var in gdp ip cpi unemp {

    gen upper_`var' = b_`var' + 1.96 * se_`var'
    gen lower_`var' = b_`var' - 1.96 * se_`var'
}

************************************************************
* PLOTS
************************************************************

twoway ///
    (rarea upper_gdp lower_gdp horizon if horizon <= 8) ///
    (line b_gdp horizon if horizon <= 8), ///
    yline(0) ///
    title("GDP response to tariff liberalization shock") ///
    xtitle("Years after shock") ///
    ytitle("Percent")

twoway ///
    (rarea upper_ip lower_ip horizon if horizon <= 8) ///
    (line b_ip horizon if horizon <= 8), ///
    yline(0) ///
    title("Industrial production response") ///
    xtitle("Years after shock")

twoway ///
    (rarea upper_cpi lower_cpi horizon if horizon <= 8) ///
    (line b_cpi horizon if horizon <= 8), ///
    yline(0) ///
    title("CPI response") ///
    xtitle("Years after shock")

twoway ///
    (rarea upper_unemp lower_unemp horizon if horizon <= 8) ///
    (line b_unemp horizon if horizon <= 8), ///
    yline(0) ///
    title("Unemployment response") ///
    xtitle("Years after shock")

















