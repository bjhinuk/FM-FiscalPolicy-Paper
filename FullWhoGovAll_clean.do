*=================================================================
* Gender, Ideology, and Fiscal Policy:
* Evidence from Finance Ministers Across a Global Panel
*
* Master replication do-file
* Author: Jhinuk Banerjee, University of Oklahoma
* Contact: jhinuk.ban1@ou.edu
* Date: May 2026
*
* INSTRUCTIONS:
* 1. Update the global path below to your local directory
* 2. Place WhoGov(w+cs)+GLID_WEO(1).dta in that folder
* 3. Run this do-file in its entirety
* 4. All tables (.tex) and figures (.pdf) will be saved to outpath
*=================================================================

*-----------------------------------------------------------------
* 0. SETUP
*-----------------------------------------------------------------

*--- Update these two paths only ---
global datapath "/Users/jhinukbanerji/Desktop/Oklahoma/W-FM/DATA/WhoGov_data/"
global outpath  "/Users/jhinukbanerji/Desktop/Oklahoma/W-FM/DATA/WhoGov_data/"

*--- Install required packages (uncomment and run once if needed) ---
* ssc install ivreghdfe, replace
* ssc install ivreg2,    replace
* ssc install ranktest,  replace
* ssc install reghdfe,   replace
* ssc install ftools,    replace
* ssc install estout,    replace

*--- Load analysis dataset ---
use "${datapath}WhoGov(w+cs)+GLID_WEO(1).dta", clear
di "Dataset loaded: " _N " observations"

*--- Panel setup ---
encode iso, gen(country_id)
xtset country_id year

*--- Sample restriction: 1990-2023 ---
keep if year >= 1990 & year <= 2023
di "Observations after 1990-2023 restriction: " _N

*--- Re-xtset after restriction ---
xtset country_id year

*--- Global variable lists ---
global treatment     "female_fm"
global outcomes      "balance_gdp primary_balance_gdp structural_balance_gdp"
global controls_main "gdp_growth inflation gross_debt_gdp democracy hog_ideology_num_redux"

*-----------------------------------------------------------------
* 1. VARIABLE CONSTRUCTION
*-----------------------------------------------------------------

*--- Treatment variable ---
capture drop female_fm
gen female_fm = (m_Finance == 1 & gender == "Female")
label var female_fm "Women Finance Minister (=1)"

*--- Decade indicator ---
capture drop decade
gen decade = floor(year/10)*10
label var decade "Decade"

*--- FM age at appointment (IV2) ---
capture drop fm_age
gen fm_age = year - birthyear
label var fm_age "Finance Minister age at appointment"

*--- IV1: Relative cabinet women share (region-decade deviation) ---
capture drop region_decade_mean_cab iv10_relative_cabinet
bysort region decade: egen region_decade_mean_cab = mean(n_female_minister)
gen iv10_relative_cabinet = n_female_minister - region_decade_mean_cab
label var iv10_relative_cabinet "Cabinet women relative to region-decade mean (IV1)"

*--- Ideology split for robustness ---
capture drop female_fm_left female_fm_right
gen female_fm_left  = female_fm * (fm_ideology1 <= 2)
gen female_fm_right = female_fm * (fm_ideology1 >= 4)
label var female_fm_left  "Left women FM (ideology 1-2)"
label var female_fm_right "Right women FM (ideology 4-6)"

*--- Cumulative treatment for robustness ---
capture drop cum_female_fm
bysort country_id (year): gen cum_female_fm = sum(female_fm)
label var cum_female_fm "Cumulative years with women FM"

*--- Placebo indicator (seed for replicability) ---
capture drop placebo_fm
set seed 1234
bysort country_id: gen placebo_fm = female_fm[ceil(_N * runiform())]
label var placebo_fm "Placebo: randomly reassigned within country"

*--- Region numeric for region x year FE ---
capture drop region_num
encode region, gen(region_num)

di "=== Variable construction complete ==="

*-----------------------------------------------------------------
* 2. DESCRIPTIVE STATISTICS TABLES
*-----------------------------------------------------------------

*--- Table A1: Full sample summary statistics ---
eststo clear
eststo desc: quietly estpost summarize ///
    $treatment $outcomes $controls_main fm_ideology1

