
************************************************************
* COUNTRY-BY-COUNTRY LP-IV: INTERNATIONAL TARIFF SHOCKS
* Same specification as run_lpiv.do but estimated separately
* for each country. Results saved in graphs/lp_iv/<ISO3>/
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
* (identical coding to run_lpiv.do)
************************************************************

gen z = 0

* --- GBR ---
* Repeal of Corn Laws: impl. 02/01/1849 (day 32 of 365)
replace z = z + -1 * (365-32)/365  if iso3 == "GBR" & year == 1849
replace z = z + -1 * 32/365        if iso3 == "GBR" & year == 1850

* Gladstone 1853 Budget: impl. 08/20/1853 (day 232 of 365)
replace z = z + -1 * (365-232)/365 if iso3 == "GBR" & year == 1853
replace z = z + -1 * 232/365       if iso3 == "GBR" & year == 1854

* Cobden-Chevalier Treaty: impl. 07/01/1860 (day 183 of 366)
replace z = z + -1 * (366-183)/366 if iso3 == "GBR" & year == 1860
replace z = z + -1 * 183/366       if iso3 == "GBR" & year == 1861

* GATT Geneva Round: impl. 01/01/1948 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "GBR" & year == 1948

* GATT Kennedy Round: impl. 01/01/1968 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "GBR" & year == 1968

* EC Accession: impl. 01/01/1973 (day 1 of 365)
replace z = z + -1 * (365-1)/365   if iso3 == "GBR" & year == 1973

* GATT Tokyo Round: impl. 01/01/1980 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "GBR" & year == 1980

* --- FRA ---
* Cobden-Chevalier Treaty: impl. 07/23/1860 (day 205 of 366)
replace z = z + -1 * (366-205)/366 if iso3 == "FRA" & year == 1860
replace z = z + -1 * 205/366       if iso3 == "FRA" & year == 1861

* Tariff Law of May 7 1881: impl. 05/07/1881 (day 127 of 365)
replace z = z + (365-127)/365 if iso3 == "FRA" & year == 1881
replace z = z + 127/365       if iso3 == "FRA" & year == 1882

* Meline Tariff: impl. 01/11/1892 (day 11 of 366)
replace z = z + (366-11)/366  if iso3 == "FRA" & year == 1892
replace z = z + 11/366        if iso3 == "FRA" & year == 1893

* 1910 Tariff Revision: impl. 03/29/1910 (day 88 of 365)
replace z = z + (365-88)/365  if iso3 == "FRA" & year == 1910
replace z = z + 88/365        if iso3 == "FRA" & year == 1911

* 1927 Tariff Revision: impl. 08/03/1927 (day 215 of 365)
replace z = z + (365-215)/365 if iso3 == "FRA" & year == 1927
replace z = z + 215/365       if iso3 == "FRA" & year == 1928

* GATT Geneva Round: impl. 01/01/1948 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "FRA" & year == 1948

* GATT Dillon Round: impl. 01/01/1963 (day 1 of 365)
replace z = z + -1 * (365-1)/365   if iso3 == "FRA" & year == 1963

* GATT Kennedy Round: impl. 01/01/1968 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "FRA" & year == 1968

* GATT Tokyo Round: impl. 01/01/1980 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "FRA" & year == 1980

* --- DEU ---
* Zollverein Reform: impl. 01/01/1853 (day 1 of 365)
replace z = z + -1 * (365-1)/365   if iso3 == "DEU" & year == 1853

* Franco-Prussian Commercial Treaty: impl. 01/01/1866 (day 1 of 365)
replace z = z + -1 * (365-1)/365   if iso3 == "DEU" & year == 1866

* Abolition of Iron Duties: impl. 01/01/1873 (day 1 of 365)
replace z = z + -1 * (365-1)/365   if iso3 == "DEU" & year == 1873

* Bulow Tariff: impl. 01/01/1903 (day 1 of 365)
replace z = z + (365-1)/365   if iso3 == "DEU" & year == 1903

* GATT Dillon Round: impl. 01/01/1963 (day 1 of 365)
replace z = z + -1 * (365-1)/365   if iso3 == "DEU" & year == 1963

