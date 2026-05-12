
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

* deduplicate: keep the observation with the more recent base for each year
bysort year (ind_prod_unit): keep if _n == _N
tempfile ind_prod
save `ind_prod'

* read in GDP deflator and real GDP from Global Macro Database
import delimited "intl_tariffs/data/uk_gdp_deflator.csv", clear
rename (deflator rgdp) (gdp_deflator rgdp_gmd)
drop ngdp
tempfile gmd
save `gmd'

* read in general uk data
import delimited "intl_tariffs/data/uk.csv", clear
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

************************************************************
* BUILD CONTINUOUS LOG SERIES VIA SEGMENTS
************************************************************

sort year

* --- CPI: log within segments ---
gen byte cpi_break = (cpi_base != cpi_base[_n-1]) & _n > 1 & !missing(cpi_base)
gen int cpi_seg = sum(cpi_break | (_n == 1 & !missing(cpi)))
replace cpi_seg = . if missing(cpi)
gen double lcpi = log(cpi)

* --- Industrial Production: log within segments ---
gen byte ip_break = (ind_prod_unit != ind_prod_unit[_n-1]) & _n > 1 & !missing(ind_prod_unit)
gen int ip_seg = sum(ip_break | (_n == 1 & !missing(ind_prod)))
replace ip_seg = . if missing(ind_prod)
gen double lip = log(ind_prod)

* --- Real GDP from GMD (continuous series, no base-change issues) ---
gen double lrgdp = log(rgdp_gmd)

* --- GDP deflator from GMD (continuous series, no base-change issues) ---
gen double ldefl = log(gdp_deflator)

* ensure no duplicate years before declaring time series
duplicates drop year, force
replace year = round(year)
recast int year
sort year

* time series setup
tsset year
tsfill

************************************************************
* NARRATIVE TARIFF SHOCK INSTRUMENT (time-weighted)
************************************************************

gen z = 0
	replace z = -1 * (365-188)/365 if year == 1853 // gladstone 1853 budget
	replace z = -1 * (366-182)/366 if year == 1860 // gladstone 1860 budget
	replace z = -1 if year == 1948               // GATT
	replace z = -1 * (366-182)/366 if year == 1960 // EFTA
	replace z = -1 * (366-182)/366 if year == 1968 // kennedy round
	replace z = -1 if year == 1973               // EC accession
	replace z = -1 if year == 1980               // tokyo round
	replace z = -1 if year == 1995               // WTO membership

************************************************************
* CUMULATIVE RESPONSES (y_{t+h} - y_{t-1}) in percent
* Set to missing if h-year window spans a base-change break
************************************************************

forvalues h = 0/8 {
	gen dgdp`h'   = 100 * (F`h'.lrgdp - L1.lrgdp)
	gen dip`h'    = 100 * (F`h'.lip - L1.lip)
	gen ddefl`h'  = 100 * (F`h'.ldefl - L1.ldefl)
	gen dunemp`h' = F`h'.unemployment_rate_pct - L1.unemployment_rate_pct

	* null out IP responses spanning a base-change break
	replace dip`h'  = . if F`h'.ip_seg  != L1.ip_seg  | missing(F`h'.ip_seg)  | missing(L1.ip_seg)
}

************************************************************
* CONTROLS
************************************************************

gen d_lip  = D.lip
gen infl   = D.ldefl

* null out IP growth at base-change years
replace d_lip = . if ip_seg != L1.ip_seg | missing(ip_seg) | missing(L1.ip_seg)

* pre-generate lags (avoids TS operator gap issues with reg)
gen L1_infl = L1.infl
gen L2_infl = L2.infl
gen L1_d_lip = L1.d_lip
gen L2_d_lip = L2.d_lip
gen L1_unemp = L1.unemployment_rate_pct
gen L2_unemp = L2.unemployment_rate_pct

************************************************************
* STORAGE VARIABLES FOR IRFs
************************************************************

gen horizon = .

gen b_gdp = .
gen se_gdp = .

gen b_ip = .
gen se_ip = .

gen b_defl = .
gen se_defl = .

gen b_unemp = .
gen se_unemp = .

************************************************************
* REDUCED-FORM LOCAL PROJECTIONS
* Regress outcome directly on narrative shock z_t + controls
* Coefficients = causal effect of a unit narrative shock event
* Inference: heteroskedasticity-robust SEs
************************************************************

forvalues h = 0/8 {

    local hh = `h' + 1
    local nw_lag = `h' + 1

    ********************************************************
    * GDP RESPONSE
    ********************************************************

    reg dgdp`h' ///
        z ///
        L1_infl L2_infl L1_d_lip L2_d_lip ///
        L1_unemp L2_unemp, robust

    replace horizon = `h' in `hh'
    replace b_gdp   = _b[z] in `hh'
    replace se_gdp  = _se[z] in `hh'

    ********************************************************
    * INDUSTRIAL PRODUCTION RESPONSE
    ********************************************************

    reg dip`h' ///
        z ///
        L1_infl L2_infl L1_d_lip L2_d_lip ///
        L1_unemp L2_unemp, robust

    replace b_ip  = _b[z] in `hh'
    replace se_ip = _se[z] in `hh'

    ********************************************************
    * GDP DEFLATOR RESPONSE
    ********************************************************

    reg ddefl`h' ///
        z ///
        L1_infl L2_infl L1_d_lip L2_d_lip ///
        L1_unemp L2_unemp, robust

    replace b_defl  = _b[z] in `hh'
    replace se_defl = _se[z] in `hh'

    ********************************************************
    * UNEMPLOYMENT RESPONSE
    ********************************************************

    reg dunemp`h' ///
        z ///
        L1_infl L2_infl L1_d_lip L2_d_lip ///
        L1_unemp L2_unemp, robust

    replace b_unemp  = _b[z] in `hh'
    replace se_unemp = _se[z] in `hh'
}

************************************************************
* CONFIDENCE INTERVALS (90% and 95%)
************************************************************

foreach var in gdp ip defl unemp {
    gen upper95_`var' = b_`var' + 1.96 * se_`var'
    gen lower95_`var' = b_`var' - 1.96 * se_`var'
    gen upper90_`var' = b_`var' + 1.645 * se_`var'
    gen lower90_`var' = b_`var' - 1.645 * se_`var'
}

************************************************************
* PLOTS
************************************************************

twoway ///
    (rarea upper95_gdp lower95_gdp horizon if horizon <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_gdp lower90_gdp horizon if horizon <= 8, color(blue%40) lwidth(none)) ///
    (line b_gdp horizon if horizon <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real GDP") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/rf_gdp.png", replace

twoway ///
    (rarea upper95_ip lower95_ip horizon if horizon <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_ip lower90_ip horizon if horizon <= 8, color(blue%40) lwidth(none)) ///
    (line b_ip horizon if horizon <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Industrial Production") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/rf_ip.png", replace

twoway ///
    (rarea upper95_defl lower95_defl horizon if horizon <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_defl lower90_defl horizon if horizon <= 8, color(blue%40) lwidth(none)) ///
    (line b_defl horizon if horizon <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("GDP Deflator") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/rf_deflator.png", replace

twoway ///
    (rarea upper95_unemp lower95_unemp horizon if horizon <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_unemp lower90_unemp horizon if horizon <= 8, color(blue%40) lwidth(none)) ///
    (line b_unemp horizon if horizon <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Unemployment Rate") ///
    xtitle("Years") ytitle("ppt") ///
    legend(off)
graph export "intl_tariffs/graphs/rf_unemp.png", replace