esttab desc using "${outpath}desc_stats_full.tex", replace ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") ///
    noobs nonumber ///
    title("Summary Statistics: Full Sample 1990--2023") ///
    collabels("Mean" "SD" "Min" "Max" "N") ///
    note("Unit of observation is country-year.")

*--- Table A2: Summary by FM gender ---
eststo clear
eststo male:   quietly estpost summarize $outcomes $controls_main if female_fm == 0
eststo female: quietly estpost summarize $outcomes $controls_main if female_fm == 1

esttab male female using "${outpath}desc_stats_bygender.tex", replace ///
    cells("mean(fmt(3)) sd(fmt(3))") ///
    noobs nonumber ///
    mtitles("Male FM" "Female FM") ///
    title("Summary Statistics by Finance Minister Gender") ///
    note("Unit of observation is country-year.")

*--- Table A3: Women FM by UN region ---
eststo clear
eststo region_tab: quietly estpost tabulate region female_fm

esttab region_tab using "${outpath}desc_region_femfm.tex", replace ///
    cells("b(fmt(0))") noobs nonumber ///
    title("Women Finance Ministers by World Region, 1990--2023") ///
    collabels("Male FM" "Female FM") ///
    note("Cell entries are country-year observations.")

*--- Table A4: Women FM by decade ---
eststo clear
eststo decade_tab: quietly estpost tabulate decade female_fm

esttab decade_tab using "${outpath}desc_decade_femfm.tex", replace ///
    cells("b(fmt(0))") noobs nonumber ///
    title("Women Finance Ministers by Decade, 1990--2023") ///
    collabels("Male FM" "Female FM") ///
    note("Cell entries are country-year observations.")

*--- Table A5: Ideology distribution by FM gender ---
eststo clear
eststo ideo_male:   quietly estpost summarize fm_ideology1 if female_fm == 0
eststo ideo_female: quietly estpost summarize fm_ideology1 if female_fm == 1

esttab ideo_male ideo_female using "${outpath}desc_ideology_femfm.tex", replace ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(0)) max(fmt(0)) count(fmt(0))") ///
    noobs nonumber ///
    mtitles("Male FM" "Female FM") ///
    title("FM Ideology by Gender, 1990--2023") ///
    collabels("Mean" "SD" "Min" "Max" "N") ///
    note("fm\_ideology1: 1 = far left, 6 = far right.")

ttest fm_ideology1, by(female_fm)

di "=== Descriptive tables complete ==="

*-----------------------------------------------------------------
* 3. INSTRUMENT CONSTRUCTION AND FIRST STAGE
*-----------------------------------------------------------------

*--- Additional instruments for comparison table ---
capture drop iv1_loo_count iv4_core_loo
gen iv1_loo_count = n_female_minister - (gender == "Female")
replace iv1_loo_count = 0 if iv1_loo_count < 0
label var iv1_loo_count "Women in other cabinet positions (LOO)"

gen iv4_core_loo = n_female_core - (gender == "Female")
replace iv4_core_loo = 0 if iv4_core_loo < 0
label var iv4_core_loo "Women in core cabinet excl. Finance (LOO)"

*--- Table 6: First stage comparison across instruments and FE ---
eststo clear

xtreg female_fm iv1_loo_count  $controls_main i.year, fe cluster(country_id)
estimates store fs_iv1

xtreg female_fm iv4_core_loo   $controls_main i.year, fe cluster(country_id)
estimates store fs_iv4

xtreg female_fm fm_age          $controls_main i.year, fe cluster(country_id)
estimates store fs_fmage_cfe

xtreg female_fm iv10_relative_cabinet $controls_main i.year, fe cluster(country_id)
estimates store fs_iv10_cfe

reghdfe female_fm iv10_relative_cabinet $controls_main, ///
    absorb(region year) cluster(country_id)
estimates store fs_iv10_rfe

esttab fs_iv1 fs_iv4 fs_fmage_cfe fs_iv10_cfe fs_iv10_rfe ///
    using "${outpath}iv_firststage_compare.tex", replace ///
    keep(iv1_loo_count iv4_core_loo fm_age iv10_relative_cabinet) ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 6: First Stage Comparison Across Instruments and Fixed Effects") ///
    mtitles("IV1 (CFE)" "IV4 (CFE)" "FM Age (CFE)" "IV10 (CFE)" "IV10 (RFE)") ///
    scalars("N Observations" "r2 R-squared") ///
    note("CFE = country and year FE. RFE = region and year FE. " ///
         "Clustered SEs at country level. Stock-Yogo 15% CV = 8.96 (1 IV), 11.59 (2 IVs).")