* GATT Kennedy Round: impl. 01/01/1968 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "DEU" & year == 1968

* GATT Tokyo Round: impl. 01/01/1980 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "DEU" & year == 1980

* --- ITA ---
* Unification (Piedmont Liberal Tariff): impl. 01/01/1860 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "ITA" & year == 1860

* GATT Dillon Round: impl. 01/01/1963 (day 1 of 365)
replace z = z + -1 * (365-1)/365   if iso3 == "ITA" & year == 1963

* GATT Kennedy Round: impl. 01/01/1968 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "ITA" & year == 1968

* GATT Tokyo Round: impl. 01/01/1980 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "ITA" & year == 1980

* --- NLD ---
* 1924 Tariff Revision: impl. 01/01/1925 (day 1 of 365)
replace z = z + (365-1)/365   if iso3 == "NLD" & year == 1925

* GATT Dillon Round: impl. 01/01/1963 (day 1 of 365)
replace z = z + -1 * (365-1)/365   if iso3 == "NLD" & year == 1963

* GATT Kennedy Round: impl. 01/01/1968 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "NLD" & year == 1968

* GATT Tokyo Round: impl. 01/01/1980 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "NLD" & year == 1980

* --- BEL ---
* GATT Geneva Round: impl. 01/01/1948 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "BEL" & year == 1948

* GATT Kennedy Round: impl. 01/01/1968 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "BEL" & year == 1968

* GATT Tokyo Round: impl. 01/01/1980 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "BEL" & year == 1980

* --- PRT ---
* EFTA Accession: impl. 07/01/1960 (day 183 of 366)
replace z = z + -1 * (366-183)/366 if iso3 == "PRT" & year == 1960
replace z = z + -1 * 183/366       if iso3 == "PRT" & year == 1961

* GATT Dillon Round: impl. 01/01/1963 (day 1 of 365)
replace z = z + -1 * (365-1)/365   if iso3 == "PRT" & year == 1963

* GATT Kennedy Round: impl. 01/01/1968 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "PRT" & year == 1968

* EC Free Trade Agreement: impl. 01/01/1973 (day 1 of 365)
replace z = z + -1 * (365-1)/365   if iso3 == "PRT" & year == 1973

* --- CHE ---
* Swiss Tariff Reform: impl. 01/01/1864 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "CHE" & year == 1864

* Canovas Tariff: impl. 01/01/1891 (day 1 of 365)
replace z = z + (365-1)/365   if iso3 == "CHE" & year == 1891

* GATT Kennedy Round: impl. 01/01/1968 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "CHE" & year == 1968

* FTA with EC: impl. 01/01/1973 (day 1 of 365)
replace z = z + -1 * (365-1)/365   if iso3 == "CHE" & year == 1973

* GATT Tokyo Round: impl. 01/01/1980 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "CHE" & year == 1980

* --- ESP ---
* GATT Dillon Round: impl. 01/01/1963 (day 1 of 365)
replace z = z + -1 * (365-1)/365   if iso3 == "ESP" & year == 1963

* GATT Kennedy Round: impl. 01/01/1968 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "ESP" & year == 1968

* --- JPN ---
* GATT Kennedy Round: impl. 01/01/1968 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "JPN" & year == 1968

* GATT Tokyo Round: impl. 01/01/1980 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "JPN" & year == 1980

* --- BRA ---
* GATT Geneva Round: impl. 01/01/1948 (day 1 of 366)
replace z = z + -1 * (366-1)/366   if iso3 == "BRA" & year == 1948

* --- MEX ---
* GATT Accession: impl. 08/24/1986 (day 236 of 365)
replace z = z + -1 * (365-236)/365 if iso3 == "MEX" & year == 1986
replace z = z + -1 * 236/365       if iso3 == "MEX" & year == 1987

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
* CREATE OUTPUT DIRECTORIES
************************************************************

