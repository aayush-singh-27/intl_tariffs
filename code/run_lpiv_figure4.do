
************************************************************
* LP-IV FIGURE 4 REPLICATION
* Reproducing Den Besten & Kanzig (2025) Figure 4 IRFs:
*   tariff rate, GDP deflator, real GDP, unemployment,
*   real imports, real exports, industrial production
* Both pooled panel and country-by-country
************************************************************

clear all
set more off

************************************************************
* LOAD PANEL
************************************************************

import delimited "intl_tariffs/data/panel.csv", clear

encode iso3, gen(cid)
xtset cid year
tsfill

decode cid, gen(iso3_filled)
replace iso3 = iso3_filled if missing(iso3)
drop iso3_filled

************************************************************
* INSTALL PACKAGES (IF NEEDED)
************************************************************

capture which ivreg2
if _rc ssc install ivreg2

capture which ranktest
if _rc ssc install ranktest

************************************************************
* NARRATIVE TARIFF SHOCK INSTRUMENTS
* (identical coding to run_lpiv.do)
************************************************************

gen z = 0

* --- GBR ---
replace z = z + -1 * (365-32)/365  if iso3 == "GBR" & year == 1849
replace z = z + -1 * 32/365        if iso3 == "GBR" & year == 1850
replace z = z + -1 * (365-232)/365 if iso3 == "GBR" & year == 1853
replace z = z + -1 * 232/365       if iso3 == "GBR" & year == 1854
replace z = z + -1 * (366-183)/366 if iso3 == "GBR" & year == 1860
replace z = z + -1 * 183/366       if iso3 == "GBR" & year == 1861
replace z = z + -1 * (366-1)/366   if iso3 == "GBR" & year == 1948
replace z = z + -1 * (366-1)/366   if iso3 == "GBR" & year == 1968
replace z = z + -1 * (365-1)/365   if iso3 == "GBR" & year == 1973
replace z = z + -1 * (366-1)/366   if iso3 == "GBR" & year == 1980

* --- FRA ---
replace z = z + -1 * (366-205)/366 if iso3 == "FRA" & year == 1860
replace z = z + -1 * 205/366       if iso3 == "FRA" & year == 1861
replace z = z + (365-127)/365 if iso3 == "FRA" & year == 1881
replace z = z + 127/365       if iso3 == "FRA" & year == 1882
replace z = z + (366-11)/366  if iso3 == "FRA" & year == 1892
replace z = z + 11/366        if iso3 == "FRA" & year == 1893
replace z = z + (365-88)/365  if iso3 == "FRA" & year == 1910
replace z = z + 88/365        if iso3 == "FRA" & year == 1911
replace z = z + (365-215)/365 if iso3 == "FRA" & year == 1927
replace z = z + 215/365       if iso3 == "FRA" & year == 1928
replace z = z + -1 * (366-1)/366   if iso3 == "FRA" & year == 1948
replace z = z + -1 * (365-1)/365   if iso3 == "FRA" & year == 1963
replace z = z + -1 * (366-1)/366   if iso3 == "FRA" & year == 1968
replace z = z + -1 * (366-1)/366   if iso3 == "FRA" & year == 1980

* --- DEU ---
replace z = z + -1 * (365-1)/365   if iso3 == "DEU" & year == 1853
replace z = z + -1 * (365-1)/365   if iso3 == "DEU" & year == 1866
replace z = z + -1 * (365-1)/365   if iso3 == "DEU" & year == 1873
replace z = z + (365-1)/365   if iso3 == "DEU" & year == 1903
replace z = z + -1 * (365-1)/365   if iso3 == "DEU" & year == 1963
replace z = z + -1 * (366-1)/366   if iso3 == "DEU" & year == 1968
replace z = z + -1 * (366-1)/366   if iso3 == "DEU" & year == 1980

* --- ITA ---
replace z = z + -1 * (366-1)/366   if iso3 == "ITA" & year == 1860
replace z = z + -1 * (365-1)/365   if iso3 == "ITA" & year == 1963
replace z = z + -1 * (366-1)/366   if iso3 == "ITA" & year == 1968
replace z = z + -1 * (366-1)/366   if iso3 == "ITA" & year == 1980

* --- NLD ---
replace z = z + (365-1)/365   if iso3 == "NLD" & year == 1925
replace z = z + -1 * (365-1)/365   if iso3 == "NLD" & year == 1963
replace z = z + -1 * (366-1)/366   if iso3 == "NLD" & year == 1968
replace z = z + -1 * (366-1)/366   if iso3 == "NLD" & year == 1980

