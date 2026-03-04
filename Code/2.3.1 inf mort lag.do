set more off
cd "C:\Users\antho\OneDrive\Climate Finance"
use "Output\Data\cf_data_v4.dta", clear

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

label variable ihs_cf "IHS CFPC"
label variable ihs_c_cf "IHS CFPC" 
label variable gain "ND-GAIN"

* ----------------------------------------------------------------------------
* INFANT MORTALITY REGRESSIONS: FLOW, CUMULATIVE, AND MULTIPLE LAGS
* ----------------------------------------------------------------------------
estimates clear

* 1. Basic OLS (Current Flow)
eststo a1: reg ln_inf_mort ihs_cf_pc, vce(cluster code_num)
estadd local ctrl "" : a1
estadd local fix  "" : a1

* 2. OLS with Controls
eststo a2: reg ln_inf_mort ihs_cf_pc L.ln_health_pc L.ln_inf_mort L.ln_gdppc L.ln_pop L.ln_fert war hiv, vce(cluster code_num)
estadd local ctrl "\ding{51}" : a2
estadd local fix  ""  : a2

* 3. Fixed Effects (Current Flow)
eststo a3: xtreg ln_inf_mort ihs_cf_pc L.ln_health_pc L.ln_inf_mort L.ln_gdppc L.ln_pop L.ln_fert war hiv i.yr, fe vce(cluster code_num)
estadd local ctrl "\ding{51}" : a3
estadd local fix  "\ding{51}" : a3

* 4. Fixed Effects (Cumulative Flow)
eststo a4: xtreg ln_inf_mort ihs_c_cf L.ln_health_pc L.ln_inf_mort L.ln_gdppc L.ln_pop L.ln_fert war hiv i.yr, fe vce(cluster code_num)
estadd local ctrl "\ding{51}" : a4
estadd local fix  "\ding{51}" : a4

* 5. Fixed Effects (L1 Lag)
eststo a5: xtreg ln_inf_mort L.ihs_cf_pc L.ln_health_pc L.ln_inf_mort L.ln_gdppc L.ln_pop L.ln_fert war hiv i.yr, fe vce(cluster code_num)
estadd local ctrl "\ding{51}" : a5
estadd local fix  "\ding{51}" : a5

* 6. Fixed Effects (L5 Lag)
eststo a6: xtreg ln_inf_mort L5.ihs_cf_pc L.ln_health_pc L.ln_inf_mort L.ln_gdppc L.ln_pop L.ln_fert war hiv i.yr, fe vce(cluster code_num)
estadd local ctrl "\ding{51}" : a6
estadd local fix  "\ding{51}": a6

* 7. Fixed Effects (L10 Lag)
eststo a7: xtreg ln_inf_mort L10.ihs_cf_pc L.ln_health_pc L.ln_inf_mort L.ln_gdppc L.ln_pop L.ln_fert war hiv i.yr, fe vce(cluster code_num)
estadd local ctrl "\ding{51}" : a7
estadd local fix  "\ding{51}" : a7

* ----------------------------------------------------------------------------
* TABLE EXPORT (LaTeX)
* ----------------------------------------------------------------------------

esttab a1 a2 a3 a4 a5 a6 a7 using "Output\Tables\inf mort ag lag.tex", replace ///
    fragment booktabs style(tex) label ///
    cells(b(star fmt(3)) se(fmt(3))) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    keep(*ihs_cf_pc* *ihs_c_cf*) ///
    collabels(none) nomtitles nodepvars noobs ///
    stats(ctrl fix r2_a N, ///
          fmt(%s %s 3 0) ///
          labels("Controls" "Year FE" "Adj. $ R^2$" "Observations")) ///
    prehead("\begin{table}[htbp]\centering \caption{Climate Finance per Capita (CFPC) and Log Infant Mortality} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{7}{c}} \toprule") ///
    postfoot("\bottomrule \end{tabular} \end{adjustbox} \begin{center} \begin{minipage}{0.8\textwidth} \footnotesize \flushleft Climate finance is in mil. 2021 USD and is IHS transformed. Year FE refers to  year fixed effects. The L indicates the number of lagged years. Standard errors clustered at the country level. *, **, *** denote significance at the 10, 5, and 1 percent levels. \end{minipage} \end{center} \end{table}")