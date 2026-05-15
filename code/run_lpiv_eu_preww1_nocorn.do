
************************************************************
* LP-IV: EUROPEAN PRE-WWI
* Pooled + country-by-country
* Playing around with different shock dates based on what tau looks like
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

capture which ivreg2
if _rc ssc install ivreg2

capture which ranktest
if _rc ssc install ranktest

************************************************************
* NARRATIVE TARIFF SHOCK INSTRUMENTS
* Same as main file but excluding Corn Laws (GBR 1849)
* and DEU pre-1870 shocks
************************************************************

gen z = 0

* --- GBR ---
*replace z = z + -1 * (365-32)/365  if iso3 == "GBR" & year == 1849
*replace z = z + -1 * 32/365        if iso3 == "GBR" & year == 1850
replace z = z + -1 * (365-232)/365 if iso3 == "GBR" & year == 1853
replace z = z + -1 * 232/365       if iso3 == "GBR" & year == 1854
replace z = z + -1 * (366-183)/366 if iso3 == "GBR" & year == 1860
replace z = z + -1 * 183/366       if iso3 == "GBR" & year == 1861

* --- FRA ---
replace z = z + -1 * (366-205)/366 if iso3 == "FRA" & year == 1860
replace z = z + -1 * 205/366       if iso3 == "FRA" & year == 1861
replace z = z + (365-1)/365   if iso3 == "FRA" & year == 1872
replace z = z + (365-127)/365 if iso3 == "FRA" & year == 1881
replace z = z + 127/365       if iso3 == "FRA" & year == 1882
replace z = z + (365-1)/365   if iso3 == "FRA" & year == 1885
replace z = z + (366-11)/366  if iso3 == "FRA" & year == 1892
replace z = z + 11/366        if iso3 == "FRA" & year == 1893
replace z = z + (365-88)/365  if iso3 == "FRA" & year == 1910
replace z = z + 88/365        if iso3 == "FRA" & year == 1911

* --- DEU ---
* Playing around with different dates based on what tau looks like:
* 1853 Zollverein Reform: clear drop 11->9.4->7.6
* 1879 Bismarck Tariff: clear rise 2.8->3.4->5.8->6.1
* Dropping 1866 (deflator data volatile), 1873 (tiny tau move),
* 1903 Bulow (tau actually falls afterwards)
replace z = z + -1 * (365-1)/365   if iso3 == "DEU" & year == 1853
replace z = z + (365-192)/365 if iso3 == "DEU" & year == 1879
replace z = z + 192/365       if iso3 == "DEU" & year == 1880

* --- ITA ---
replace z = z + -1 * (366-1)/366   if iso3 == "ITA" & year == 1860

* --- NLD ---
replace z = z + (365-1)/365   if iso3 == "NLD" & year == 1925

* --- CHE ---
replace z = z + -1 * (366-1)/366   if iso3 == "CHE" & year == 1864
replace z = z + (365-1)/365   if iso3 == "CHE" & year == 1891

************************************************************
* CONSTRUCT VARIABLES
************************************************************

gen double lrgdp = log(rgdp)
gen double ldefl = log(gdp_deflator)

gen double rimp = imports / cpi_gmd
gen double rexp = exports / cpi_gmd
gen double lrimp = log(rimp)
gen double lrexp = log(rexp)
gen double lip = log(ind_prod)

gen dtau = D.tau_tamar

* cumulative responses
forvalues h = 0/8 {
    gen dtau_cum`h' = F`h'.tau_tamar - L1.tau_tamar
    gen dgdp`h' = 100 * (F`h'.lrgdp - L1.lrgdp)
    gen ddefl`h' = 100 * (F`h'.ldefl - L1.ldefl)
    gen dunemp`h' = F`h'.unemployment_rate_pct - L1.unemployment_rate_pct
    gen dimp`h' = 100 * (F`h'.lrimp - L1.lrimp)
    gen dexp`h' = 100 * (F`h'.lrexp - L1.lrexp)
    gen dip`h' = 100 * (F`h'.lip - L1.lip)
}

************************************************************
* CONTROLS
************************************************************

