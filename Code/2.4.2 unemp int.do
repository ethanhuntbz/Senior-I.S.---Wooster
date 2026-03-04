set more off
cd "C:\Users\antho\OneDrive\Climate Finance"
use "Output\Data\cf_data_v4.dta", clear

*Ref: Perone 2022
*Both are in 2023 USD unlike the paper
gen cap_gdp = cap_form/gdp
gen ihs_cf = asinh(Financing)
gen ln_unemp_15_64 = ln(unemp_15_64)
sort country yr
bysort country (yr): gen c_cf = sum(Financing)
gen ihs_c_cf = asinh(c_cf)

encode code, gen(code_num)
xtset code_num yr


label variable ihs_cf "IHS CF"
label variable ihs_c_cf "IHS Cumulative CF" 
label variable gain "ND-GAIN"

* ----------------------------------------------------------------------------
* UNEMPLOYMENT INTERACTIONS: CHECKMARKS AND LAG NOTATION
* ----------------------------------------------------------------------------
estimates clear

* 3. Random Effects (Current Flow Interaction)
eststo a3: xtreg ln_unemp_15_64 c.ihs_cf##c.gain cap_gdp epl cov_brgn coord replacement almp_unemp lti tfp tot i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}" : a3
estadd local fe   "\ding{51}" : a3

* 4. Random Effects (Cumulative Interaction)
eststo a35: xtreg ln_unemp_15_64 c.ihs_c_cf##c.gain cap_gdp epl cov_brgn coord replacement almp_unemp lti tfp tot i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}" : a35
estadd local fe   "\ding{51}" : a35

* 5. Random Effects (Lagged Interactions)
eststo a4: xtreg ln_unemp_15_64 c.L.ihs_cf##c.L.gain cap_gdp epl cov_brgn coord replacement almp_unemp lti tfp tot i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}" : a4
estadd local fe   "\ding{51}" : a4

eststo a5: xtreg ln_unemp_15_64 c.L5.ihs_cf##c.L5.gain cap_gdp epl cov_brgn coord replacement almp_unemp lti tfp tot i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}" : a5
estadd local fe   "\ding{51}" : a5


* ----------------------------------------------------------------------------
* TABLE EXPORT (LaTeX)
* ----------------------------------------------------------------------------

esttab a3 a35 a4 a5 using "Output\Tables\unemp int lag.tex", replace ///
    fragment booktabs style(tex) label ///
    cells(b(star fmt(3)) se(fmt(3))) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    keep(*ihs_cf* *ihs_c_cf* *gain* *#*) ///  
    collabels(none) nomtitles nodepvars noobs ///
    stats(ctrl fe r2_o N, ///
          fmt(%s %s 3 0) ///
          labels("Controls" "Year FE" "Overall $ R^2$" "Observations")) ///
    prehead("\begin{table}[htbp]\centering \caption{Climate Finance (CF), Adaptation Readiness (ND-GAIN), and Unemployment} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{7}{c}} \toprule") ///
    postfoot("\bottomrule \end{tabular} \end{adjustbox} \begin{center} \begin{minipage}{0.7\textwidth} \footnotesize \flushleft Climate finance is in mil. 2021 USD and is IHS transformed. The L indicates the number of lagged years. All,15+ indicates all workers regardless of gender 15 years or older. FE are year fixed effects. Standard errors clustered at the country level. *, **, *** denote significance at the 10, 5, and 1 percent levels. \end{minipage} \end{center} \end{table}")