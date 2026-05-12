
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

* read in general uk data
import delimited "intl_tariffs/data/uk.csv", clear
merge 1:1 year using `ind_prod', nogen
merge 1:1 year using `tau_tamar', nogen

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

************************************************************
* BUILD CONTINUOUS LOG SERIES VIA GROWTH RATES
* Strategy: compute log within each base period, then
* accumulate growth rates across base changes to get a
* continuous log-level series. Growth is set to missing
* at base-change years so no artificial jumps propagate.
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

* --- Real GDP: deflate within CPI base period, log within segments ---
gen rgdp = gdp_gnp / cpi
replace rgdp = . if missing(cpi) | missing(gdp_gnp)
gen int gdp_seg = cpi_seg
replace gdp_seg = . if missing(rgdp)
gen double lrgdp = log(rgdp)

* ensure no duplicate years before declaring time series
duplicates drop year, force

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
* ENDOGENOUS VARIABLES: change in tariff rate (both series)
************************************************************

gen dtau = D.tau
gen dtau_m = D.tau_mitchell

************************************************************
* CUMULATIVE RESPONSES (y_{t+h} - y_{t-1}) in percent
* Set to missing if h-year window spans a base-change break
************************************************************

forvalues h = 0/8 {
	gen dgdp`h'   = 100 * (F`h'.lrgdp - L1.lrgdp)
	gen dip`h'    = 100 * (F`h'.lip - L1.lip)
	gen dcpi`h'   = 100 * (F`h'.lcpi - L1.lcpi)
	gen dunemp`h' = F`h'.unemployment_rate_pct - L1.unemployment_rate_pct

	* null out responses spanning a base-change break
	replace dgdp`h' = . if F`h'.gdp_seg != L1.gdp_seg | missing(F`h'.gdp_seg) | missing(L1.gdp_seg)
	replace dip`h'  = . if F`h'.ip_seg  != L1.ip_seg  | missing(F`h'.ip_seg)  | missing(L1.ip_seg)
	replace dcpi`h' = . if F`h'.cpi_seg != L1.cpi_seg | missing(F`h'.cpi_seg) | missing(L1.cpi_seg)
}

************************************************************
* CONTROLS (lags for lag-augmentation, following MOP 2020)
************************************************************

gen d_lip  = D.lip
gen infl   = D.lcpi

* null out growth rates at base-change years
replace d_lip = . if ip_seg != L1.ip_seg | missing(ip_seg) | missing(L1.ip_seg)
replace infl  = . if cpi_seg != L1.cpi_seg | missing(cpi_seg) | missing(L1.cpi_seg)

************************************************************
* INSTALL PACKAGES (IF NEEDED)
************************************************************

capture which ivreg2
if _rc ssc install ivreg2

************************************************************
* TARIFF RATE COMPARISON GRAPH
* Tamar series vs Mitchell (customs/imports), with vertical
* red lines at narrative shock years
************************************************************

* build xline list from shock years
levelsof year if z != 0 & !missing(z), local(shock_years)
local xlines ""
foreach y of local shock_years {
    local xlines `"`xlines' `y'"'
}