capture mkdir "intl_tariffs/graphs/lp_iv"
foreach cc in GBR FRA DEU ITA NLD BEL PRT CHE ESP JPN BRA MEX {
    capture mkdir "intl_tariffs/graphs/lp_iv/`cc'"
}
capture mkdir "intl_tariffs/graphs/lp_iv_preww1"
foreach cc in GBR FRA DEU ITA NLD BEL PRT CHE ESP {
    capture mkdir "intl_tariffs/graphs/lp_iv_preww1/`cc'"
}

************************************************************
* COUNTRY-BY-COUNTRY ESTIMATION
************************************************************

local countries GBR FRA DEU ITA NLD BEL PRT CHE ESP JPN BRA MEX

foreach cc of local countries {

    di _n "============================================================"
    di "COUNTRY: `cc'"
    di "============================================================"

    * count shocks
    count if z != 0 & iso3 == "`cc'" & !missing(dtau)
    local nshocks = r(N)
    di "Shocks in estimation sample: `nshocks'"

    if `nshocks' < 2 {
        di "Skipping `cc' — fewer than 2 shocks in sample"
        continue
    }

    * storage (use tempvars to avoid name conflicts across loop iterations)
    tempvar horizon b_gdp se_gdp b_defl se_defl b_unemp se_unemp fstat
    gen `horizon' = .
    gen `b_gdp' = .
    gen `se_gdp' = .
    gen `b_defl' = .
    gen `se_defl' = .
    gen `b_unemp' = .
    gen `se_unemp' = .
    gen `fstat' = .

    local est_ok = 1

    forvalues h = 0/8 {

        local hh = `h' + 1

        * GDP
        capture ivreg2 dgdp`h' ///
            L1_dtau L2_dtau L1_infl L2_infl ///
            L1_dunemp L2_dunemp ///
            (dtau = z) ///
            if iso3 == "`cc'", ///
            robust

        if _rc == 0 {
            replace `horizon' = `h' in `hh'
            replace `b_gdp'   = _b[dtau] in `hh'
            replace `se_gdp'  = _se[dtau] in `hh'
            replace `fstat'   = e(widstat) in `hh'
        }
        else {
            di "  GDP h=`h' failed for `cc'"
            local est_ok = 0
        }

        * GDP DEFLATOR
        capture ivreg2 ddefl`h' ///
            L1_dtau L2_dtau L1_infl L2_infl ///
            L1_dunemp L2_dunemp ///
            (dtau = z) ///
            if iso3 == "`cc'", ///
            robust

        if _rc == 0 {
            replace `b_defl'  = _b[dtau] in `hh'
            replace `se_defl' = _se[dtau] in `hh'
        }
        else {
            di "  Deflator h=`h' failed for `cc'"
        }

        * UNEMPLOYMENT
        capture ivreg2 dunemp`h' ///
            L1_dtau L2_dtau L1_infl L2_infl ///
            L1_dunemp L2_dunemp ///
            (dtau = z) ///
            if iso3 == "`cc'", ///
            robust

        if _rc == 0 {
            replace `b_unemp'  = _b[dtau] in `hh'
            replace `se_unemp' = _se[dtau] in `hh'
        }
        else {
            di "  Unemployment h=`h' failed for `cc'"
        }
    }

    * report F-stats
    di _n "First-stage F-statistics (`cc'):"
    list `horizon' `fstat' if `horizon' != ., noobs clean

    * confidence intervals
    tempvar up95g lo95g up90g lo90g up95d lo95d up90d lo90d up95u lo95u up90u lo90u
    gen `up95g' = `b_gdp' + 1.96 * `se_gdp'
    gen `lo95g' = `b_gdp' - 1.96 * `se_gdp'
    gen `up90g' = `b_gdp' + 1.645 * `se_gdp'
    gen `lo90g' = `b_gdp' - 1.645 * `se_gdp'
    gen `up95d' = `b_defl' + 1.96 * `se_defl'
    gen `lo95d' = `b_defl' - 1.96 * `se_defl'
    gen `up90d' = `b_defl' + 1.645 * `se_defl'
    gen `lo90d' = `b_defl' - 1.645 * `se_defl'
    gen `up95u' = `b_unemp' + 1.96 * `se_unemp'
    gen `lo95u' = `b_unemp' - 1.96 * `se_unemp'
    gen `up90u' = `b_unemp' + 1.645 * `se_unemp'
    gen `lo90u' = `b_unemp' - 1.645 * `se_unemp'

    * plots
    twoway ///
        (rarea `up95g' `lo95g' `horizon' if `horizon' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `up90g' `lo90g' `horizon' if `horizon' <= 8, color(blue%40) lwidth(none)) ///
        (line `b_gdp' `horizon' if `horizon' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("Real GDP — `cc'") ///
        xtitle("Years") ytitle("%") ///
        legend(off)
    graph export "intl_tariffs/graphs/lp_iv/`cc'/irf_gdp.png", replace

    twoway ///
        (rarea `up95d' `lo95d' `horizon' if `horizon' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `up90d' `lo90d' `horizon' if `horizon' <= 8, color(blue%40) lwidth(none)) ///
        (line `b_defl' `horizon' if `horizon' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("GDP Deflator — `cc'") ///
        xtitle("Years") ytitle("%") ///
        legend(off)
    graph export "intl_tariffs/graphs/lp_iv/`cc'/irf_defl.png", replace

    twoway ///
        (rarea `up95u' `lo95u' `horizon' if `horizon' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `up90u' `lo90u' `horizon' if `horizon' <= 8, color(blue%40) lwidth(none)) ///
        (line `b_unemp' `horizon' if `horizon' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("Unemployment — `cc'") ///
        xtitle("Years") ytitle("ppt") ///
        legend(off)
    graph export "intl_tariffs/graphs/lp_iv/`cc'/irf_unemp.png", replace

    * clean up tempvars
    drop `horizon' `b_gdp' `se_gdp' `b_defl' `se_defl' `b_unemp' `se_unemp' `fstat'
    drop `up95g' `lo95g' `up90g' `lo90g' `up95d' `lo95d' `up90d' `lo90d' `up95u' `lo95u' `up90u' `lo90u'
}

************************************************************
************************************************************
* PRE-WWI EUROPEAN COUNTRIES (year <= 1913)
* Saves to graphs/lp_iv_preww1/<ISO3>/
************************************************************
************************************************************

di _n _n "############################################################"
di "PRE-WWI EUROPEAN ESTIMATION (year <= 1913)"
di "############################################################"

local eu_countries GBR FRA DEU ITA NLD BEL PRT CHE ESP

foreach cc of local eu_countries {

    di _n "============================================================"
    di "COUNTRY (pre-WWI): `cc'"
    di "============================================================"

    * count shocks in pre-WWI window
    count if z != 0 & iso3 == "`cc'" & year <= 1913 & !missing(dtau)
    local nshocks = r(N)
    di "Pre-WWI shocks in estimation sample: `nshocks'"

    if `nshocks' < 2 {
        di "Skipping `cc' — fewer than 2 pre-WWI shocks"
        continue
    }

    * storage
    tempvar horizon b_gdp se_gdp b_defl se_defl b_unemp se_unemp fstat
    gen `horizon' = .
    gen `b_gdp' = .
    gen `se_gdp' = .
    gen `b_defl' = .
    gen `se_defl' = .
    gen `b_unemp' = .
    gen `se_unemp' = .
    gen `fstat' = .

    forvalues h = 0/8 {

        local hh = `h' + 1

        * GDP
        capture ivreg2 dgdp`h' ///
            L1_dtau L2_dtau L1_infl L2_infl ///
            L1_dunemp L2_dunemp ///
            (dtau = z) ///
            if iso3 == "`cc'" & year <= 1913, ///
            robust

        if _rc == 0 {
            replace `horizon' = `h' in `hh'
            replace `b_gdp'   = _b[dtau] in `hh'
            replace `se_gdp'  = _se[dtau] in `hh'
            replace `fstat'   = e(widstat) in `hh'
        }
        else {
            di "  GDP h=`h' failed for `cc' (pre-WWI)"
        }

        * GDP DEFLATOR
        capture ivreg2 ddefl`h' ///
            L1_dtau L2_dtau L1_infl L2_infl ///
            L1_dunemp L2_dunemp ///
            (dtau = z) ///
            if iso3 == "`cc'" & year <= 1913, ///
            robust

        if _rc == 0 {
            replace `b_defl'  = _b[dtau] in `hh'
            replace `se_defl' = _se[dtau] in `hh'
        }
        else {
            di "  Deflator h=`h' failed for `cc' (pre-WWI)"
        }

        * UNEMPLOYMENT
        capture ivreg2 dunemp`h' ///
            L1_dtau L2_dtau L1_infl L2_infl ///
            L1_dunemp L2_dunemp ///
            (dtau = z) ///
            if iso3 == "`cc'" & year <= 1913, ///
            robust

        if _rc == 0 {
            replace `b_unemp'  = _b[dtau] in `hh'
            replace `se_unemp' = _se[dtau] in `hh'
        }
        else {
            di "  Unemployment h=`h' failed for `cc' (pre-WWI)"
        }
    }

    * report F-stats
    di _n "First-stage F-statistics (`cc', pre-WWI):"
    list `horizon' `fstat' if `horizon' != ., noobs clean

    * confidence intervals
    tempvar up95g lo95g up90g lo90g up95d lo95d up90d lo90d up95u lo95u up90u lo90u
    gen `up95g' = `b_gdp' + 1.96 * `se_gdp'
    gen `lo95g' = `b_gdp' - 1.96 * `se_gdp'
    gen `up90g' = `b_gdp' + 1.645 * `se_gdp'
    gen `lo90g' = `b_gdp' - 1.645 * `se_gdp'
    gen `up95d' = `b_defl' + 1.96 * `se_defl'
    gen `lo95d' = `b_defl' - 1.96 * `se_defl'
    gen `up90d' = `b_defl' + 1.645 * `se_defl'
    gen `lo90d' = `b_defl' - 1.645 * `se_defl'
    gen `up95u' = `b_unemp' + 1.96 * `se_unemp'
    gen `lo95u' = `b_unemp' - 1.96 * `se_unemp'
    gen `up90u' = `b_unemp' + 1.645 * `se_unemp'
    gen `lo90u' = `b_unemp' - 1.645 * `se_unemp'

    * plots
    twoway ///
        (rarea `up95g' `lo95g' `horizon' if `horizon' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `up90g' `lo90g' `horizon' if `horizon' <= 8, color(blue%40) lwidth(none)) ///
        (line `b_gdp' `horizon' if `horizon' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("Real GDP — `cc' (Pre-WWI)") ///
        xtitle("Years") ytitle("%") ///
        legend(off)
    graph export "intl_tariffs/graphs/lp_iv_preww1/`cc'/irf_gdp.png", replace

    twoway ///
        (rarea `up95d' `lo95d' `horizon' if `horizon' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `up90d' `lo90d' `horizon' if `horizon' <= 8, color(blue%40) lwidth(none)) ///
        (line `b_defl' `horizon' if `horizon' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("GDP Deflator — `cc' (Pre-WWI)") ///
        xtitle("Years") ytitle("%") ///
        legend(off)
    graph export "intl_tariffs/graphs/lp_iv_preww1/`cc'/irf_defl.png", replace

    twoway ///
        (rarea `up95u' `lo95u' `horizon' if `horizon' <= 8, color(blue%20) lwidth(none)) ///
        (rarea `up90u' `lo90u' `horizon' if `horizon' <= 8, color(blue%40) lwidth(none)) ///
        (line `b_unemp' `horizon' if `horizon' <= 8, lcolor(black) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("Unemployment — `cc' (Pre-WWI)") ///
        xtitle("Years") ytitle("ppt") ///
        legend(off)
    graph export "intl_tariffs/graphs/lp_iv_preww1/`cc'/irf_unemp.png", replace

    * clean up tempvars
    drop `horizon' `b_gdp' `se_gdp' `b_defl' `se_defl' `b_unemp' `se_unemp' `fstat'
    drop `up95g' `lo95g' `up90g' `lo90g' `up95d' `lo95d' `up90d' `lo90d' `up95u' `lo95u' `up90u' `lo90u'
}
