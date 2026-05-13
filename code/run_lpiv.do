
************************************************************
* PANEL LP-IV: INTERNATIONAL TARIFF SHOCKS
* Specification follows equation (8) from Den Besten et al.:
*   y_{i,t+h} - y_{i,t-1} = alpha_i + theta*dtau_it + controls + e
*   instrument: z_it (narrative shock) for dtau_it
************************************************************

clear all
set more off

************************************************************
* LOAD PANEL
************************************************************

import delimited "intl_tariffs/data/panel.csv", clear

* encode country for panel setup
encode iso3, gen(cid)

* fill gaps so xt operators work
xtset cid year
tsfill

* re-fill iso3 after tsfill (it becomes missing for filled obs)
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
* Direction: -1 = liberalization, +1 = protection
************************************************************

gen z = 0

* --- GBR ---
replace z = -1 if iso3 == "GBR" & year == 1853
replace z = -1 if iso3 == "GBR" & year == 1860
replace z = -1 if iso3 == "GBR" & year == 1948
replace z = -1 if iso3 == "GBR" & year == 1960
replace z = -1 if iso3 == "GBR" & year == 1968
replace z = -1 if iso3 == "GBR" & year == 1973
replace z = -1 if iso3 == "GBR" & year == 1979
replace z = -1 if iso3 == "GBR" & year == 1995

* --- FRA ---
replace z = -1 if iso3 == "FRA" & year == 1860
replace z = +1 if iso3 == "FRA" & year == 1872
replace z = +1 if iso3 == "FRA" & year == 1881
replace z = +1 if iso3 == "FRA" & year == 1910
replace z = -1 if iso3 == "FRA" & year == 1948
replace z = -1 if iso3 == "FRA" & year == 1958
replace z = -1 if iso3 == "FRA" & year == 1968
replace z = -1 if iso3 == "FRA" & year == 1979
replace z = -1 if iso3 == "FRA" & year == 1995

* --- DEU ---
replace z = -1 if iso3 == "DEU" & year == 1853
replace z = -1 if iso3 == "DEU" & year == 1862
replace z = -1 if iso3 == "DEU" & year == 1873
replace z = +1 if iso3 == "DEU" & year == 1892
replace z = -1 if iso3 == "DEU" & year == 1951
replace z = -1 if iso3 == "DEU" & year == 1958
replace z = -1 if iso3 == "DEU" & year == 1968
replace z = -1 if iso3 == "DEU" & year == 1979
replace z = -1 if iso3 == "DEU" & year == 1995

* --- ITA ---
replace z = -1 if iso3 == "ITA" & year == 1861
replace z = -1 if iso3 == "ITA" & year == 1863
replace z = -1 if iso3 == "ITA" & year == 1950
replace z = -1 if iso3 == "ITA" & year == 1958
replace z = -1 if iso3 == "ITA" & year == 1968
replace z = -1 if iso3 == "ITA" & year == 1979
replace z = -1 if iso3 == "ITA" & year == 1995

* --- NLD ---
replace z = -1 if iso3 == "NLD" & year == 1862
replace z = +1 if iso3 == "NLD" & year == 1924
replace z = -1 if iso3 == "NLD" & year == 1948
replace z = -1 if iso3 == "NLD" & year == 1958
replace z = -1 if iso3 == "NLD" & year == 1968
replace z = -1 if iso3 == "NLD" & year == 1979
replace z = -1 if iso3 == "NLD" & year == 1995

* --- BEL ---
replace z = -1 if iso3 == "BEL" & year == 1921
replace z = -1 if iso3 == "BEL" & year == 1948
replace z = -1 if iso3 == "BEL" & year == 1958
replace z = -1 if iso3 == "BEL" & year == 1968
replace z = -1 if iso3 == "BEL" & year == 1979
replace z = -1 if iso3 == "BEL" & year == 1995

* --- PRT ---
replace z = -1 if iso3 == "PRT" & year == 1960
replace z = -1 if iso3 == "PRT" & year == 1962
replace z = -1 if iso3 == "PRT" & year == 1972
replace z = -1 if iso3 == "PRT" & year == 1986
replace z = -1 if iso3 == "PRT" & year == 1995

