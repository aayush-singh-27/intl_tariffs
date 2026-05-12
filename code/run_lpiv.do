
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

// tariff rate: use Tamar's series
gen tau = tau_uk_tamar

* handle base changes in CPI and IP
sort year
replace cpi = . if cpi_base != cpi_base[_n-1] & year > 1781
replace ind_prod = . if ind_prod_unit != ind_prod_unit[_n-1] & year > 1801

* make variables real
gen rgdp = gdp_gnp / cpi
gen rimports = imports / cpi
gen rexports = exports / cpi

replace rgdp = . if missing(cpi)
replace rimports = . if missing(cpi)
replace rexports = . if missing(cpi)

// take logs
gen lrgdp = log(rgdp)
gen lrimports = log(rimports)
gen lrexports = log(rexports)
gen lip = log(ind_prod)
gen lcpi = log(cpi)

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
* ENDOGENOUS VARIABLE: change in tariff rate
************************************************************

gen dtau = D.tau

************************************************************
* CUMULATIVE RESPONSES (y_{t+h} - y_{t-1}) in percent
************************************************************

forvalues h = 0/8 {
	gen dgdp`h'   = 100 * (F`h'.lrgdp - L1.lrgdp)
	gen dip`h'    = 100 * (F`h'.lip - L1.lip)
	gen dcpi`h'   = 100 * (F`h'.lcpi - L1.lcpi)
	gen dunemp`h' = F`h'.unemployment_rate_pct - L1.unemployment_rate_pct
}

************************************************************
* CONTROLS (lags for lag-augmentation, following MOP 2020)
************************************************************

gen d_lip  = D.lip
gen infl   = D.lcpi

************************************************************
* INSTALL ivreg2 (IF NEEDED)
************************************************************

capture which ivreg2
if _rc ssc install ivreg2

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
*   — include p extra lags of controls beyond specification need
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

twoway ///
    (rarea upper95_ip lower95_ip horizon if horizon <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_ip lower90_ip horizon if horizon <= 8, color(blue%40) lwidth(none)) ///
    (line b_ip horizon if horizon <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Industrial Production") ///
    xtitle("Years") ytitle("%") ///
    legend(off)

twoway ///
    (rarea upper95_cpi lower95_cpi horizon if horizon <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_cpi lower90_cpi horizon if horizon <= 8, color(blue%40) lwidth(none)) ///
    (line b_cpi horizon if horizon <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("CPI") ///
    xtitle("Years") ytitle("%") ///
    legend(off)

twoway ///
    (rarea upper95_unemp lower95_unemp horizon if horizon <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_unemp lower90_unemp horizon if horizon <= 8, color(blue%40) lwidth(none)) ///
    (line b_unemp horizon if horizon <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Unemployment Rate") ///
    xtitle("Years") ytitle("ppt") ///
    legend(off)

