gen L1_dgdp = 100 * (lrgdp - L1.lrgdp)
gen L1_ddefl = 100 * (ldefl - L1.ldefl)
gen L1_dtau = L1.dtau
gen L1_dunemp = unemployment_rate_pct - L1.unemployment_rate_pct
gen L1_dimp = 100 * (lrimp - L1.lrimp)
gen L1_dexp = 100 * (lrexp - L1.lrexp)
gen L1_dip = 100 * (lip - L1.lip)

************************************************************
* OUTPUT DIRECTORIES
************************************************************

capture mkdir "intl_tariffs/graphs/eu_preww1_nocorn"
foreach cc in GBR FRA DEU ITA NLD BEL PRT CHE ESP {
    capture mkdir "intl_tariffs/graphs/eu_preww1_nocorn/`cc'"
}

************************************************************
* SAMPLE
************************************************************

gen byte eu_preww1 = inlist(iso3, "GBR", "FRA", "DEU", "ITA", "NLD", "BEL", "PRT", "CHE", "ESP") & year <= 1913

************************************************************
************************************************************
* POOLED EU PRE-WWI************************************************************
************************************************************

di _n "============================================================"
di "POOLED EU PRE-WWI LP-IV"
di "============================================================"

count if z != 0 & eu_preww1 == 1
di "Shocks in estimation sample: " r(N)

foreach v in tau gdp defl unemp imp exp ip {
    gen horizon_`v' = .
    gen b_`v' = .
    gen se_`v' = .
}

gen fstat = .

forvalues h = 0/8 {

    local hh = `h' + 1

    * TARIFF RATE (first stage)
    capture ivreg2 dtau_cum`h' ///
        i.cid L1_dtau L1_dgdp L1_ddefl ///
        (dtau = z) ///
        if eu_preww1 == 1, ///
        robust first

    if _rc == 0 {
        replace horizon_tau = `h' in `hh'
        replace b_tau   = _b[dtau] in `hh'
        replace se_tau  = _se[dtau] in `hh'
        replace fstat   = e(widstat) in `hh'
        di "h=`h': F-stat = " e(widstat) " | b_tau = " _b[dtau]
    }

    * REAL GDP
    capture ivreg2 dgdp`h' ///
        i.cid L1_dtau L1_dgdp L1_ddefl ///
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
        i.cid L1_dtau L1_dgdp L1_ddefl ///
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
        i.cid L1_dtau L1_dunemp L1_dgdp L1_ddefl ///
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
        i.cid L1_dtau L1_dimp L1_dgdp L1_ddefl ///
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
        i.cid L1_dtau L1_dexp L1_dgdp L1_ddefl ///
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
        i.cid L1_dtau L1_dip L1_dgdp L1_ddefl ///
        (dtau = z) ///
        if eu_preww1 == 1, ///
        robust

    if _rc == 0 {
        replace horizon_ip = `h' in `hh'
        replace b_ip    = _b[dtau] in `hh'
        replace se_ip   = _se[dtau] in `hh'
    }
}

************************************************************
* POOLED: CONFIDENCE INTERVALS AND PLOTS
************************************************************

foreach v in tau gdp defl unemp imp exp ip {
    gen up95_`v' = b_`v' + 1.96 * se_`v'
    gen lo95_`v' = b_`v' - 1.96 * se_`v'
    gen up90_`v' = b_`v' + 1.645 * se_`v'
    gen lo90_`v' = b_`v' - 1.645 * se_`v'
}

di _n "============================================================"
di "F-STATISTICS BY HORIZON"
di "============================================================"
list horizon_tau fstat if horizon_tau != . , noobs clean

