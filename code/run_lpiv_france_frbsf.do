
************************************************************
* LP-IV FOR FRANCE — REPLICATING BARNICHON & SINGH (2025)
* 4 narrative shocks, 1850–1913 sample
* Shocks: 1860 Cobden-Chevalier (cut), 1872 Import Surtax (hike),
*         1885 Iron/Steel/Sugar tariff (hike), 1892 Meline (hike)
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
* KEEP FRANCE ONLY, PRE-WWI
************************************************************

keep if iso3 == "FRA"
keep if year >= 1850 & year <= 1913

************************************************************
* NARRATIVE TARIFF SHOCK INSTRUMENTS (4 shocks)
************************************************************

gen z = 0

* 1860: Cobden-Chevalier Treaty (cut) — signed July 23 1860
replace z = -1 * (366-205)/366 if year == 1860
replace z = -1 * 205/366       if year == 1861

* 1872: Import Surtax (hike) — revenue for war reparations
* Assume Jan 1 implementation (start of year)
replace z = (365-1)/365 if year == 1872

* 1885: Tariff on Iron, Steel, Sugar (hike)
* Assume Jan 1 implementation
replace z = (365-1)/365 if year == 1885

* 1892: Meline Tariff (hike) — Jan 11 1892
replace z = (366-11)/366 if year == 1892
replace z = 11/366       if year == 1893

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

* first-stage: change in tariff rate
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
* CONTROLS (2 lags of each, matching VAR(2) structure)
************************************************************

gen L1_dgdp = 100 * (lrgdp - L1.lrgdp)
gen L2_dgdp = 100 * (L1.lrgdp - L2.lrgdp)
gen L1_ddefl = 100 * (ldefl - L1.ldefl)
gen L2_ddefl = 100 * (L1.ldefl - L2.ldefl)
gen L1_dtau = L1.dtau
gen L2_dtau = L2.dtau
gen L1_dunemp = unemployment_rate_pct - L1.unemployment_rate_pct
gen L2_dunemp = L1.unemployment_rate_pct - L2.unemployment_rate_pct
gen L1_dimp = 100 * (lrimp - L1.lrimp)
gen L2_dimp = 100 * (L1.lrimp - L2.lrimp)
gen L1_dexp = 100 * (lrexp - L1.lrexp)
gen L2_dexp = 100 * (L1.lrexp - L2.lrexp)
gen L1_dip = 100 * (lip - L1.lip)
gen L2_dip = 100 * (L1.lip - L2.lip)

************************************************************
* OUTPUT DIRECTORY
************************************************************

capture mkdir "intl_tariffs/graphs/france_frbsf"

************************************************************
* SAMPLE DIAGNOSTICS
************************************************************

di _n "============================================================"
di "FRANCE LP-IV — BARNICHON & SINGH (2025) SHOCKS"
di "Sample: 1850-1913"
di "============================================================"

count if z != 0
di "Shocks in estimation sample: " r(N)
tab year if z != 0

************************************************************
* LP-IV ESTIMATION
************************************************************

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
        L1_dtau L2_dtau L1_dgdp L2_dgdp L1_ddefl L2_ddefl ///
        (dtau = z), ///
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
        L1_dtau L2_dtau L1_dgdp L2_dgdp L1_ddefl L2_ddefl ///
        (dtau = z), ///
        robust

    if _rc == 0 {
        replace horizon_gdp = `h' in `hh'
        replace b_gdp   = _b[dtau] in `hh'
        replace se_gdp  = _se[dtau] in `hh'
    }

    * GDP DEFLATOR
    capture ivreg2 ddefl`h' ///
        L1_dtau L2_dtau L1_dgdp L2_dgdp L1_ddefl L2_ddefl ///
        (dtau = z), ///
        robust

    if _rc == 0 {
        replace horizon_defl = `h' in `hh'
        replace b_defl  = _b[dtau] in `hh'
        replace se_defl = _se[dtau] in `hh'
    }

    * UNEMPLOYMENT
    capture ivreg2 dunemp`h' ///
        L1_dtau L2_dtau L1_dunemp L2_dunemp L1_dgdp L2_dgdp L1_ddefl L2_ddefl ///
        (dtau = z), ///
        robust

    if _rc == 0 {
        replace horizon_unemp = `h' in `hh'
        replace b_unemp  = _b[dtau] in `hh'
        replace se_unemp = _se[dtau] in `hh'
    }

    * REAL IMPORTS
    capture ivreg2 dimp`h' ///
        L1_dtau L2_dtau L1_dimp L2_dimp L1_dgdp L2_dgdp L1_ddefl L2_ddefl ///
        (dtau = z), ///
        robust

    if _rc == 0 {
        replace horizon_imp = `h' in `hh'
        replace b_imp   = _b[dtau] in `hh'
        replace se_imp  = _se[dtau] in `hh'
    }

    * REAL EXPORTS
    capture ivreg2 dexp`h' ///
        L1_dtau L2_dtau L1_dexp L2_dexp L1_dgdp L2_dgdp L1_ddefl L2_ddefl ///
        (dtau = z), ///
        robust

    if _rc == 0 {
        replace horizon_exp = `h' in `hh'
        replace b_exp   = _b[dtau] in `hh'
        replace se_exp  = _se[dtau] in `hh'
    }

    * INDUSTRIAL PRODUCTION
    capture ivreg2 dip`h' ///
        L1_dtau L2_dtau L1_dip L2_dip L1_dgdp L2_dgdp L1_ddefl L2_ddefl ///
        (dtau = z), ///
        robust

    if _rc == 0 {
        replace horizon_ip = `h' in `hh'
        replace b_ip    = _b[dtau] in `hh'
        replace se_ip   = _se[dtau] in `hh'
    }
}