*--- Table 7: Preferred first stage (region and year FE, both IVs) ---
eststo clear

reghdfe female_fm iv10_relative_cabinet $controls_main, ///
    absorb(region year) cluster(country_id)
estimates store fs_iv10
test iv10_relative_cabinet

reghdfe female_fm fm_age $controls_main, ///
    absorb(region year) cluster(country_id)
estimates store fs_fmage
test fm_age

reghdfe female_fm iv10_relative_cabinet fm_age $controls_main, ///
    absorb(region year) cluster(country_id)
estimates store fs_both
testparm iv10_relative_cabinet fm_age

esttab fs_iv10 fs_fmage fs_both ///
    using "${outpath}table1_instrument_diagnostics.tex", replace ///
    keep(iv10_relative_cabinet fm_age $controls_main) ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 7: Preferred First Stage -- Region and Year Fixed Effects") ///
    mtitles("IV1 Only" "FM Age Only" "Both IVs") ///
    scalars("N Observations" "r2_a Adj. R-squared") ///
    note("Dependent variable: Women Finance Minister (=1). " ///
         "Region and year FE absorbed. Clustered SEs at country level. " ///
         "Kleibergen-Paap F: IV10=15.22, FM Age=16.05, Joint=13.65.")

di "=== First stage tables complete ==="

*-----------------------------------------------------------------
* 4. TWFE BASELINE (Table 8)
*-----------------------------------------------------------------

eststo clear

xtreg balance_gdp female_fm i.year, fe cluster(country_id)
estimates store tw_bal_nc

xtreg balance_gdp female_fm $controls_main i.year, fe cluster(country_id)
estimates store tw_bal_c

xtreg primary_balance_gdp female_fm i.year, fe cluster(country_id)
estimates store tw_prim_nc

xtreg primary_balance_gdp female_fm $controls_main i.year, fe cluster(country_id)
estimates store tw_prim_c

xtreg structural_balance_gdp female_fm i.year, fe cluster(country_id)
estimates store tw_struc_nc

xtreg structural_balance_gdp female_fm $controls_main i.year, fe cluster(country_id)
estimates store tw_struc_c

esttab tw_bal_nc tw_bal_c tw_prim_nc tw_prim_c tw_struc_nc tw_struc_c ///
    using "${outpath}table2_twfe_baseline.tex", replace ///
    keep(female_fm $controls_main) ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 8: TWFE Baseline -- Women Finance Ministers and Fiscal Outcomes") ///
    mgroups("Fiscal Balance" "Primary Balance" "Structural Balance", ///
        pattern(1 0 1 0 1 0)) ///
    mtitles("No Controls" "Controls" "No Controls" "Controls" ///
            "No Controls" "Controls") ///
    note("Country and year FE. Clustered SEs at country level.")

di "=== TWFE baseline complete ==="

*-----------------------------------------------------------------
* 5. GENDER-IDEOLOGY NEXUS (Tables 9-12)
*-----------------------------------------------------------------

*--- Table 9: FM ideology main effect ---
eststo clear

xtreg balance_gdp fm_ideology1 $controls_main i.year, fe cluster(country_id)
estimates store ideo_bal

xtreg primary_balance_gdp fm_ideology1 $controls_main i.year, fe cluster(country_id)
estimates store ideo_prim

xtreg structural_balance_gdp fm_ideology1 $controls_main i.year, fe cluster(country_id)
estimates store ideo_struc

esttab ideo_bal ideo_prim ideo_struc ///
    using "${outpath}table3a_ideology_main.tex", replace ///
    keep(fm_ideology1 $controls_main) ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 9: FM Ideology and Fiscal Outcomes") ///
    mtitles("Fiscal Balance" "Primary Balance" "Structural Balance") ///
    note("Country and year FE. Clustered SEs at country level. " ///
         "fm\_ideology1: 1=far left, 6=far right.")

*--- Table 10: Gender + ideology additive ---
eststo clear

xtreg balance_gdp female_fm fm_ideology1 $controls_main i.year, fe cluster(country_id)
estimates store genderideo_bal

xtreg primary_balance_gdp female_fm fm_ideology1 $controls_main i.year, fe cluster(country_id)
estimates store genderideo_prim