* --- CHE ---
replace z = -1 if iso3 == "CHE" & year == 1864
replace z = -1 if iso3 == "CHE" & year == 1960
replace z = -1 if iso3 == "CHE" & year == 1966
replace z = -1 if iso3 == "CHE" & year == 1972
replace z = -1 if iso3 == "CHE" & year == 1995

* --- ESP ---
replace z = -1 if iso3 == "ESP" & year == 1869
replace z = -1 if iso3 == "ESP" & year == 1963
replace z = -1 if iso3 == "ESP" & year == 1970
replace z = -1 if iso3 == "ESP" & year == 1986
replace z = -1 if iso3 == "ESP" & year == 1995

* --- JPN ---
replace z = +1 if iso3 == "JPN" & year == 1899
replace z = +1 if iso3 == "JPN" & year == 1911
replace z = -1 if iso3 == "JPN" & year == 1955
replace z = -1 if iso3 == "JPN" & year == 1961
replace z = -1 if iso3 == "JPN" & year == 1968
replace z = -1 if iso3 == "JPN" & year == 1979
replace z = -1 if iso3 == "JPN" & year == 1995

* --- ARG ---
replace z = -1 if iso3 == "ARG" & year == 1967
replace z = -1 if iso3 == "ARG" & year == 1991
replace z = -1 if iso3 == "ARG" & year == 1995

* --- BRA ---
replace z = -1 if iso3 == "BRA" & year == 1948
replace z = -1 if iso3 == "BRA" & year == 1991
replace z = -1 if iso3 == "BRA" & year == 1995

* --- MEX ---
replace z = -1 if iso3 == "MEX" & year == 1986
replace z = -1 if iso3 == "MEX" & year == 1994
replace z = -1 if iso3 == "MEX" & year == 1995

************************************************************
* LOG SERIES AND CUMULATIVE RESPONSES
************************************************************

gen double lrgdp = log(rgdp)
gen double ldefl = log(gdp_deflator)

* change in tariff rate (endogenous variable)
gen dtau = D.tau_tamar

* cumulative responses: y_{t+h} - y_{t-1}
forvalues h = 0/8 {
    gen dgdp`h'   = 100 * (F`h'.lrgdp - L1.lrgdp)
    gen ddefl`h'  = 100 * (F`h'.ldefl - L1.ldefl)
    gen dunemp`h' = F`h'.unemployment_rate_pct - L1.unemployment_rate_pct
}

************************************************************
* CONTROLS
************************************************************

gen infl = D.ldefl
gen L1_infl = L1.infl
gen L2_infl = L2.infl
gen L1_dunemp = L1.unemployment_rate_pct - L2.unemployment_rate_pct
gen L2_dunemp = L2.unemployment_rate_pct - L3.unemployment_rate_pct
gen L1_dtau = L1.dtau
gen L2_dtau = L2.dtau

************************************************************
* SAMPLE INDICATORS
************************************************************

gen byte european = inlist(iso3, "GBR", "FRA", "DEU", "ITA", "NLD", "BEL", "PRT", "CHE", "ESP")
gen byte preww1 = (year <= 1913)
gen byte sample_eu_pre = (european == 1 & preww1 == 1)

* full sample excludes ARG (tau_mitchell only 1910-1944, too sparse)
gen byte sample_full = (iso3 != "ARG")

************************************************************
************************************************************
* SPECIFICATION 1: EUROPEAN COUNTRIES, PRE-WWI
************************************************************
************************************************************

di _n "============================================================"
di "SPEC 1: EUROPEAN COUNTRIES, PRE-WWI (year <= 1913)"
di "============================================================"

* count shocks in sample
count if z != 0 & sample_eu_pre == 1 & !missing(z)
di "Number of narrative shocks in sample: " r(N)
tab iso3 if z != 0 & sample_eu_pre == 1, sort

* storage
gen horizon1 = .
gen b_gdp1 = .
gen se_gdp1 = .
gen b_defl1 = .
gen se_defl1 = .
gen b_unemp1 = .
gen se_unemp1 = .
gen f_stat1 = .