* --- BEL ---
replace z = z + -1 * (366-1)/366   if iso3 == "BEL" & year == 1948
replace z = z + -1 * (366-1)/366   if iso3 == "BEL" & year == 1968
replace z = z + -1 * (366-1)/366   if iso3 == "BEL" & year == 1980

* --- PRT ---
replace z = z + -1 * (366-183)/366 if iso3 == "PRT" & year == 1960
replace z = z + -1 * 183/366       if iso3 == "PRT" & year == 1961
replace z = z + -1 * (365-1)/365   if iso3 == "PRT" & year == 1963
replace z = z + -1 * (366-1)/366   if iso3 == "PRT" & year == 1968
replace z = z + -1 * (365-1)/365   if iso3 == "PRT" & year == 1973

* --- CHE ---
replace z = z + -1 * (366-1)/366   if iso3 == "CHE" & year == 1864
replace z = z + (365-1)/365   if iso3 == "CHE" & year == 1891
replace z = z + -1 * (366-1)/366   if iso3 == "CHE" & year == 1968
replace z = z + -1 * (365-1)/365   if iso3 == "CHE" & year == 1973
replace z = z + -1 * (366-1)/366   if iso3 == "CHE" & year == 1980

* --- ESP ---
replace z = z + -1 * (365-1)/365   if iso3 == "ESP" & year == 1963
replace z = z + -1 * (366-1)/366   if iso3 == "ESP" & year == 1968

* --- JPN ---
replace z = z + -1 * (366-1)/366   if iso3 == "JPN" & year == 1968
replace z = z + -1 * (366-1)/366   if iso3 == "JPN" & year == 1980

* --- BRA ---
replace z = z + -1 * (366-1)/366   if iso3 == "BRA" & year == 1948

* --- MEX ---
replace z = z + -1 * (365-236)/365 if iso3 == "MEX" & year == 1986
replace z = z + -1 * 236/365       if iso3 == "MEX" & year == 1987

************************************************************
* CONSTRUCT VARIABLES
************************************************************

gen double lrgdp = log(rgdp)
gen double ldefl = log(gdp_deflator)

* real imports and exports (deflate by CPI)
gen double rimp = imports / cpi_gmd
gen double rexp = exports / cpi_gmd
gen double lrimp = log(rimp)
gen double lrexp = log(rexp)
gen double lip = log(ind_prod)

* change in tariff rate (endogenous variable)
gen dtau = D.tau_tamar

* cumulative responses at each horizon: y_{t+h} - y_{t-1}
forvalues h = 0/8 {
    * tariff rate (cumulative change, ppt)
    gen dtau_cum`h' = F`h'.tau_tamar - L1.tau_tamar

    * real GDP (%)
    gen dgdp`h' = 100 * (F`h'.lrgdp - L1.lrgdp)

    * GDP deflator (%)
    gen ddefl`h' = 100 * (F`h'.ldefl - L1.ldefl)

    * unemployment (ppt)
    gen dunemp`h' = F`h'.unemployment_rate_pct - L1.unemployment_rate_pct

    * real imports (%)
    gen dimp`h' = 100 * (F`h'.lrimp - L1.lrimp)

    * real exports (%)
    gen dexp`h' = 100 * (F`h'.lrexp - L1.lrexp)

    * industrial production (%)
    gen dip`h' = 100 * (F`h'.lip - L1.lip)
}

************************************************************
* CONTROLS
* Lag of outcome + lag of GDP growth + lag of inflation
* (following Den Besten & Kanzig specification)
************************************************************

gen L1_dgdp = 100 * (lrgdp - L1.lrgdp)
gen L1_ddefl = 100 * (ldefl - L1.ldefl)
gen L1_dtau = L1.dtau
gen L1_dunemp = unemployment_rate_pct - L1.unemployment_rate_pct
gen L1_dimp = 100 * (lrimp - L1.lrimp)
gen L1_dexp = 100 * (lrexp - L1.lrexp)
gen L1_dip = 100 * (lip - L1.lip)

************************************************************
* CREATE OUTPUT DIRECTORIES
************************************************************