twoway ///
    (rarea up95_tau lo95_tau horizon_tau if horizon_tau <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_tau lo90_tau horizon_tau if horizon_tau <= 8, color(blue%40) lwidth(none)) ///
    (line b_tau horizon_tau if horizon_tau <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Tariff Rate — EU Pre-WWI") ///
    xtitle("Years") ytitle("ppt per 1 ppt tariff hike") ///
    legend(off)
graph export "intl_tariffs/graphs/eu_preww1_nocorn/pool_tau.png", replace

twoway ///
    (rarea up95_gdp lo95_gdp horizon_gdp if horizon_gdp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_gdp lo90_gdp horizon_gdp if horizon_gdp <= 8, color(blue%40) lwidth(none)) ///
    (line b_gdp horizon_gdp if horizon_gdp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real GDP — EU Pre-WWI") ///
    xtitle("Years") ytitle("% per 1 ppt tariff hike") ///
    legend(off)
graph export "intl_tariffs/graphs/eu_preww1_nocorn/pool_gdp.png", replace

twoway ///
    (rarea up95_defl lo95_defl horizon_defl if horizon_defl <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_defl lo90_defl horizon_defl if horizon_defl <= 8, color(blue%40) lwidth(none)) ///
    (line b_defl horizon_defl if horizon_defl <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("GDP Deflator — EU Pre-WWI") ///
    xtitle("Years") ytitle("% per 1 ppt tariff hike") ///
    legend(off)
graph export "intl_tariffs/graphs/eu_preww1_nocorn/pool_defl.png", replace

twoway ///
    (rarea up95_unemp lo95_unemp horizon_unemp if horizon_unemp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_unemp lo90_unemp horizon_unemp if horizon_unemp <= 8, color(blue%40) lwidth(none)) ///
    (line b_unemp horizon_unemp if horizon_unemp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Unemployment — EU Pre-WWI") ///
    xtitle("Years") ytitle("ppt per 1 ppt tariff hike") ///
    legend(off)
graph export "intl_tariffs/graphs/eu_preww1_nocorn/pool_unemp.png", replace

twoway ///
    (rarea up95_imp lo95_imp horizon_imp if horizon_imp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_imp lo90_imp horizon_imp if horizon_imp <= 8, color(blue%40) lwidth(none)) ///
    (line b_imp horizon_imp if horizon_imp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real Imports — EU Pre-WWI") ///
    xtitle("Years") ytitle("% per 1 ppt tariff hike") ///
    legend(off)
graph export "intl_tariffs/graphs/eu_preww1_nocorn/pool_imp.png", replace

twoway ///
    (rarea up95_exp lo95_exp horizon_exp if horizon_exp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_exp lo90_exp horizon_exp if horizon_exp <= 8, color(blue%40) lwidth(none)) ///
    (line b_exp horizon_exp if horizon_exp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real Exports — EU Pre-WWI") ///
    xtitle("Years") ytitle("% per 1 ppt tariff hike") ///
    legend(off)
graph export "intl_tariffs/graphs/eu_preww1_nocorn/pool_exp.png", replace

twoway ///
    (rarea up95_ip lo95_ip horizon_ip if horizon_ip <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_ip lo90_ip horizon_ip if horizon_ip <= 8, color(blue%40) lwidth(none)) ///
    (line b_ip horizon_ip if horizon_ip <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Industrial Production — EU Pre-WWI") ///
    xtitle("Years") ytitle("% per 1 ppt tariff hike") ///
    legend(off)
graph export "intl_tariffs/graphs/eu_preww1_nocorn/pool_ip.png", replace

* clean up pooled storage
foreach v in tau gdp defl unemp imp exp ip {
    drop horizon_`v' b_`v' se_`v' up95_`v' lo95_`v' up90_`v' lo90_`v'
}
drop fstat

************************************************************
************************************************************
* COUNTRY-BY-COUNTRY EU PRE-WWI************************************************************
************************************************************

di _n _n "############################################################"
di "COUNTRY-BY-COUNTRY EU PRE-WWI"
di "############################################################"

local countries GBR FRA DEU ITA NLD CHE ESP

foreach cc of local countries {

    di _n "============================================================"
    di "COUNTRY: `cc' (pre-WWI)"
    di "============================================================"

    count if z != 0 & iso3 == "`cc'" & year <= 1913
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

        * TARIFF RATE (first stage)
        capture ivreg2 dtau_cum`h' ///
            L1_dtau L1_dgdp L1_ddefl ///
            (dtau = z) ///
            if iso3 == "`cc'" & year <= 1913, ///
            robust first

        if _rc == 0 {
            replace `hz' = `h' in `hh'
            replace `bt' = _b[dtau] in `hh'
            replace `set' = _se[dtau] in `hh'
            replace `fs' = e(widstat) in `hh'
        }

        * REAL GDP
        capture ivreg2 dgdp`h' ///
            L1_dtau L1_dgdp L1_ddefl ///
            (dtau = z) ///
            if iso3 == "`cc'" & year <= 1913, ///
            robust

        if _rc == 0 {
            replace `bg' = _b[dtau] in `hh'
            replace `seg' = _se[dtau] in `hh'
        }

        * GDP DEFLATOR
        capture ivreg2 ddefl`h' ///
            L1_dtau L1_dgdp L1_ddefl ///
            (dtau = z) ///
            if iso3 == "`cc'" & year <= 1913, ///
            robust

        if _rc == 0 {
            replace `bd' = _b[dtau] in `hh'
            replace `sed' = _se[dtau] in `hh'
        }

        * UNEMPLOYMENT
        capture ivreg2 dunemp`h' ///
            L1_dtau L1_dunemp L1_dgdp L1_ddefl ///
            (dtau = z) ///
            if iso3 == "`cc'" & year <= 1913, ///
            robust

        if _rc == 0 {
            replace `bu' = _b[dtau] in `hh'
            replace `seu' = _se[dtau] in `hh'
        }

        * REAL IMPORTS
        capture ivreg2 dimp`h' ///
            L1_dtau L1_dimp L1_dgdp L1_ddefl ///
            (dtau = z) ///
            if iso3 == "`cc'" & year <= 1913, ///
            robust

        if _rc == 0 {
            replace `bi' = _b[dtau] in `hh'
            replace `sei' = _se[dtau] in `hh'
        }

        * REAL EXPORTS
        capture ivreg2 dexp`h' ///
            L1_dtau L1_dexp L1_dgdp L1_ddefl ///
            (dtau = z) ///
            if iso3 == "`cc'" & year <= 1913, ///
            robust

        if _rc == 0 {
            replace `be' = _b[dtau] in `hh'
            replace `see' = _se[dtau] in `hh'
        }

        * INDUSTRIAL PRODUCTION
        capture ivreg2 dip`h' ///
            L1_dtau L1_dip L1_dgdp L1_ddefl ///
            (dtau = z) ///
            if iso3 == "`cc'" & year <= 1913, ///
            robust

        if _rc == 0 {
            replace `bp' = _b[dtau] in `hh'
            replace `sep' = _se[dtau] in `hh'
        }
    }

    * Print F-stats
    di _n "F-statistics:"
    list `hz' `fs' if `hz' != . , noobs clean

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
        title("Tariff Rate — `cc' Pre-WWI") ///
        xtitle("Years") ytitle("ppt") ///
        legend(off)
    graph export "intl_tariffs/graphs/eu_preww1_nocorn/`cc'/tau.png", replace

    twoway ///
        (rarea `u95g' `l95g' `hz' if `hz' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `u90g' `l90g' `hz' if `hz' <= 8, color(blue%40) lwidth(none)) ///
        (line `bg' `hz' if `hz' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("Real GDP — `cc' Pre-WWI") ///
        xtitle("Years") ytitle("%") ///
        legend(off)
    graph export "intl_tariffs/graphs/eu_preww1_nocorn/`cc'/gdp.png", replace

    twoway ///
        (rarea `u95d' `l95d' `hz' if `hz' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `u90d' `l90d' `hz' if `hz' <= 8, color(blue%40) lwidth(none)) ///
        (line `bd' `hz' if `hz' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("GDP Deflator — `cc' Pre-WWI") ///
        xtitle("Years") ytitle("%") ///
        legend(off)
    graph export "intl_tariffs/graphs/eu_preww1_nocorn/`cc'/defl.png", replace

    twoway ///
        (rarea `u95u' `l95u' `hz' if `hz' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `u90u' `l90u' `hz' if `hz' <= 8, color(blue%40) lwidth(none)) ///
        (line `bu' `hz' if `hz' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("Unemployment — `cc' Pre-WWI") ///
        xtitle("Years") ytitle("ppt") ///
        legend(off)
    graph export "intl_tariffs/graphs/eu_preww1_nocorn/`cc'/unemp.png", replace

    twoway ///
        (rarea `u95i' `l95i' `hz' if `hz' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `u90i' `l90i' `hz' if `hz' <= 8, color(blue%40) lwidth(none)) ///
        (line `bi' `hz' if `hz' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("Real Imports — `cc' Pre-WWI") ///
        xtitle("Years") ytitle("%") ///
        legend(off)
    graph export "intl_tariffs/graphs/eu_preww1_nocorn/`cc'/imp.png", replace

    twoway ///
        (rarea `u95e' `l95e' `hz' if `hz' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `u90e' `l90e' `hz' if `hz' <= 8, color(blue%40) lwidth(none)) ///
        (line `be' `hz' if `hz' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("Real Exports — `cc' Pre-WWI") ///
        xtitle("Years") ytitle("%") ///
        legend(off)
    graph export "intl_tariffs/graphs/eu_preww1_nocorn/`cc'/exp.png", replace

    twoway ///
        (rarea `u95p' `l95p' `hz' if `hz' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `u90p' `l90p' `hz' if `hz' <= 8, color(blue%40) lwidth(none)) ///
        (line `bp' `hz' if `hz' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("Industrial Production — `cc' Pre-WWI") ///
        xtitle("Years") ytitle("%") ///
        legend(off)
    graph export "intl_tariffs/graphs/eu_preww1_nocorn/`cc'/ip.png", replace

    * clean up
    drop `hz' `bt' `set' `bg' `seg' `bd' `sed' `bu' `seu' `bi' `sei' `be' `see' `bp' `sep' `fs'
    drop `u95t' `l95t' `u90t' `l90t' `u95g' `l95g' `u90g' `l90g' `u95d' `l95d' `u90d' `l90d'
    drop `u95u' `l95u' `u90u' `l90u' `u95i' `l95i' `u90i' `l90i' `u95e' `l95e' `u90e' `l90e' `u95p' `l95p' `u90p' `l90p'
}

di _n "============================================================"
di "DONE — EU Pre-WWI LP-IV"
di "============================================================"

************************************************************
************************************************************
* EU FULL SAMPLE (NO CORN LAWS, NO GERMANY, FRBSF FRENCH SHOCKS)
************************************************************
************************************************************

di _n _n "############################################################"
di "EU FULL — NO CORN, NO DEU, FRBSF FRENCH SHOCKS"
di "############################################################"

capture mkdir "intl_tariffs/graphs/eu_full_nocorn_nodeu"

************************************************************
* PERIOD DUMMIES
************************************************************

gen byte d_crimean = (year >= 1853 & year <= 1856)
gen byte d_franco_prussian = (year >= 1870 & year <= 1871)
gen byte d_ww1 = (year >= 1914 & year <= 1918)
gen byte d_great_depression = (year >= 1929 & year <= 1933)
gen byte d_ww2 = (year >= 1939 & year <= 1945)

************************************************************
* INSTRUMENT (clean: no Corn, no DEU, only FRBSF French shocks)
************************************************************

gen z3 = 0

* --- GBR (no Corn Laws) ---
* 1853 Gladstone Budget
replace z3 = z3 + -1 * (365-232)/365 if iso3 == "GBR" & year == 1853
replace z3 = z3 + -1 * 232/365       if iso3 == "GBR" & year == 1854
* 1860 Cobden-Chevalier
replace z3 = z3 + -1 * (366-183)/366 if iso3 == "GBR" & year == 1860
replace z3 = z3 + -1 * 183/366       if iso3 == "GBR" & year == 1861
* 1948 GATT Geneva
replace z3 = z3 + -1 * (366-1)/366   if iso3 == "GBR" & year == 1948
* 1968 GATT Kennedy
replace z3 = z3 + -1 * (366-1)/366   if iso3 == "GBR" & year == 1968
* 1973 EC Accession
replace z3 = z3 + -1 * (365-1)/365   if iso3 == "GBR" & year == 1973
* 1980 GATT Tokyo
replace z3 = z3 + -1 * (366-1)/366   if iso3 == "GBR" & year == 1980

* --- FRA (FRBSF 4 shocks only + post-WWI GATT) ---
* 1860 Cobden-Chevalier
replace z3 = z3 + -1 * (366-205)/366 if iso3 == "FRA" & year == 1860
replace z3 = z3 + -1 * 205/366       if iso3 == "FRA" & year == 1861
* 1872 Import Surtax
replace z3 = z3 + (365-1)/365   if iso3 == "FRA" & year == 1872
* 1885 Iron/Steel/Sugar
replace z3 = z3 + (365-1)/365   if iso3 == "FRA" & year == 1885
* 1892 Meline Tariff
replace z3 = z3 + (366-11)/366  if iso3 == "FRA" & year == 1892
replace z3 = z3 + 11/366        if iso3 == "FRA" & year == 1893
* 1948 GATT Geneva
replace z3 = z3 + -1 * (366-1)/366   if iso3 == "FRA" & year == 1948
* 1963 GATT Dillon
replace z3 = z3 + -1 * (365-1)/365   if iso3 == "FRA" & year == 1963
* 1968 GATT Kennedy
replace z3 = z3 + -1 * (366-1)/366   if iso3 == "FRA" & year == 1968
* 1980 GATT Tokyo
replace z3 = z3 + -1 * (366-1)/366   if iso3 == "FRA" & year == 1980

* --- ITA ---
* 1860 Unification
replace z3 = z3 + -1 * (366-1)/366   if iso3 == "ITA" & year == 1860
* 1963 GATT Dillon
replace z3 = z3 + -1 * (365-1)/365   if iso3 == "ITA" & year == 1963
* 1968 GATT Kennedy
replace z3 = z3 + -1 * (366-1)/366   if iso3 == "ITA" & year == 1968
* 1980 GATT Tokyo
replace z3 = z3 + -1 * (366-1)/366   if iso3 == "ITA" & year == 1980

* --- NLD ---
* 1925 Tariff Revision
replace z3 = z3 + (365-1)/365   if iso3 == "NLD" & year == 1925
* 1963 GATT Dillon
replace z3 = z3 + -1 * (365-1)/365   if iso3 == "NLD" & year == 1963
* 1968 GATT Kennedy
replace z3 = z3 + -1 * (366-1)/366   if iso3 == "NLD" & year == 1968
* 1980 GATT Tokyo
replace z3 = z3 + -1 * (366-1)/366   if iso3 == "NLD" & year == 1980

* --- BEL ---
* 1948 GATT Geneva
replace z3 = z3 + -1 * (366-1)/366   if iso3 == "BEL" & year == 1948
* 1968 GATT Kennedy
replace z3 = z3 + -1 * (366-1)/366   if iso3 == "BEL" & year == 1968
* 1980 GATT Tokyo
replace z3 = z3 + -1 * (366-1)/366   if iso3 == "BEL" & year == 1980

* --- PRT ---
* 1960 EFTA
replace z3 = z3 + -1 * (366-183)/366 if iso3 == "PRT" & year == 1960
replace z3 = z3 + -1 * 183/366       if iso3 == "PRT" & year == 1961
* 1963 GATT Dillon
replace z3 = z3 + -1 * (365-1)/365   if iso3 == "PRT" & year == 1963
* 1968 GATT Kennedy
replace z3 = z3 + -1 * (366-1)/366   if iso3 == "PRT" & year == 1968
* 1973 EC FTA
replace z3 = z3 + -1 * (365-1)/365   if iso3 == "PRT" & year == 1973

* --- CHE --- (excluded from this specification)
*replace z3 = z3 + -1 * (366-1)/366   if iso3 == "CHE" & year == 1864
*replace z3 = z3 + (365-1)/365   if iso3 == "CHE" & year == 1891
*replace z3 = z3 + -1 * (366-1)/366   if iso3 == "CHE" & year == 1968
*replace z3 = z3 + -1 * (365-1)/365   if iso3 == "CHE" & year == 1973
*replace z3 = z3 + -1 * (366-1)/366   if iso3 == "CHE" & year == 1980

* --- ESP ---
* 1963 GATT Dillon
replace z3 = z3 + -1 * (365-1)/365   if iso3 == "ESP" & year == 1963
* 1968 GATT Kennedy
replace z3 = z3 + -1 * (366-1)/366   if iso3 == "ESP" & year == 1968

************************************************************
* SAMPLE: EU excluding Germany
************************************************************

gen byte eu_nodeu = inlist(iso3, "GBR", "FRA", "ITA", "NLD", "BEL", "PRT", "ESP") & year <= 1970

count if z3 != 0 & eu_nodeu == 1
di "Total shocks (EU no DEU, no Corn, FRBSF French): " r(N)

************************************************************
* ESTIMATION
************************************************************

foreach v in tau gdp defl unemp imp exp ip {
    gen horizon3_`v' = .
    gen b3_`v' = .
    gen se3_`v' = .
}

gen fstat3 = .

forvalues h = 0/8 {

    local hh = `h' + 1

    * TARIFF RATE (first stage)
    capture ivreg2 dtau_cum`h' ///
        i.cid L1_dtau L1_dgdp L1_ddefl ///
        d_crimean d_franco_prussian d_ww1 d_great_depression d_ww2 ///
        (dtau = z3) ///
        if eu_nodeu == 1, ///
        robust first

    if _rc == 0 {
        replace horizon3_tau = `h' in `hh'
        replace b3_tau   = _b[dtau] in `hh'
        replace se3_tau  = _se[dtau] in `hh'
        replace fstat3   = e(widstat) in `hh'
        di "h=`h': F-stat = " e(widstat) " | b_tau = " _b[dtau]
    }

    * REAL GDP
    capture ivreg2 dgdp`h' ///
        i.cid L1_dtau L1_dgdp L1_ddefl ///
        d_crimean d_franco_prussian d_ww1 d_great_depression d_ww2 ///
        (dtau = z3) ///
        if eu_nodeu == 1, ///
        robust

    if _rc == 0 {
        replace horizon3_gdp = `h' in `hh'
        replace b3_gdp   = _b[dtau] in `hh'
        replace se3_gdp  = _se[dtau] in `hh'
    }

    * GDP DEFLATOR
    capture ivreg2 ddefl`h' ///
        i.cid L1_dtau L1_dgdp L1_ddefl ///
        d_crimean d_franco_prussian d_ww1 d_great_depression d_ww2 ///
        (dtau = z3) ///
        if eu_nodeu == 1, ///
        robust

    if _rc == 0 {
        replace horizon3_defl = `h' in `hh'
        replace b3_defl  = _b[dtau] in `hh'
        replace se3_defl = _se[dtau] in `hh'
    }

    * UNEMPLOYMENT
    capture ivreg2 dunemp`h' ///
        i.cid L1_dtau L1_dunemp L1_dgdp L1_ddefl ///
        d_crimean d_franco_prussian d_ww1 d_great_depression d_ww2 ///
        (dtau = z3) ///
        if eu_nodeu == 1, ///
        robust

    if _rc == 0 {
        replace horizon3_unemp = `h' in `hh'
        replace b3_unemp  = _b[dtau] in `hh'
        replace se3_unemp = _se[dtau] in `hh'
    }

    * REAL IMPORTS
    capture ivreg2 dimp`h' ///
        i.cid L1_dtau L1_dimp L1_dgdp L1_ddefl ///
        d_crimean d_franco_prussian d_ww1 d_great_depression d_ww2 ///
        (dtau = z3) ///
        if eu_nodeu == 1, ///
        robust

    if _rc == 0 {
        replace horizon3_imp = `h' in `hh'
        replace b3_imp   = _b[dtau] in `hh'
        replace se3_imp  = _se[dtau] in `hh'
    }

    * REAL EXPORTS
    capture ivreg2 dexp`h' ///
        i.cid L1_dtau L1_dexp L1_dgdp L1_ddefl ///
        d_crimean d_franco_prussian d_ww1 d_great_depression d_ww2 ///
        (dtau = z3) ///
        if eu_nodeu == 1, ///
        robust

    if _rc == 0 {
        replace horizon3_exp = `h' in `hh'
        replace b3_exp   = _b[dtau] in `hh'
        replace se3_exp  = _se[dtau] in `hh'
    }

    * INDUSTRIAL PRODUCTION
    capture ivreg2 dip`h' ///
        i.cid L1_dtau L1_dip L1_dgdp L1_ddefl ///
        d_crimean d_franco_prussian d_ww1 d_great_depression d_ww2 ///
        (dtau = z3) ///
        if eu_nodeu == 1, ///
        robust

    if _rc == 0 {
        replace horizon3_ip = `h' in `hh'
        replace b3_ip    = _b[dtau] in `hh'
        replace se3_ip   = _se[dtau] in `hh'
    }
}

************************************************************
* EU NO CORN/NO DEU: CONFIDENCE INTERVALS AND PLOTS
************************************************************

foreach v in tau gdp defl unemp imp exp ip {
    gen up95_3`v' = b3_`v' + 1.96 * se3_`v'
    gen lo95_3`v' = b3_`v' - 1.96 * se3_`v'
    gen up90_3`v' = b3_`v' + 1.645 * se3_`v'
    gen lo90_3`v' = b3_`v' - 1.645 * se3_`v'
}

di _n "============================================================"
di "EU NO CORN/NO DEU F-STATISTICS BY HORIZON"
di "============================================================"
list horizon3_tau fstat3 if horizon3_tau != . , noobs clean

twoway ///
    (rarea up95_3tau lo95_3tau horizon3_tau if horizon3_tau <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_3tau lo90_3tau horizon3_tau if horizon3_tau <= 8, color(blue%40) lwidth(none)) ///
    (line b3_tau horizon3_tau if horizon3_tau <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Tariff Rate — EU Pre-1970 (No Corn, No DEU)") ///
    xtitle("Years") ytitle("ppt per 1 ppt tariff hike") ///
    legend(off)
graph export "intl_tariffs/graphs/eu_full_nocorn_nodeu/tau.png", replace

twoway ///
    (rarea up95_3gdp lo95_3gdp horizon3_gdp if horizon3_gdp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_3gdp lo90_3gdp horizon3_gdp if horizon3_gdp <= 8, color(blue%40) lwidth(none)) ///
    (line b3_gdp horizon3_gdp if horizon3_gdp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real GDP — EU Pre-1970 (No Corn, No DEU)") ///
    xtitle("Years") ytitle("% per 1 ppt tariff hike") ///
    legend(off)
graph export "intl_tariffs/graphs/eu_full_nocorn_nodeu/gdp.png", replace

twoway ///
    (rarea up95_3defl lo95_3defl horizon3_defl if horizon3_defl <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_3defl lo90_3defl horizon3_defl if horizon3_defl <= 8, color(blue%40) lwidth(none)) ///
    (line b3_defl horizon3_defl if horizon3_defl <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("GDP Deflator — EU Pre-1970 (No Corn, No DEU)") ///
    xtitle("Years") ytitle("% per 1 ppt tariff hike") ///
    legend(off)
graph export "intl_tariffs/graphs/eu_full_nocorn_nodeu/defl.png", replace

twoway ///
    (rarea up95_3unemp lo95_3unemp horizon3_unemp if horizon3_unemp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_3unemp lo90_3unemp horizon3_unemp if horizon3_unemp <= 8, color(blue%40) lwidth(none)) ///
    (line b3_unemp horizon3_unemp if horizon3_unemp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Unemployment — EU Pre-1970 (No Corn, No DEU)") ///
    xtitle("Years") ytitle("ppt per 1 ppt tariff hike") ///
    legend(off)
graph export "intl_tariffs/graphs/eu_full_nocorn_nodeu/unemp.png", replace

twoway ///
    (rarea up95_3imp lo95_3imp horizon3_imp if horizon3_imp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_3imp lo90_3imp horizon3_imp if horizon3_imp <= 8, color(blue%40) lwidth(none)) ///
    (line b3_imp horizon3_imp if horizon3_imp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real Imports — EU Pre-1970 (No Corn, No DEU)") ///
    xtitle("Years") ytitle("% per 1 ppt tariff hike") ///
    legend(off)
graph export "intl_tariffs/graphs/eu_full_nocorn_nodeu/imp.png", replace

twoway ///
    (rarea up95_3exp lo95_3exp horizon3_exp if horizon3_exp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_3exp lo90_3exp horizon3_exp if horizon3_exp <= 8, color(blue%40) lwidth(none)) ///
    (line b3_exp horizon3_exp if horizon3_exp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real Exports — EU Pre-1970 (No Corn, No DEU)") ///
    xtitle("Years") ytitle("% per 1 ppt tariff hike") ///
    legend(off)
graph export "intl_tariffs/graphs/eu_full_nocorn_nodeu/exp.png", replace

twoway ///
    (rarea up95_3ip lo95_3ip horizon3_ip if horizon3_ip <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_3ip lo90_3ip horizon3_ip if horizon3_ip <= 8, color(blue%40) lwidth(none)) ///
    (line b3_ip horizon3_ip if horizon3_ip <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Industrial Production — EU Pre-1970 (No Corn, No DEU)") ///
    xtitle("Years") ytitle("% per 1 ppt tariff hike") ///
    legend(off)
graph export "intl_tariffs/graphs/eu_full_nocorn_nodeu/ip.png", replace

di _n "============================================================"
di "DONE — EU Full (No Corn, No DEU, FRBSF French shocks)"
di "============================================================"