twoway ///
    (line tau year if year >= 1800, lcolor(blue) lwidth(medthick)) ///
    (line tau_mitchell year if year >= 1800 & !missing(tau_mitchell), lcolor(black) lpattern(dash) lwidth(medium)), ///
    xline(`xlines', lcolor(red) lpattern(solid) lwidth(thin)) ///
    title("UK Tariff Rates") ///
    xtitle("Year") ytitle("Percent") ///
    legend(order(1 "Tamar series" 2 "Customs/Imports (Mitchell)") rows(1) position(6))
graph export "intl_tariffs/graphs/tariff_rates.png", replace

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

gen f_stat = .

************************************************************
* LP-IV ESTIMATION
* Specification follows equation (8) in the paper:
*   y_{i,t+h} - y_{i,t-1} = a + theta * dtau_t + controls + error
*   instrument: z_t (narrative shock) for dtau_t
* Inference: robust SEs with lag-augmentation (MOP 2020)
************************************************************

forvalues h = 0/8 {

    local hh = `h' + 1

    ********************************************************
    * GDP RESPONSE
    ********************************************************

    ivreg2 dgdp`h' ///
        L(1/2).dtau L(1/2).infl L(1/2).d_lip ///
        L(1/2).unemployment_rate_pct ///
        (dtau = z), ///
        robust

    replace horizon = `h' in `hh'
    replace b_gdp   = _b[dtau] in `hh'
    replace se_gdp  = _se[dtau] in `hh'
    replace f_stat  = e(widstat) in `hh'

    ********************************************************
    * INDUSTRIAL PRODUCTION RESPONSE
    ********************************************************

    ivreg2 dip`h' ///
        L(1/2).dtau L(1/2).infl L(1/2).d_lip ///
        L(1/2).unemployment_rate_pct ///
        (dtau = z), ///
        robust

    replace b_ip  = _b[dtau] in `hh'
    replace se_ip = _se[dtau] in `hh'

    ********************************************************
    * CPI RESPONSE
    ********************************************************

    ivreg2 dcpi`h' ///
        L(1/2).dtau L(1/2).infl L(1/2).d_lip ///
        L(1/2).unemployment_rate_pct ///
        (dtau = z), ///
        robust

    replace b_cpi  = _b[dtau] in `hh'
    replace se_cpi = _se[dtau] in `hh'

    ********************************************************
    * UNEMPLOYMENT RESPONSE
    ********************************************************

    ivreg2 dunemp`h' ///
        L(1/2).dtau L(1/2).infl L(1/2).d_lip ///
        L(1/2).unemployment_rate_pct ///
        (dtau = z), ///
        robust

    replace b_unemp  = _b[dtau] in `hh'
    replace se_unemp = _se[dtau] in `hh'
}

* display first-stage F-statistics
list horizon f_stat if horizon != .

************************************************************
* CONFIDENCE INTERVALS (90% and 95%)
************************************************************

foreach var in gdp ip cpi unemp {
    gen upper95_`var' = b_`var' + 1.96 * se_`var'
    gen lower95_`var' = b_`var' - 1.96 * se_`var'
    gen upper90_`var' = b_`var' + 1.645 * se_`var'
    gen lower90_`var' = b_`var' - 1.645 * se_`var'
}

************************************************************
* IRF PLOTS
************************************************************