forvalues h = 0/8 {

    local hh = `h' + 1

    * GDP
    ivreg2 dgdp`h' ///
        i.cid L1_dtau L2_dtau L1_infl L2_infl ///
        L1_dunemp L2_dunemp ///
        (dtau = z) ///
        if sample_eu_pre == 1, ///
        robust

    replace horizon1 = `h' in `hh'
    replace b_gdp1   = _b[dtau] in `hh'
    replace se_gdp1  = _se[dtau] in `hh'
    replace f_stat1  = e(widstat) in `hh'

    * GDP DEFLATOR
    ivreg2 ddefl`h' ///
        i.cid L1_dtau L2_dtau L1_infl L2_infl ///
        L1_dunemp L2_dunemp ///
        (dtau = z) ///
        if sample_eu_pre == 1, ///
        robust

    replace b_defl1  = _b[dtau] in `hh'
    replace se_defl1 = _se[dtau] in `hh'

    * UNEMPLOYMENT
    ivreg2 dunemp`h' ///
        i.cid L1_dtau L2_dtau L1_infl L2_infl ///
        L1_dunemp L2_dunemp ///
        (dtau = z) ///
        if sample_eu_pre == 1, ///
        robust

    replace b_unemp1  = _b[dtau] in `hh'
    replace se_unemp1 = _se[dtau] in `hh'
}

di _n "First-stage F-statistics (European pre-WWI):"
list horizon1 f_stat1 if horizon1 != ., noobs clean

************************************************************
* SPEC 1: CONFIDENCE INTERVALS AND PLOTS
************************************************************

foreach var in gdp defl unemp {
    gen upper95_`var'1 = b_`var'1 + 1.96 * se_`var'1
    gen lower95_`var'1 = b_`var'1 - 1.96 * se_`var'1
    gen upper90_`var'1 = b_`var'1 + 1.645 * se_`var'1
    gen lower90_`var'1 = b_`var'1 - 1.645 * se_`var'1
}

twoway ///
    (rarea upper95_gdp1 lower95_gdp1 horizon1 if horizon1 <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_gdp1 lower90_gdp1 horizon1 if horizon1 <= 8, color(blue%40) lwidth(none)) ///
    (line b_gdp1 horizon1 if horizon1 <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real GDP — European Panel, Pre-WWI") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/panel_irf_gdp_eu_preww1.png", replace

twoway ///
    (rarea upper95_defl1 lower95_defl1 horizon1 if horizon1 <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_defl1 lower90_defl1 horizon1 if horizon1 <= 8, color(blue%40) lwidth(none)) ///
    (line b_defl1 horizon1 if horizon1 <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("GDP Deflator — European Panel, Pre-WWI") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/panel_irf_defl_eu_preww1.png", replace

twoway ///
    (rarea upper95_unemp1 lower95_unemp1 horizon1 if horizon1 <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_unemp1 lower90_unemp1 horizon1 if horizon1 <= 8, color(blue%40) lwidth(none)) ///
    (line b_unemp1 horizon1 if horizon1 <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Unemployment — European Panel, Pre-WWI") ///
    xtitle("Years") ytitle("ppt") ///
    legend(off)
graph export "intl_tariffs/graphs/panel_irf_unemp_eu_preww1.png", replace

************************************************************
************************************************************
* SPECIFICATION 2: FULL SAMPLE (ALL COUNTRIES, ALL YEARS)
* Excludes ARG (too little tau_mitchell coverage)
************************************************************
************************************************************

di _n "============================================================"
di "SPEC 2: FULL SAMPLE (excl. ARG)"
di "============================================================"

count if z != 0 & sample_full == 1 & !missing(z)
di "Number of narrative shocks in sample: " r(N)
tab iso3 if z != 0 & sample_full == 1, sort

* storage
gen horizon2 = .
gen b_gdp2 = .
gen se_gdp2 = .
gen b_defl2 = .
gen se_defl2 = .
gen b_unemp2 = .
gen se_unemp2 = .
gen f_stat2 = .

forvalues h = 0/8 {

    local hh = `h' + 1

    * GDP
    ivreg2 dgdp`h' ///
        i.cid L1_dtau L2_dtau L1_infl L2_infl ///
        L1_dunemp L2_dunemp ///
        (dtau = z) ///
        if sample_full == 1, ///
        robust

    replace horizon2 = `h' in `hh'
    replace b_gdp2   = _b[dtau] in `hh'
    replace se_gdp2  = _se[dtau] in `hh'
    replace f_stat2  = e(widstat) in `hh'

    * GDP DEFLATOR
    ivreg2 ddefl`h' ///
        i.cid L1_dtau L2_dtau L1_infl L2_infl ///
        L1_dunemp L2_dunemp ///
        (dtau = z) ///
        if sample_full == 1, ///
        robust

    replace b_defl2  = _b[dtau] in `hh'
    replace se_defl2 = _se[dtau] in `hh'

    * UNEMPLOYMENT
    ivreg2 dunemp`h' ///
        i.cid L1_dtau L2_dtau L1_infl L2_infl ///
        L1_dunemp L2_dunemp ///
        (dtau = z) ///
        if sample_full == 1, ///
        robust

    replace b_unemp2  = _b[dtau] in `hh'
    replace se_unemp2 = _se[dtau] in `hh'
}

di _n "First-stage F-statistics (Full sample):"
list horizon2 f_stat2 if horizon2 != ., noobs clean

************************************************************
* SPEC 2: CONFIDENCE INTERVALS AND PLOTS
************************************************************

foreach var in gdp defl unemp {
    gen upper95_`var'2 = b_`var'2 + 1.96 * se_`var'2
    gen lower95_`var'2 = b_`var'2 - 1.96 * se_`var'2
    gen upper90_`var'2 = b_`var'2 + 1.645 * se_`var'2
    gen lower90_`var'2 = b_`var'2 - 1.645 * se_`var'2
}

twoway ///
    (rarea upper95_gdp2 lower95_gdp2 horizon2 if horizon2 <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_gdp2 lower90_gdp2 horizon2 if horizon2 <= 8, color(blue%40) lwidth(none)) ///
    (line b_gdp2 horizon2 if horizon2 <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real GDP — Full Panel") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/panel_irf_gdp_full.png", replace

twoway ///
    (rarea upper95_defl2 lower95_defl2 horizon2 if horizon2 <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_defl2 lower90_defl2 horizon2 if horizon2 <= 8, color(blue%40) lwidth(none)) ///
    (line b_defl2 horizon2 if horizon2 <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("GDP Deflator — Full Panel") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/panel_irf_defl_full.png", replace

twoway ///
    (rarea upper95_unemp2 lower95_unemp2 horizon2 if horizon2 <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_unemp2 lower90_unemp2 horizon2 if horizon2 <= 8, color(blue%40) lwidth(none)) ///
    (line b_unemp2 horizon2 if horizon2 <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Unemployment — Full Panel") ///
    xtitle("Years") ytitle("ppt") ///
    legend(off)
graph export "intl_tariffs/graphs/panel_irf_unemp_full.png", replace

************************************************************
************************************************************
* SPECIFICATION 3: EUROPEAN PRE-WWI WITH COUNTRY + YEAR FE
* Year FE defensible here because shocks have differential
* timing (only 1853, 1860 hit two countries simultaneously)
************************************************************
************************************************************

di _n "============================================================"
di "SPEC 3: EUROPEAN PRE-WWI, COUNTRY + YEAR FE"
di "============================================================"

count if z != 0 & sample_eu_pre == 1 & !missing(z)
di "Number of narrative shocks in sample: " r(N)

* storage
gen horizon3 = .
gen b_gdp3 = .
gen se_gdp3 = .
gen b_defl3 = .
gen se_defl3 = .
gen b_unemp3 = .
gen se_unemp3 = .
gen f_stat3 = .

forvalues h = 0/8 {

    local hh = `h' + 1

    * GDP
    ivreg2 dgdp`h' ///
        i.cid i.year L1_dtau L2_dtau L1_infl L2_infl ///
        L1_dunemp L2_dunemp ///
        (dtau = z) ///
        if sample_eu_pre == 1, ///
        robust

    replace horizon3 = `h' in `hh'
    replace b_gdp3   = _b[dtau] in `hh'
    replace se_gdp3  = _se[dtau] in `hh'
    replace f_stat3  = e(widstat) in `hh'

    * GDP DEFLATOR
    ivreg2 ddefl`h' ///
        i.cid i.year L1_dtau L2_dtau L1_infl L2_infl ///
        L1_dunemp L2_dunemp ///
        (dtau = z) ///
        if sample_eu_pre == 1, ///
        robust

    replace b_defl3  = _b[dtau] in `hh'
    replace se_defl3 = _se[dtau] in `hh'

    * UNEMPLOYMENT
    ivreg2 dunemp`h' ///
        i.cid i.year L1_dtau L2_dtau L1_infl L2_infl ///
        L1_dunemp L2_dunemp ///
        (dtau = z) ///
        if sample_eu_pre == 1, ///
        robust

    replace b_unemp3  = _b[dtau] in `hh'
    replace se_unemp3 = _se[dtau] in `hh'
}

di _n "First-stage F-statistics (European pre-WWI, year FE):"
list horizon3 f_stat3 if horizon3 != ., noobs clean

************************************************************
* SPEC 3: CONFIDENCE INTERVALS AND PLOTS
************************************************************

foreach var in gdp defl unemp {
    gen upper95_`var'3 = b_`var'3 + 1.96 * se_`var'3
    gen lower95_`var'3 = b_`var'3 - 1.96 * se_`var'3
    gen upper90_`var'3 = b_`var'3 + 1.645 * se_`var'3
    gen lower90_`var'3 = b_`var'3 - 1.645 * se_`var'3
}

twoway ///
    (rarea upper95_gdp3 lower95_gdp3 horizon3 if horizon3 <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_gdp3 lower90_gdp3 horizon3 if horizon3 <= 8, color(blue%40) lwidth(none)) ///
    (line b_gdp3 horizon3 if horizon3 <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Real GDP — European Panel, Pre-WWI, Year FE") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/panel_irf_gdp_eu_preww1_yearfe.png", replace

twoway ///
    (rarea upper95_defl3 lower95_defl3 horizon3 if horizon3 <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_defl3 lower90_defl3 horizon3 if horizon3 <= 8, color(blue%40) lwidth(none)) ///
    (line b_defl3 horizon3 if horizon3 <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("GDP Deflator — European Panel, Pre-WWI, Year FE") ///
    xtitle("Years") ytitle("%") ///
    legend(off)
graph export "intl_tariffs/graphs/panel_irf_defl_eu_preww1_yearfe.png", replace

twoway ///
    (rarea upper95_unemp3 lower95_unemp3 horizon3 if horizon3 <= 8, color(blue%20) lwidth(none)) ///
    (rarea upper90_unemp3 lower90_unemp3 horizon3 if horizon3 <= 8, color(blue%40) lwidth(none)) ///
    (line b_unemp3 horizon3 if horizon3 <= 8, lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    title("Unemployment — European Panel, Pre-WWI, Year FE") ///
    xtitle("Years") ytitle("ppt") ///
    legend(off)
graph export "intl_tariffs/graphs/panel_irf_unemp_eu_preww1_yearfe.png", replace

************************************************************
* FIRST-STAGE SUMMARY
************************************************************

di _n "============================================================"
di "FIRST STAGE DETAILS"
di "============================================================"

reg dtau z i.cid L1_dtau L2_dtau L1_infl L2_infl L1_dunemp L2_dunemp if sample_eu_pre == 1, robust
di "Spec 1 — European pre-WWI, country FE only — F on z: " e(F)

reg dtau z i.cid L1_dtau L2_dtau L1_infl L2_infl L1_dunemp L2_dunemp if sample_full == 1, robust
di "Spec 2 — Full sample, country FE only — F on z: " e(F)

reg dtau z i.cid i.year L1_dtau L2_dtau L1_infl L2_infl L1_dunemp L2_dunemp if sample_eu_pre == 1, robust
di "Spec 3 — European pre-WWI, country + year FE — F on z: " e(F)

