set more off
cd "C:\Users\antho\OneDrive\Climate Finance"
use "Output\Data\cf_data_v4.dta", clear
*Drawing from Mishra

*CHANGE IN THIS VERSION - NOT ONLY DAC DONORS, REMOVED COMMITMENTS TO COMPARE

*CF -> Infant Mortality
gen ln_inf_mort = ln(inf_mort)
gen ln_gdppc = ln(gdp/population)
gen ln_pop = ln(population)
gen ln_health_d = ln(health_aid_d+1)
gen ln_fert = ln(fert)
gen ln_health_pc = ln(health_aid_d/population)

encode code, gen(code_num)
xtset code_num yr

gen ihs_cf_pc = asinh(Financing/population)

sort code_num yr
bysort code_num (yr): gen c_cf = sum(Financing)/population
gen ihs_c_cf = asinh(c_cf)

* ----------------------------------------------------------------------------
* UNEMPLOYMENT INTERACTIONS: CHECKMARKS AND LAG NOTATION
* ----------------------------------------------------------------------------
estimates clear

label variable ihs_cf "IHS CFPC"
label variable ihs_c_cf "IHS Cumulative CFPC"
label variable gain "ND-GAIN"

* 3. Random Effects (Current Flow Interaction)
eststo a3: xtreg ln_inf_mort c.ihs_cf##c.gain L.ln_health_pc L.ln_inf_mort L.ln_gdppc L.ln_pop L.ln_fert war hiv, vce(cluster code_num)
estadd local ctrl "\ding{51}" : a3
estadd local fe   "\ding{51}" : a3

* 4. Random Effects (Cumulative Interaction)
eststo a35: xtreg ln_inf_mort c.ihs_c_cf##c.gain L.ln_health_pc L.ln_inf_mort L.ln_gdppc L.ln_pop L.ln_fert war hiv, vce(cluster code_num)
estadd local ctrl "\ding{51}" : a35
estadd local fe   "\ding{51}" : a35

* 5. Random Effects (Lagged Interactions)
eststo a4: xtreg ln_inf_mort c.L.ihs_cf##c.L.gain L.ln_health_pc L.ln_inf_mort L.ln_gdppc L.ln_pop L.ln_fert war hiv, vce(cluster code_num)
estadd local ctrl "\ding{51}" : a4
estadd local fe   "\ding{51}" : a4

eststo a5: xtreg ln_inf_mort c.L5.ihs_cf##c.L5.gain L.ln_health_pc L.ln_inf_mort L.ln_gdppc L.ln_pop L.ln_fert war hiv, vce(cluster code_num)
estadd local ctrl "\ding{51}" : a5
estadd local fe   "\ding{51}" : a5

eststo a6: xtreg ln_inf_mort c.L10.ihs_cf##c.L10.gain L.ln_health_pc L.ln_inf_mort L.ln_gdppc L.ln_pop L.ln_fert war hiv, vce(cluster code_num)
estadd local ctrl "\ding{51}" : a6
estadd local fe   "\ding{51}" : a6

* ----------------------------------------------------------------------------
* TABLE EXPORT (LaTeX)
* ----------------------------------------------------------------------------

esttab a3 a35 a4 a5 a6 using "Output\Tables\inf mort int lag.tex", replace ///
    fragment booktabs style(tex) label ///
    cells(b(star fmt(3)) se(fmt(3))) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    keep(*ihs_cf* *gain* *#*) ///  
    collabels(none) nomtitles nodepvars noobs ///
    stats(ctrl fe r2_a r2_o N, ///
          fmt(%s %s 3 3 0) ///
          labels("Controls" "Year FE" "Adj. $R^2$" "Overall $R^2$" "Observations")) ///
    prehead("\begin{table}[htbp]\centering \caption{Climate Finance per Capita (CFPC), Adaptation Readiness (ND-GAIN), and Infant Mortality} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{7}{c}} \toprule") ///
    postfoot("\bottomrule \end{tabular} \end{adjustbox} \end{table}")