capture mkdir "intl_tariffs/graphs/lp_iv_fig4"
foreach cc in GBR FRA DEU ITA NLD BEL PRT CHE ESP JPN BRA MEX {
    capture mkdir "intl_tariffs/graphs/lp_iv_fig4/`cc'"
}

************************************************************
* SAMPLE
************************************************************

gen byte sample_full = (iso3 != "ARG")

************************************************************
************************************************************
* POOLED PANEL ESTIMATION (Figure 4 equivalent)
************************************************************
************************************************************

di _n "============================================================"
di "POOLED PANEL — FIGURE 4 REPLICATION"
di "============================================================"

count if z != 0 & sample_full == 1 & !missing(dtau)
di "Shocks in estimation sample: " r(N)

* storage for 7 outcomes
foreach v in tau gdp defl unemp imp exp ip {
    gen horizon_`v' = .
    gen b_`v' = .
    gen se_`v' = .
}
gen f_stat_pool = .

forvalues h = 0/8 {

    local hh = `h' + 1

    * TARIFF RATE (dynamic first stage)
    capture ivreg2 dtau_cum`h' ///
        i.cid L1_dtau L1_dgdp L1_ddefl ///
        (dtau = z) ///
        if sample_full == 1, ///
        robust

    if _rc == 0 {
        replace horizon_tau = `h' in `hh'
        replace b_tau   = _b[dtau] in `hh'
        replace se_tau  = _se[dtau] in `hh'
        replace f_stat_pool = e(widstat) in `hh'
    }

    * REAL GDP
    capture ivreg2 dgdp`h' ///
        i.cid L1_dgdp L1_ddefl ///
        (dtau = z) ///
        if sample_full == 1, ///
        robust

    if _rc == 0 {
        replace horizon_gdp = `h' in `hh'
        replace b_gdp   = _b[dtau] in `hh'
        replace se_gdp  = _se[dtau] in `hh'
    }

    * GDP DEFLATOR
    capture ivreg2 ddefl`h' ///
        i.cid L1_ddefl L1_dgdp ///
        (dtau = z) ///
        if sample_full == 1, ///
        robust

    if _rc == 0 {
        replace horizon_defl = `h' in `hh'
        replace b_defl  = _b[dtau] in `hh'
        replace se_defl = _se[dtau] in `hh'
    }

    * UNEMPLOYMENT
    capture ivreg2 dunemp`h' ///
        i.cid L1_dunemp L1_dgdp L1_ddefl ///
        (dtau = z) ///
        if sample_full == 1, ///
        robust

    if _rc == 0 {
        replace horizon_unemp = `h' in `hh'
        replace b_unemp  = _b[dtau] in `hh'
        replace se_unemp = _se[dtau] in `hh'
    }

    * REAL IMPORTS
    capture ivreg2 dimp`h' ///
        i.cid L1_dimp L1_dgdp L1_ddefl ///
        (dtau = z) ///
        if sample_full == 1, ///
        robust

    if _rc == 0 {
        replace horizon_imp = `h' in `hh'
        replace b_imp   = _b[dtau] in `hh'
        replace se_imp  = _se[dtau] in `hh'
    }

    * REAL EXPORTS
    capture ivreg2 dexp`h' ///
        i.cid L1_dexp L1_dgdp L1_ddefl ///
        (dtau = z) ///
        if sample_full == 1, ///
        robust

    if _rc == 0 {
        replace horizon_exp = `h' in `hh'
        replace b_exp   = _b[dtau] in `hh'
        replace se_exp  = _se[dtau] in `hh'
    }

    * INDUSTRIAL PRODUCTION
    capture ivreg2 dip`h' ///
        i.cid L1_dip L1_dgdp L1_ddefl ///
        (dtau = z) ///
        if sample_full == 1, ///
        robust

    if _rc == 0 {
        replace horizon_ip = `h' in `hh'
        replace b_ip    = _b[dtau] in `hh'
        replace se_ip   = _se[dtau] in `hh'
    }
}

di _n "First-stage F-statistics (pooled panel):"
list horizon_tau f_stat_pool if horizon_tau != ., noobs clean