twoway ///
    (rarea upper95_gdp lower95_gdp horizon if horizon <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_gdp lower90_gdp horizon if horizon <= 8, color(blue%40) lwidth(none)) ///
    (line b_gdp horizon if horizon <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real GDP") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/irf_gdp.png", replace

twoway ///
    (rarea upper95_ip lower95_ip horizon if horizon <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_ip lower90_ip horizon if horizon <= 8, color(blue%40) lwidth(none)) ///
    (line b_ip horizon if horizon <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Industrial Production") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/irf_ip.png", replace

twoway ///
    (rarea upper95_cpi lower95_cpi horizon if horizon <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_cpi lower90_cpi horizon if horizon <= 8, color(blue%40) lwidth(none)) ///
    (line b_cpi horizon if horizon <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("CPI") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/irf_cpi.png", replace

twoway ///
    (rarea upper95_unemp lower95_unemp horizon if horizon <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_unemp lower90_unemp horizon if horizon <= 8, color(blue%40) lwidth(none)) ///
    (line b_unemp horizon if horizon <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Unemployment Rate") ///
    xtitle("Years") ytitle("ppt") ///
    legend(off)
graph export "intl_tariffs/graphs/irf_unemp.png", replace

************************************************************
************************************************************
* LP-IV WITH MITCHELL TARIFF RATE (customs/imports)
************************************************************
************************************************************

gen horizon_m = .

gen b_gdp_m = .
gen se_gdp_m = .

gen b_ip_m = .
gen se_ip_m = .

gen b_cpi_m = .
gen se_cpi_m = .

gen b_unemp_m = .
gen se_unemp_m = .

gen f_stat_m = .

forvalues h = 0/8 {

    local hh = `h' + 1

    ivreg2 dgdp`h' ///
        L(1/2).dtau_m L(1/2).infl L(1/2).d_lip ///
        L(1/2).unemployment_rate_pct ///
        (dtau_m = z), ///
        robust

    replace horizon_m = `h' in `hh'
    replace b_gdp_m   = _b[dtau_m] in `hh'
    replace se_gdp_m  = _se[dtau_m] in `hh'
    replace f_stat_m  = e(widstat) in `hh'

    ivreg2 dip`h' ///
        L(1/2).dtau_m L(1/2).infl L(1/2).d_lip ///
        L(1/2).unemployment_rate_pct ///
        (dtau_m = z), ///
        robust

    replace b_ip_m  = _b[dtau_m] in `hh'
    replace se_ip_m = _se[dtau_m] in `hh'

    ivreg2 dcpi`h' ///
        L(1/2).dtau_m L(1/2).infl L(1/2).d_lip ///
        L(1/2).unemployment_rate_pct ///
        (dtau_m = z), ///
        robust

    replace b_cpi_m  = _b[dtau_m] in `hh'
    replace se_cpi_m = _se[dtau_m] in `hh'

    ivreg2 dunemp`h' ///
        L(1/2).dtau_m L(1/2).infl L(1/2).d_lip ///
        L(1/2).unemployment_rate_pct ///
        (dtau_m = z), ///
        robust

    replace b_unemp_m  = _b[dtau_m] in `hh'
    replace se_unemp_m = _se[dtau_m] in `hh'
}

* display Mitchell first-stage F-statistics
di "Mitchell series F-statistics:"
list horizon_m f_stat_m if horizon_m != .

foreach var in gdp ip cpi unemp {
    gen upper95_`var'_m = b_`var'_m + 1.96 * se_`var'_m
    gen lower95_`var'_m = b_`var'_m - 1.96 * se_`var'_m
    gen upper90_`var'_m = b_`var'_m + 1.645 * se_`var'_m
    gen lower90_`var'_m = b_`var'_m - 1.645 * se_`var'_m
}

twoway ///
    (rarea upper95_gdp_m lower95_gdp_m horizon_m if horizon_m <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_gdp_m lower90_gdp_m horizon_m if horizon_m <= 8, color(blue%40) lwidth(none)) ///
    (line b_gdp_m horizon_m if horizon_m <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real GDP (Mitchell tariff)") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/irf_gdp_mitchell.png", replace

twoway ///
    (rarea upper95_ip_m lower95_ip_m horizon_m if horizon_m <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_ip_m lower90_ip_m horizon_m if horizon_m <= 8, color(blue%40) lwidth(none)) ///
    (line b_ip_m horizon_m if horizon_m <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Industrial Production (Mitchell tariff)") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/irf_ip_mitchell.png", replace

twoway ///
    (rarea upper95_cpi_m lower95_cpi_m horizon_m if horizon_m <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_cpi_m lower90_cpi_m horizon_m if horizon_m <= 8, color(blue%40) lwidth(none)) ///
    (line b_cpi_m horizon_m if horizon_m <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("CPI (Mitchell tariff)") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/irf_cpi_mitchell.png", replace

twoway ///
    (rarea upper95_unemp_m lower95_unemp_m horizon_m if horizon_m <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_unemp_m lower90_unemp_m horizon_m if horizon_m <= 8, color(blue%40) lwidth(none)) ///
    (line b_unemp_m horizon_m if horizon_m <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Unemployment Rate (Mitchell tariff)") ///
    xtitle("Years") ytitle("ppt") ///
    legend(off)
graph export "intl_tariffs/graphs/irf_unemp_mitchell.png", replace