************************************************************
* CONFIDENCE INTERVALS AND PLOTS
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
    title("Tariff Rate — France 1850-1913 (FRBSF shocks)") ///
    xtitle("Years") ytitle("ppt per 1 ppt tariff hike") ///
    legend(off)
graph export "intl_tariffs/graphs/france_frbsf/tau.png", replace

* Individual graphs saved to memory for combining
twoway ///
    (rarea up95_gdp lo95_gdp horizon_gdp if horizon_gdp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_gdp lo90_gdp horizon_gdp if horizon_gdp <= 8, color(blue%40) lwidth(none)) ///
    (line b_gdp horizon_gdp if horizon_gdp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real GDP", size(medium)) ///
    xtitle("Years") ytitle("% per 1 ppt tariff hike") ///
    legend(off) name(g_gdp, replace)

twoway ///
    (rarea up95_defl lo95_defl horizon_defl if horizon_defl <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_defl lo90_defl horizon_defl if horizon_defl <= 8, color(blue%40) lwidth(none)) ///
    (line b_defl horizon_defl if horizon_defl <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("GDP Deflator", size(medium)) ///
    xtitle("Years") ytitle("% per 1 ppt tariff hike") ///
    legend(off) name(g_defl, replace)

twoway ///
    (rarea up95_unemp lo95_unemp horizon_unemp if horizon_unemp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_unemp lo90_unemp horizon_unemp if horizon_unemp <= 8, color(blue%40) lwidth(none)) ///
    (line b_unemp horizon_unemp if horizon_unemp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Unemployment", size(medium)) ///
    xtitle("Years") ytitle("ppt per 1 ppt tariff hike") ///
    legend(off) name(g_unemp, replace)

twoway ///
    (rarea up95_imp lo95_imp horizon_imp if horizon_imp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_imp lo90_imp horizon_imp if horizon_imp <= 8, color(blue%40) lwidth(none)) ///
    (line b_imp horizon_imp if horizon_imp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real Imports", size(medium)) ///
    xtitle("Years") ytitle("% per 1 ppt tariff hike") ///
    legend(off) name(g_imp, replace)

twoway ///
    (rarea up95_exp lo95_exp horizon_exp if horizon_exp <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_exp lo90_exp horizon_exp if horizon_exp <= 8, color(blue%40) lwidth(none)) ///
    (line b_exp horizon_exp if horizon_exp <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real Exports", size(medium)) ///
    xtitle("Years") ytitle("% per 1 ppt tariff hike") ///
    legend(off) name(g_exp, replace)

twoway ///
    (rarea up95_ip lo95_ip horizon_ip if horizon_ip <= 8, color(blue%20) lwidth(none)) ///
    (rarea up90_ip lo90_ip horizon_ip if horizon_ip <= 8, color(blue%40) lwidth(none)) ///
    (line b_ip horizon_ip if horizon_ip <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Industrial Production", size(medium)) ///
    xtitle("Years") ytitle("% per 1 ppt tariff hike") ///
    legend(off) name(g_ip, replace)

* Page 1: GDP, deflator, unemployment, imports (2x2)
graph combine g_gdp g_defl g_unemp g_imp, ///
    cols(2) title("France 1850-1913 (FRBSF shocks) — Page 1", size(medium)) ///
    xsize(10) ysize(7)
graph export "intl_tariffs/graphs/france_frbsf/combined_p1.png", replace

* Page 2: exports, IP (1x2)
graph combine g_exp g_ip, ///
    cols(2) title("France 1850-1913 (FRBSF shocks) — Page 2", size(medium)) ///
    xsize(10) ysize(5)
graph export "intl_tariffs/graphs/france_frbsf/combined_p2.png", replace

graph drop g_gdp g_defl g_unemp g_imp g_exp g_ip

di _n "============================================================"
di "DONE — France LP-IV with Barnichon & Singh (2025) shocks"
di "============================================================"