xtreg structural_balance_gdp female_fm fm_ideology1 $controls_main i.year, fe cluster(country_id)
estimates store genderideo_struc

esttab genderideo_bal genderideo_prim genderideo_struc ///
    using "${outpath}table3b_gender_ideology.tex", replace ///
    keep(female_fm fm_ideology1 $controls_main) ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 10: Gender and Ideology -- Additive Effects on Fiscal Outcomes") ///
    mtitles("Fiscal Balance" "Primary Balance" "Structural Balance") ///
    note("Country and year FE. Clustered SEs at country level.")

*--- Table 11: Gender x ideology interaction ---
eststo clear

xtreg balance_gdp female_fm fm_ideology1 ///
    c.female_fm#c.fm_ideology1 $controls_main i.year, fe cluster(country_id)
estimates store interact_bal

xtreg primary_balance_gdp female_fm fm_ideology1 ///
    c.female_fm#c.fm_ideology1 $controls_main i.year, fe cluster(country_id)
estimates store interact_prim

xtreg structural_balance_gdp female_fm fm_ideology1 ///
    c.female_fm#c.fm_ideology1 $controls_main i.year, fe cluster(country_id)
estimates store interact_struc

esttab interact_bal interact_prim interact_struc ///
    using "${outpath}table3c_gender_ideology_interaction.tex", replace ///
    keep(female_fm fm_ideology1 c.female_fm#c.fm_ideology1 $controls_main) ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 11: Gender x Ideology Interaction -- Fiscal Outcomes") ///
    mtitles("Fiscal Balance" "Primary Balance" "Structural Balance") ///
    note("Country and year FE. Clustered SEs at country level.")

*--- Table 12: Women FMs only subsample ---
eststo clear

xtreg balance_gdp fm_ideology1 $controls_main i.year ///
    if female_fm == 1, fe cluster(country_id)
estimates store wfm_bal

xtreg primary_balance_gdp fm_ideology1 $controls_main i.year ///
    if female_fm == 1, fe cluster(country_id)
estimates store wfm_prim

xtreg structural_balance_gdp fm_ideology1 $controls_main i.year ///
    if female_fm == 1, fe cluster(country_id)
estimates store wfm_struc

esttab wfm_bal wfm_prim wfm_struc ///
    using "${outpath}table3d_women_ideology_only.tex", replace ///
    keep(fm_ideology1 $controls_main) ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 12: Ideology and Fiscal Outcomes -- Women FMs Only") ///
    mtitles("Fiscal Balance" "Primary Balance" "Structural Balance") ///
    note("Sample: country-years with women Finance Ministers only. " ///
         "Country and year FE. Clustered SEs at country level.")

di "=== Gender-ideology tables complete ==="

*-----------------------------------------------------------------
* 6. IV MAIN RESULTS (Tables 13-14)
*-----------------------------------------------------------------

*--- Table 13: Just-identified IV (IV1 only) ---
eststo clear

ivreghdfe balance_gdp $controls_main ///
    (female_fm = iv10_relative_cabinet), ///
    absorb(region year) cluster(country_id)
estimates store iv_bal
estadd scalar kpf = e(widstat)

ivreghdfe primary_balance_gdp $controls_main ///
    (female_fm = iv10_relative_cabinet), ///
    absorb(region year) cluster(country_id)
estimates store iv_prim
estadd scalar kpf = e(widstat)

ivreghdfe structural_balance_gdp $controls_main ///
    (female_fm = iv10_relative_cabinet), ///
    absorb(region year) cluster(country_id)
estimates store iv_struc
estadd scalar kpf = e(widstat)

esttab iv_bal iv_prim iv_struc ///
    using "${outpath}table4_iv_main.tex", replace ///
    keep(female_fm $controls_main) ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 13: Just-Identified IV -- IV1 Only") ///
    mtitles("Fiscal Balance" "Primary Balance" "Structural Balance") ///
    scalars("kpf Kleibergen-Paap F-stat" "N Observations") ///
    note("IV: Cabinet women relative to region-decade mean (IV1). " ///
         "Region and year FE absorbed. Clustered SEs at country level.")

*--- Table 14: Overidentified IV (IV1 + FM Age) ---
eststo clear

ivreghdfe balance_gdp $controls_main ///
    (female_fm = iv10_relative_cabinet fm_age), ///
    absorb(region year) cluster(country_id)
estimates store ivov_bal
estadd scalar kpf = e(widstat)
estadd scalar jp  = e(jp), replace

ivreghdfe primary_balance_gdp $controls_main ///
    (female_fm = iv10_relative_cabinet fm_age), ///
    absorb(region year) cluster(country_id)
estimates store ivov_prim
estadd scalar kpf = e(widstat), replace
estadd scalar jp  = e(jp), replace

ivreghdfe structural_balance_gdp $controls_main ///
    (female_fm = iv10_relative_cabinet fm_age), ///
    absorb(region year) cluster(country_id)
estimates store ivov_struc
estadd scalar kpf = e(widstat), replace
estadd scalar jp  = e(jp), replace

esttab ivov_bal ivov_prim ivov_struc ///
    using "${outpath}table4_iv_overid.tex", replace ///
    keep(female_fm $controls_main) ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 14: Overidentified IV -- IV1 and FM Age") ///
    mtitles("Fiscal Balance" "Primary Balance" "Structural Balance") ///
    scalars("kpf Kleibergen-Paap F-stat" "jp Hansen J p-value" "N Observations") ///
    note("IVs: IV10 and FM Age. Region and year FE. Clustered SEs at country level. " ///
         "Hansen J p > 0.10 = instruments jointly valid.")

di "=== IV main results complete ==="

*-----------------------------------------------------------------
* 7. ROBUSTNESS CHECKS
*-----------------------------------------------------------------

*--- Country total for single-FM restriction ---
capture drop tot_fem
bysort country_id: egen tot_fem = total(female_fm)

*--- Block 1: Sample restrictions ---
eststo clear

xtreg balance_gdp female_fm $controls_main i.year ///
    if region != "Middle East and North Africa", fe cluster(country_id)
estimates store r1_bal

xtreg primary_balance_gdp female_fm $controls_main i.year ///
    if region != "Middle East and North Africa", fe cluster(country_id)
estimates store r1_prim

xtreg balance_gdp female_fm $controls_main i.year ///
    if year >= 2000, fe cluster(country_id)
estimates store r2_bal

xtreg primary_balance_gdp female_fm $controls_main i.year ///
    if year >= 2000, fe cluster(country_id)
estimates store r2_prim

xtreg balance_gdp female_fm $controls_main i.year ///
    if year < 2020, fe cluster(country_id)
estimates store r3_bal

xtreg primary_balance_gdp female_fm $controls_main i.year ///
    if year < 2020, fe cluster(country_id)
estimates store r3_prim

xtreg balance_gdp female_fm $controls_main i.year ///
    if tot_fem != 1, fe cluster(country_id)
estimates store r4_bal

xtreg primary_balance_gdp female_fm $controls_main i.year ///
    if tot_fem != 1, fe cluster(country_id)
estimates store r4_prim

esttab r1_bal r2_bal r3_bal r4_bal ///
    using "${outpath}robustness_block1_bal.tex", replace ///
    keep(female_fm) ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness Block 1: Sample Restrictions -- Fiscal Balance") ///
    mtitles("Drop MENA" "2000-2023" "Drop COVID" "Drop Single-FM") ///
    note("Country and year FE. Clustered SEs at country level.")

esttab r1_prim r2_prim r3_prim r4_prim ///
    using "${outpath}robustness_block1_prim.tex", replace ///
    keep(female_fm) ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness Block 1: Sample Restrictions -- Primary Balance") ///
    mtitles("Drop MENA" "2000-2023" "Drop COVID" "Drop Single-FM") ///
    note("Country and year FE. Clustered SEs at country level.")

*--- Block 2: Specification checks ---
eststo clear

xtreg balance_gdp female_fm ///
    L.gdp_growth L.inflation L.gross_debt_gdp ///
    L.democracy L.hog_ideology_num_redux i.year, ///
    fe cluster(country_id)
estimates store r6_bal

xtreg primary_balance_gdp female_fm ///
    L.gdp_growth L.inflation L.gross_debt_gdp ///
    L.democracy L.hog_ideology_num_redux i.year, ///
    fe cluster(country_id)
estimates store r6_prim

reghdfe balance_gdp female_fm $controls_main, ///
    absorb(country_id region_num#year) cluster(country_id)
estimates store r7_bal

reghdfe primary_balance_gdp female_fm $controls_main, ///
    absorb(country_id region_num#year) cluster(country_id)
estimates store r7_prim

esttab r6_bal r7_bal ///
    using "${outpath}robustness_block2_bal.tex", replace ///
    keep(female_fm) ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness Block 2: Specification Checks -- Fiscal Balance") ///
    mtitles("Lagged Controls" "Region x Year FE") ///
    note("Country FE in all specs. Clustered SEs at country level.")

esttab r6_prim r7_prim ///
    using "${outpath}robustness_block2_prim.tex", replace ///
    keep(female_fm) ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness Block 2: Specification Checks -- Primary Balance") ///
    mtitles("Lagged Controls" "Region x Year FE") ///
    note("Country FE in all specs. Clustered SEs at country level.")

*--- Block 3: Alternative treatment definitions ---
eststo clear

xtreg balance_gdp cum_female_fm $controls_main i.year, fe cluster(country_id)
estimates store r8_bal

xtreg primary_balance_gdp cum_female_fm $controls_main i.year, fe cluster(country_id)
estimates store r8_prim

xtreg balance_gdp female_fm female_fm_left female_fm_right ///
    $controls_main i.year, fe cluster(country_id)
estimates store r9_bal

xtreg primary_balance_gdp female_fm female_fm_left female_fm_right ///
    $controls_main i.year, fe cluster(country_id)
estimates store r9_prim

esttab r8_bal r8_prim ///
    using "${outpath}robustness_block3_cumulative.tex", replace ///
    keep(cum_female_fm) ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness Block 3a: Cumulative Treatment") ///
    mtitles("Fiscal Balance" "Primary Balance") ///
    note("Country and year FE. Clustered SEs at country level.")

esttab r9_bal r9_prim ///
    using "${outpath}robustness_block3_ideology.tex", replace ///
    keep(female_fm female_fm_left female_fm_right) ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness Block 3b: Ideology-Split Treatment") ///
    mtitles("Fiscal Balance" "Primary Balance") ///
    note("Baseline = centre ideology women FM. " ///
         "Country and year FE. Clustered SEs at country level.")

*--- Block 4: Placebo test ---
eststo clear

xtreg balance_gdp placebo_fm $controls_main i.year, fe cluster(country_id)
estimates store r10_bal

xtreg primary_balance_gdp placebo_fm $controls_main i.year, fe cluster(country_id)
estimates store r10_prim

esttab r10_bal r10_prim ///
    using "${outpath}robustness_block4_placebo.tex", replace ///
    keep(placebo_fm) ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness Block 4: Placebo Test") ///
    mtitles("Fiscal Balance" "Primary Balance") ///
    note("Placebo: randomly reassigned treatment within country (seed 1234). " ///
         "Near-zero coefficients confirm no spurious correlation. " ///
         "Country and year FE. Clustered SEs at country level.")

di "=== Robustness complete ==="

*-----------------------------------------------------------------
* 8. FIGURE 1: Female FM share by year
*-----------------------------------------------------------------

preserve
collapse (mean) share_female_fm = female_fm, by(year)
replace share_female_fm = share_female_fm * 100

twoway line share_female_fm year, ///
    sort ///
    lcolor(teal) lwidth(medthick) ///
    ytitle("Share of female Finance Ministers (%)") ///
    xtitle("Year") ///
    title("Female Finance Ministers Over Time, 1990--2023") ///
    note("Source: WhoGov; author's calculations.") ///
    xlabel(1990(5)2023, angle(45)) ///
    ylabel(0(5)20) ///
    yline(6.3, lpattern(dash) lcolor(gray))

graph export "${outpath}fig1_femfm_trend.pdf", replace
restore

*-----------------------------------------------------------------
* 9. FIGURE 2: Regional distribution bar chart
*-----------------------------------------------------------------

preserve
collapse (mean) share = female_fm (count) n = female_fm, by(region)
replace share = share * 100

graph hbar share, over(region, sort(share) label(labsize(small))) ///
    bar(1, color(teal)) ///
    yline(6.3, lpattern(dash) lcolor(gray)) ///
    ytitle("Share of female Finance Ministers (%)") ///
    title("Women Finance Ministers by World Region, 1990--2023") ///
    note("Dashed line = global average (6.3%). Source: WhoGov; author's calculations.")

graph export "${outpath}fig_region_femfm.pdf", replace
restore

di "=== Figures complete ==="
di "=== ALL REPLICATION COMPLETE ==="