* grab h=0 F-stat for subtitles
local f0 = f_stat_pool[1]
local f0_str : di %4.2f `f0'

************************************************************
* POOLED: CONFIDENCE INTERVALS AND PLOTS
************************************************************

foreach v in tau gdp defl unemp imp exp ip {
    gen up95_`v' = b_`v' + 1.96 * se_`v'
    gen lo95_`v' = b_`v' - 1.96 * se_`v'
    gen up90_`v' = b_`v' + 1.645 * se_`v'
    gen lo90_`v' = b_`v' - 1.645 * se_`v'
}

twoway ///
    (rarea up95_tau lo95_tau horizon_tau if horizon_tau <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_tau lo90_tau horizon_tau if horizon_tau <= 8, color(blue%40) lwidth(none)) ///
    (line b_tau horizon_tau if horizon_tau <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Tariff Rate") ///
    subtitle("First-stage F = `f0_str'") ///
    xtitle("Years") ytitle("ppt") ///
    legend(off)
graph export "intl_tariffs/graphs/lp_iv_fig4/pool_irf_tau.png", replace

twoway ///
    (rarea up95_gdp lo95_gdp horizon_gdp if horizon_gdp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_gdp lo90_gdp horizon_gdp if horizon_gdp <= 8, color(blue%40) lwidth(none)) ///
    (line b_gdp horizon_gdp if horizon_gdp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real GDP") ///
    subtitle("First-stage F = `f0_str'") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/lp_iv_fig4/pool_irf_gdp.png", replace

twoway ///
    (rarea up95_defl lo95_defl horizon_defl if horizon_defl <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_defl lo90_defl horizon_defl if horizon_defl <= 8, color(blue%40) lwidth(none)) ///
    (line b_defl horizon_defl if horizon_defl <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("GDP Deflator") ///
    subtitle("First-stage F = `f0_str'") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/lp_iv_fig4/pool_irf_defl.png", replace

twoway ///
    (rarea up95_unemp lo95_unemp horizon_unemp if horizon_unemp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_unemp lo90_unemp horizon_unemp if horizon_unemp <= 8, color(blue%40) lwidth(none)) ///
    (line b_unemp horizon_unemp if horizon_unemp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Unemployment") ///
    subtitle("First-stage F = `f0_str'") ///
    xtitle("Years") ytitle("ppt") ///
    legend(off)
graph export "intl_tariffs/graphs/lp_iv_fig4/pool_irf_unemp.png", replace

twoway ///
    (rarea up95_imp lo95_imp horizon_imp if horizon_imp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_imp lo90_imp horizon_imp if horizon_imp <= 8, color(blue%40) lwidth(none)) ///
    (line b_imp horizon_imp if horizon_imp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real Imports") ///
    subtitle("First-stage F = `f0_str'") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/lp_iv_fig4/pool_irf_imp.png", replace

twoway ///
    (rarea up95_exp lo95_exp horizon_exp if horizon_exp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_exp lo90_exp horizon_exp if horizon_exp <= 8, color(blue%40) lwidth(none)) ///
    (line b_exp horizon_exp if horizon_exp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real Exports") ///
    subtitle("First-stage F = `f0_str'") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/lp_iv_fig4/pool_irf_exp.png", replace

twoway ///
    (rarea up95_ip lo95_ip horizon_ip if horizon_ip <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_ip lo90_ip horizon_ip if horizon_ip <= 8, color(blue%40) lwidth(none)) ///
    (line b_ip horizon_ip if horizon_ip <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Industrial Production") ///
    subtitle("First-stage F = `f0_str'") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/lp_iv_fig4/pool_irf_ip.png", replace

* clean up pooled storage
foreach v in tau gdp defl unemp imp exp ip {
    drop horizon_`v' b_`v' se_`v' up95_`v' lo95_`v' up90_`v' lo90_`v'
}
drop f_stat_pool

************************************************************
************************************************************
* COUNTRY-BY-COUNTRY ESTIMATION
************************************************************
************************************************************

di _n _n "############################################################"
di "COUNTRY-BY-COUNTRY FIGURE 4"
di "############################################################"

local countries GBR FRA DEU ITA NLD BEL PRT CHE ESP JPN BRA MEX

foreach cc of local countries {

    di _n "============================================================"
    di "COUNTRY: `cc'"
    di "============================================================"

    count if z != 0 & iso3 == "`cc'" & !missing(dtau)
    local nshocks = r(N)
    di "Shocks in estimation sample: `nshocks'"

    if `nshocks' < 2 {
        di "Skipping `cc' — fewer than 2 shocks"
        continue
    }

    * storage
    tempvar hz bt set bg seg bd sed bu seu bi sei be see bp sep fs
    gen `hz' = .
    gen `bt' = .
    gen `set' = .
    gen `bg' = .
    gen `seg' = .
    gen `bd' = .
    gen `sed' = .
    gen `bu' = .
    gen `seu' = .
    gen `bi' = .
    gen `sei' = .
    gen `be' = .
    gen `see' = .
    gen `bp' = .
    gen `sep' = .
    gen `fs' = .

    forvalues h = 0/8 {

        local hh = `h' + 1

        * TARIFF RATE
        capture ivreg2 dtau_cum`h' ///
            L1_dtau L1_dgdp L1_ddefl ///
            (dtau = z) ///
            if iso3 == "`cc'", ///
            robust

        if _rc == 0 {
            replace `hz' = `h' in `hh'
            replace `bt' = _b[dtau] in `hh'
            replace `set' = _se[dtau] in `hh'
            replace `fs' = e(widstat) in `hh'
        }

        * REAL GDP
        capture ivreg2 dgdp`h' ///
            L1_dgdp L1_ddefl ///
            (dtau = z) ///
            if iso3 == "`cc'", ///
            robust

        if _rc == 0 {
            replace `bg' = _b[dtau] in `hh'
            replace `seg' = _se[dtau] in `hh'
        }

        * GDP DEFLATOR
        capture ivreg2 ddefl`h' ///
            L1_ddefl L1_dgdp ///
            (dtau = z) ///
            if iso3 == "`cc'", ///
            robust

        if _rc == 0 {
            replace `bd' = _b[dtau] in `hh'
            replace `sed' = _se[dtau] in `hh'
        }

        * UNEMPLOYMENT
        capture ivreg2 dunemp`h' ///
            L1_dunemp L1_dgdp L1_ddefl ///
            (dtau = z) ///
            if iso3 == "`cc'", ///
            robust

        if _rc == 0 {
            replace `bu' = _b[dtau] in `hh'
            replace `seu' = _se[dtau] in `hh'
        }

        * REAL IMPORTS
        capture ivreg2 dimp`h' ///
            L1_dimp L1_dgdp L1_ddefl ///
            (dtau = z) ///
            if iso3 == "`cc'", ///
            robust

        if _rc == 0 {
            replace `bi' = _b[dtau] in `hh'
            replace `sei' = _se[dtau] in `hh'
        }

        * REAL EXPORTS
        capture ivreg2 dexp`h' ///
            L1_dexp L1_dgdp L1_ddefl ///
            (dtau = z) ///
            if iso3 == "`cc'", ///
            robust

        if _rc == 0 {
            replace `be' = _b[dtau] in `hh'
            replace `see' = _se[dtau] in `hh'
        }

        * INDUSTRIAL PRODUCTION
        capture ivreg2 dip`h' ///
            L1_dip L1_dgdp L1_ddefl ///
            (dtau = z) ///
            if iso3 == "`cc'", ///
            robust

        if _rc == 0 {
            replace `bp' = _b[dtau] in `hh'
            replace `sep' = _se[dtau] in `hh'
        }
    }

    di _n "First-stage F-statistics (`cc'):"
    list `hz' `fs' if `hz' != ., noobs clean

    * grab h=0 F-stat for subtitles
    local cf0 = `fs'[1]
    local cf0_str : di %4.2f `cf0'

    * confidence intervals
    tempvar u95t l95t u90t l90t u95g l95g u90g l90g u95d l95d u90d l90d
    tempvar u95u l95u u90u l90u u95i l95i u90i l90i u95e l95e u90e l90e u95p l95p u90p l90p
    gen `u95t' = `bt' + 1.96 * `set'
    gen `l95t' = `bt' - 1.96 * `set'
    gen `u90t' = `bt' + 1.645 * `set'
    gen `l90t' = `bt' - 1.645 * `set'
    gen `u95g' = `bg' + 1.96 * `seg'
    gen `l95g' = `bg' - 1.96 * `seg'
    gen `u90g' = `bg' + 1.645 * `seg'
    gen `l90g' = `bg' - 1.645 * `seg'
    gen `u95d' = `bd' + 1.96 * `sed'
    gen `l95d' = `bd' - 1.96 * `sed'
    gen `u90d' = `bd' + 1.645 * `sed'
    gen `l90d' = `bd' - 1.645 * `sed'
    gen `u95u' = `bu' + 1.96 * `seu'
    gen `l95u' = `bu' - 1.96 * `seu'
    gen `u90u' = `bu' + 1.645 * `seu'
    gen `l90u' = `bu' - 1.645 * `seu'
    gen `u95i' = `bi' + 1.96 * `sei'
    gen `l95i' = `bi' - 1.96 * `sei'
    gen `u90i' = `bi' + 1.645 * `sei'
    gen `l90i' = `bi' - 1.645 * `sei'
    gen `u95e' = `be' + 1.96 * `see'
    gen `l95e' = `be' - 1.96 * `see'
    gen `u90e' = `be' + 1.645 * `see'
    gen `l90e' = `be' - 1.645 * `see'
    gen `u95p' = `bp' + 1.96 * `sep'
    gen `l95p' = `bp' - 1.96 * `sep'
    gen `u90p' = `bp' + 1.645 * `sep'
    gen `l90p' = `bp' - 1.645 * `sep'

    * plots
    twoway ///
        (rarea `u95t' `l95t' `hz' if `hz' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `u90t' `l90t' `hz' if `hz' <= 8, color(blue%40) lwidth(none)) ///
        (line `bt' `hz' if `hz' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("Tariff Rate — `cc'") ///
        subtitle("First-stage F = `cf0_str'") ///
        xtitle("Years") ytitle("ppt") ///
        legend(off)
    graph export "intl_tariffs/graphs/lp_iv_fig4/`cc'/irf_tau.png", replace

    twoway ///
        (rarea `u95g' `l95g' `hz' if `hz' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `u90g' `l90g' `hz' if `hz' <= 8, color(blue%40) lwidth(none)) ///
        (line `bg' `hz' if `hz' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("Real GDP — `cc'") ///
        subtitle("First-stage F = `cf0_str'") ///
        xtitle("Years") ytitle("%") ///
        legend(off)
    graph export "intl_tariffs/graphs/lp_iv_fig4/`cc'/irf_gdp.png", replace

    twoway ///
        (rarea `u95d' `l95d' `hz' if `hz' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `u90d' `l90d' `hz' if `hz' <= 8, color(blue%40) lwidth(none)) ///
        (line `bd' `hz' if `hz' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("GDP Deflator — `cc'") ///
        subtitle("First-stage F = `cf0_str'") ///
        xtitle("Years") ytitle("%") ///
        legend(off)
    graph export "intl_tariffs/graphs/lp_iv_fig4/`cc'/irf_defl.png", replace

    twoway ///
        (rarea `u95u' `l95u' `hz' if `hz' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `u90u' `l90u' `hz' if `hz' <= 8, color(blue%40) lwidth(none)) ///
        (line `bu' `hz' if `hz' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("Unemployment — `cc'") ///
        subtitle("First-stage F = `cf0_str'") ///
        xtitle("Years") ytitle("ppt") ///
        legend(off)
    graph export "intl_tariffs/graphs/lp_iv_fig4/`cc'/irf_unemp.png", replace

    twoway ///
        (rarea `u95i' `l95i' `hz' if `hz' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `u90i' `l90i' `hz' if `hz' <= 8, color(blue%40) lwidth(none)) ///
        (line `bi' `hz' if `hz' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("Real Imports — `cc'") ///
        subtitle("First-stage F = `cf0_str'") ///
        xtitle("Years") ytitle("%") ///
        legend(off)
    graph export "intl_tariffs/graphs/lp_iv_fig4/`cc'/irf_imp.png", replace

    twoway ///
        (rarea `u95e' `l95e' `hz' if `hz' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `u90e' `l90e' `hz' if `hz' <= 8, color(blue%40) lwidth(none)) ///
        (line `be' `hz' if `hz' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("Real Exports — `cc'") ///
        subtitle("First-stage F = `cf0_str'") ///
        xtitle("Years") ytitle("%") ///
        legend(off)
    graph export "intl_tariffs/graphs/lp_iv_fig4/`cc'/irf_exp.png", replace

    twoway ///
        (rarea `u95p' `l95p' `hz' if `hz' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `u90p' `l90p' `hz' if `hz' <= 8, color(blue%40) lwidth(none)) ///
        (line `bp' `hz' if `hz' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("Industrial Production — `cc'") ///
        subtitle("First-stage F = `cf0_str'") ///
        xtitle("Years") ytitle("%") ///
        legend(off)
    graph export "intl_tariffs/graphs/lp_iv_fig4/`cc'/irf_ip.png", replace

    * clean up
    drop `hz' `bt' `set' `bg' `seg' `bd' `sed' `bu' `seu' `bi' `sei' `be' `see' `bp' `sep' `fs'
    drop `u95t' `l95t' `u90t' `l90t' `u95g' `l95g' `u90g' `l90g' `u95d' `l95d' `u90d' `l90d'
    drop `u95u' `l95u' `u90u' `l90u' `u95i' `l95i' `u90i' `l90i' `u95e' `l95e' `u90e' `l90e' `u95p' `l95p' `u90p' `l90p'
}

************************************************************
************************************************************
* EUROPEAN PRE-WWI POOLED (year <= 1913)
************************************************************
************************************************************

di _n _n "############################################################"
di "EUROPEAN PRE-WWI POOLED — FIGURE 4"
di "############################################################"

capture mkdir "intl_tariffs/graphs/lp_iv_fig4/pool_eu_preww1"

gen byte eu_preww1 = inlist(iso3, "GBR", "FRA", "DEU", "ITA", "NLD", "BEL", "PRT", "CHE", "ESP") & year <= 1913

count if z != 0 & eu_preww1 == 1 & !missing(dtau)
di "Pre-WWI European shocks in estimation sample: " r(N)

foreach v in tau gdp defl unemp imp exp ip {
    gen horizon_`v' = .
    gen b_`v' = .
    gen se_`v' = .
}
gen f_stat_eu = .

forvalues h = 0/8 {

    local hh = `h' + 1

    * TARIFF RATE (dynamic first stage)
    capture ivreg2 dtau_cum`h' ///
        i.cid L1_dtau L1_dgdp L1_ddefl ///
        (dtau = z) ///
        if eu_preww1 == 1, ///
        robust

    if _rc == 0 {
        replace horizon_tau = `h' in `hh'
        replace b_tau   = _b[dtau] in `hh'
        replace se_tau  = _se[dtau] in `hh'
        replace f_stat_eu = e(widstat) in `hh'
    }

    * REAL GDP
    capture ivreg2 dgdp`h' ///
        i.cid L1_dgdp L1_ddefl ///
        (dtau = z) ///
        if eu_preww1 == 1, ///
        robust

    if _rc == 0 {
        replace horizon_gdp = `h' in `hh'
        replace b_gdp   = _b[dtau] in `hh'
        replace se_gdp  = _se[dtau] in `hh'
    }

    * GDP DEFLATOR
    capture ivreg2 ddefl`h' ///
        i.cid L1_ddefl L1_dgdp ///
        (dtau = z) ///
        if eu_preww1 == 1, ///
        robust

    if _rc == 0 {
        replace horizon_defl = `h' in `hh'
        replace b_defl  = _b[dtau] in `hh'
        replace se_defl = _se[dtau] in `hh'
    }

    * UNEMPLOYMENT
    capture ivreg2 dunemp`h' ///
        i.cid L1_dunemp L1_dgdp L1_ddefl ///
        (dtau = z) ///
        if eu_preww1 == 1, ///
        robust

    if _rc == 0 {
        replace horizon_unemp = `h' in `hh'
        replace b_unemp  = _b[dtau] in `hh'
        replace se_unemp = _se[dtau] in `hh'
    }

    * REAL IMPORTS
    capture ivreg2 dimp`h' ///
        i.cid L1_dimp L1_dgdp L1_ddefl ///
        (dtau = z) ///
        if eu_preww1 == 1, ///
        robust

    if _rc == 0 {
        replace horizon_imp = `h' in `hh'
        replace b_imp   = _b[dtau] in `hh'
        replace se_imp  = _se[dtau] in `hh'
    }

    * REAL EXPORTS
    capture ivreg2 dexp`h' ///
        i.cid L1_dexp L1_dgdp L1_ddefl ///
        (dtau = z) ///
        if eu_preww1 == 1, ///
        robust

    if _rc == 0 {
        replace horizon_exp = `h' in `hh'
        replace b_exp   = _b[dtau] in `hh'
        replace se_exp  = _se[dtau] in `hh'
    }

    * INDUSTRIAL PRODUCTION
    capture ivreg2 dip`h' ///
        i.cid L1_dip L1_dgdp L1_ddefl ///
        (dtau = z) ///
        if eu_preww1 == 1, ///
        robust

    if _rc == 0 {
        replace horizon_ip = `h' in `hh'
        replace b_ip    = _b[dtau] in `hh'
        replace se_ip   = _se[dtau] in `hh'
    }
}

di _n "First-stage F-statistics (European pre-WWI pooled):"
list horizon_tau f_stat_eu if horizon_tau != ., noobs clean

* grab h=0 F-stat
local ef0 = f_stat_eu[1]
local ef0_str : di %4.2f `ef0'

* confidence intervals
foreach v in tau gdp defl unemp imp exp ip {
    gen up95_`v' = b_`v' + 1.96 * se_`v'
    gen lo95_`v' = b_`v' - 1.96 * se_`v'
    gen up90_`v' = b_`v' + 1.645 * se_`v'
    gen lo90_`v' = b_`v' - 1.645 * se_`v'
}

twoway ///
    (rarea up95_tau lo95_tau horizon_tau if horizon_tau <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_tau lo90_tau horizon_tau if horizon_tau <= 8, color(blue%40) lwidth(none)) ///
    (line b_tau horizon_tau if horizon_tau <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Tariff Rate — Europe Pre-WWI") ///
    subtitle("First-stage F = `ef0_str'") ///
    xtitle("Years") ytitle("ppt") ///
    legend(off)
graph export "intl_tariffs/graphs/lp_iv_fig4/pool_eu_preww1/irf_tau.png", replace

twoway ///
    (rarea up95_gdp lo95_gdp horizon_gdp if horizon_gdp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_gdp lo90_gdp horizon_gdp if horizon_gdp <= 8, color(blue%40) lwidth(none)) ///
    (line b_gdp horizon_gdp if horizon_gdp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real GDP — Europe Pre-WWI") ///
    subtitle("First-stage F = `ef0_str'") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/lp_iv_fig4/pool_eu_preww1/irf_gdp.png", replace

twoway ///
    (rarea up95_defl lo95_defl horizon_defl if horizon_defl <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_defl lo90_defl horizon_defl if horizon_defl <= 8, color(blue%40) lwidth(none)) ///
    (line b_defl horizon_defl if horizon_defl <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("GDP Deflator — Europe Pre-WWI") ///
    subtitle("First-stage F = `ef0_str'") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/lp_iv_fig4/pool_eu_preww1/irf_defl.png", replace

twoway ///
    (rarea up95_unemp lo95_unemp horizon_unemp if horizon_unemp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_unemp lo90_unemp horizon_unemp if horizon_unemp <= 8, color(blue%40) lwidth(none)) ///
    (line b_unemp horizon_unemp if horizon_unemp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Unemployment — Europe Pre-WWI") ///
    subtitle("First-stage F = `ef0_str'") ///
    xtitle("Years") ytitle("ppt") ///
    legend(off)
graph export "intl_tariffs/graphs/lp_iv_fig4/pool_eu_preww1/irf_unemp.png", replace

twoway ///
    (rarea up95_imp lo95_imp horizon_imp if horizon_imp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_imp lo90_imp horizon_imp if horizon_imp <= 8, color(blue%40) lwidth(none)) ///
    (line b_imp horizon_imp if horizon_imp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real Imports — Europe Pre-WWI") ///
    subtitle("First-stage F = `ef0_str'") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/lp_iv_fig4/pool_eu_preww1/irf_imp.png", replace

twoway ///
    (rarea up95_exp lo95_exp horizon_exp if horizon_exp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_exp lo90_exp horizon_exp if horizon_exp <= 8, color(blue%40) lwidth(none)) ///
    (line b_exp horizon_exp if horizon_exp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real Exports — Europe Pre-WWI") ///
    subtitle("First-stage F = `ef0_str'") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/lp_iv_fig4/pool_eu_preww1/irf_exp.png", replace

twoway ///
    (rarea up95_ip lo95_ip horizon_ip if horizon_ip <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_ip lo90_ip horizon_ip if horizon_ip <= 8, color(blue%40) lwidth(none)) ///
    (line b_ip horizon_ip if horizon_ip <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Industrial Production — Europe Pre-WWI") ///
    subtitle("First-stage F = `ef0_str'") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/lp_iv_fig4/pool_eu_preww1/irf_ip.png", replace

* clean up
foreach v in tau gdp defl unemp imp exp ip {
    drop horizon_`v' b_`v' se_`v' up95_`v' lo95_`v' up90_`v' lo90_`v'
}
drop f_stat_eu eu_preww1
