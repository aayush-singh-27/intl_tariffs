
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
* Following Den Besten & Kanzig (2026) methodology:
*   - Direction from narrative sources (not ex-post tariff data)
*   - Implementation date determines timing
*   - Time-weighted: days_remaining/days_in_year in impl. year,
*     remainder spills to following year
*   - Exogeneity screen: exclude fiscal, countercyclical, external
*     imbalance motivations
*   - Exclude shocks outside tau_tamar coverage (ends 1988)
************************************************************

gen z = 0

* --- GBR ---
* Gladstone 1853 Budget: Royal Assent ~July 1853 (day 188)
* Exog: trade ideology (completing Peel's free-trade program)
replace z = -1 * (365-188)/365 if iso3 == "GBR" & year == 1853
replace z = -1 * 188/365       if iso3 == "GBR" & year == 1854

* Gladstone 1860 Budget + Cobden-Chevalier: Finance Act ~July 1860 (day 182)
* Exog: trade ideology (free trade)
replace z = -1 * (366-182)/366 if iso3 == "GBR" & year == 1860
replace z = -1 * 182/366       if iso3 == "GBR" & year == 1861

* GATT Geneva I: implemented Jan 1, 1948
* Exog: trade ideology + political (multilateral liberalization)
replace z = -1 * (366-1)/366   if iso3 == "GBR" & year == 1948

* EFTA 1960: DROPPED — tau_tamar shows no decrease (drifts up 1959-61)

* GATT Kennedy Round: implemented Jan 1, 1968 (day 1 of 366)
* Exog: trade ideology + political
replace z = -1 * (366-1)/366   if iso3 == "GBR" & year == 1968

* EC accession: Jan 1, 1973 (day 1 of 365)
* Exog: political (European integration)
replace z = -1 * (365-1)/365   if iso3 == "GBR" & year == 1973

* GATT Tokyo Round: implemented Jan 1, 1980 (day 1 of 366)
* Exog: trade ideology + political
replace z = -1 * (366-1)/366   if iso3 == "GBR" & year == 1980

* --- FRA ---
* Cobden-Chevalier: supp. convention Oct 16, 1860 (day 290 of 366)
* Exog: political/diplomatic + trade ideology
replace z = -1 * (366-290)/366 if iso3 == "FRA" & year == 1860
replace z = -1 * 290/366       if iso3 == "FRA" & year == 1861

* 1872 EXCLUDED: endogenous (fiscal — Franco-Prussian war indemnity)

* Tariff law of May 7, 1881 (day 127 of 365): agricultural protection
* Exog: distributional (agricultural lobby)
replace z = +1 * (365-127)/365 if iso3 == "FRA" & year == 1881
replace z = +1 * 127/365       if iso3 == "FRA" & year == 1882

* 1910 tariff revision (~mid-year): protectionist update
* Exog: trade ideology (maintaining protectionist regime)
replace z = +1 * 0.5           if iso3 == "FRA" & year == 1910
replace z = +1 * 0.5           if iso3 == "FRA" & year == 1911

* GATT Geneva I: Jan 1, 1948
replace z = -1 * (366-1)/366   if iso3 == "FRA" & year == 1948

* GATT Dillon Round: Dec 31, 1962 — all weight spills to 1963
replace z = -1                  if iso3 == "FRA" & year == 1963

* GATT Kennedy Round: Jan 1, 1968
replace z = -1 * (366-1)/366   if iso3 == "FRA" & year == 1968

* GATT Tokyo Round: Jan 1, 1980
replace z = -1 * (366-1)/366   if iso3 == "FRA" & year == 1980

* --- DEU ---
* Zollverein reform: agreed Feb 1853, implemented Jan 1, 1854
* Exog: political (Prussian geopolitical strategy to exclude Austria)
replace z = -1 * (365-1)/365   if iso3 == "DEU" & year == 1854

* Franco-Prussian commercial treaty: signed Aug 1862, implemented 1865
* Exog: trade ideology + political (Prussian-led integration)
replace z = -1 * (365-1)/365   if iso3 == "DEU" & year == 1865

* Abolition of iron duties: ~mid-1873 (phase-out from 1860s treaties)
* Exog: trade ideology (continuation of liberal treaty schedule)
replace z = -1 * 0.5           if iso3 == "DEU" & year == 1873

* Caprivi trade treaties: first effective Feb 1, 1892 (day 32 of 366)
* LIBERALIZATION (reduced agricultural tariffs) — NOT protection
* Exog: trade ideology (export-led growth) + political
replace z = -1 * (366-32)/366  if iso3 == "DEU" & year == 1892

* GATT Torquay 1951: DROPPED — tau_tamar rises (DEU rebuilding tariffs post-war)

* GATT Dillon Round: Dec 31, 1962 — spills to 1963
replace z = -1                  if iso3 == "DEU" & year == 1963

* GATT Kennedy Round: Jan 1, 1968
replace z = -1 * (366-1)/366   if iso3 == "DEU" & year == 1968

* GATT Tokyo Round: Jan 1, 1980
replace z = -1 * (366-1)/366   if iso3 == "DEU" & year == 1980

* --- ITA ---
* Unification: Piedmont's liberal tariff extended 1861-62 (Jan 1, 1862)
* Exog: political + trade ideology (Cavour's liberal program)
replace z = -1 * (366-1)/366   if iso3 == "ITA" & year == 1862

* GATT Torquay 1951: DROPPED — tau_tamar jumps up (ITA rebuilding tariffs post-war)

* GATT Dillon Round: Dec 31, 1962 — spills to 1963
replace z = -1                  if iso3 == "ITA" & year == 1963

* GATT Kennedy Round: Jan 1, 1968
replace z = -1 * (366-1)/366   if iso3 == "ITA" & year == 1968

* GATT Tokyo Round: Jan 1, 1980
replace z = -1 * (366-1)/366   if iso3 == "ITA" & year == 1980

* --- NLD ---
* GATT Geneva I 1948: DROPPED — tau_tamar jumps up (NLD re-imposing tariffs post-war)

* GATT Dillon Round: Dec 31, 1962 — spills to 1963
replace z = -1                  if iso3 == "NLD" & year == 1963

* GATT Kennedy Round: Jan 1, 1968
replace z = -1 * (366-1)/366   if iso3 == "NLD" & year == 1968

* GATT Tokyo Round: Jan 1, 1980
replace z = -1 * (366-1)/366   if iso3 == "NLD" & year == 1980

* --- BEL ---
* GATT Geneva I: Jan 1, 1948
replace z = -1 * (366-1)/366   if iso3 == "BEL" & year == 1948

* GATT Dillon 1963: DROPPED — dtau only -0.07pp (noise)

* GATT Kennedy Round: Jan 1, 1968
replace z = -1 * (366-1)/366   if iso3 == "BEL" & year == 1968

* GATT Tokyo 1980: DROPPED — dtau only -0.01pp (noise)

* --- PRT ---
* EFTA accession: July 1, 1960 (day 183 of 366)
* Exog: political
replace z = -1 * (366-183)/366 if iso3 == "PRT" & year == 1960
replace z = -1 * 183/366       if iso3 == "PRT" & year == 1961

* GATT Dillon Round (PRT joined 1962): Dec 31, 1962 — spills to 1963
replace z = -1                  if iso3 == "PRT" & year == 1963

* Kennedy Round: Jan 1, 1968
replace z = -1 * (366-1)/366   if iso3 == "PRT" & year == 1968

* EC accession 1986: DROPPED — tau_tamar shows no decrease

* --- CHE ---
* EFTA 1960: DROPPED — tau_tamar rises (no visible cut)

* GATT accession (1966) + Kennedy Round prep: Jan 1, 1968
replace z = -1 * (366-1)/366   if iso3 == "CHE" & year == 1968

* GATT Tokyo Round: Jan 1, 1980
replace z = -1 * (366-1)/366   if iso3 == "CHE" & year == 1980

* --- ESP ---
* Figuerola/Glorious Revolution: tau drops sharply in 1868 (day ~270 of 366)
* Exog: trade ideology (free-trade ideology of revolutionary govt)
* Note: traditionally dated 1869 but tau_tamar shows the big cut in 1868
replace z = -1 * (366-270)/366 if iso3 == "ESP" & year == 1868
replace z = -1 * 270/366       if iso3 == "ESP" & year == 1869

* GATT accession (1963) + Dillon Round: effectively 1963
replace z = -1                  if iso3 == "ESP" & year == 1963

* Kennedy Round: Jan 1, 1968
replace z = -1 * (366-1)/366   if iso3 == "ESP" & year == 1968

* EC accession 1986: DROPPED — tau_tamar rises (no visible cut)

* --- JPN ---
* Tariff autonomy revision of 1899: ~April 1899 (day 91 of 365)
* Exog: political (regaining tariff sovereignty from unequal treaties)
replace z = +1 * (365-91)/365  if iso3 == "JPN" & year == 1899
replace z = +1 * 91/365        if iso3 == "JPN" & year == 1900

* 1911 tariff revision: protectionist update (~April, day 91 of 365)
* Exog: trade ideology (industrial protection)
replace z = +1 * (365-91)/365  if iso3 == "JPN" & year == 1911
replace z = +1 * 91/365        if iso3 == "JPN" & year == 1912

* GATT Geneva II / 1955 accession: DROPPED — tau_tamar rises throughout 1955-58

* GATT Kennedy Round: Jan 1, 1968
replace z = -1 * (366-1)/366   if iso3 == "JPN" & year == 1968

* GATT Tokyo Round: Jan 1, 1980
replace z = -1 * (366-1)/366   if iso3 == "JPN" & year == 1980

* --- BRA ---
* GATT Geneva I (original member): Jan 1, 1948
replace z = -1 * (366-1)/366   if iso3 == "BRA" & year == 1948

* --- MEX ---
* GATT accession: Aug 24, 1986 (day 236 of 365)
* Exog: trade ideology (neoliberal reform under de la Madrid)
replace z = -1 * (365-236)/365 if iso3 == "MEX" & year == 1986
replace z = -1 * 236/365       if iso3 == "MEX" & year == 1987

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

