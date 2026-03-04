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
label variable ihs_c_cf "IHS Cumumulative CF"

eststo a1: reg ln_unemp_15_64 ihs_cf
estadd local ctrl "": a1
estadd local fe "": a1

eststo a2: reg ln_unemp_15_64 ihs_cf cap_gdp epl cov_brgn coord replacement almp_unemp lti tfp tot, vce(cluster code_num)
estadd local ctrl "\ding{51}": a2
estadd local fe "": a2

eststo a3: xtreg ln_unemp_15_64 ihs_cf cap_gdp epl cov_brgn coord replacement almp_unemp lti tfp tot i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}": a3
estadd local fe "\ding{51}": a3

eststo a35: xtreg ln_unemp_15_64 ihs_c_cf cap_gdp epl cov_brgn coord replacement almp_unemp lti tfp tot i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}": a35
estadd local fe "\ding{51}": a35

eststo a4: xtreg ln_unemp_15_64 l.ihs_cf cap_gdp epl cov_brgn coord replacement almp_unemp lti tfp tot i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}": a4
estadd local fe "\ding{51}": a4

eststo a5: xtreg ln_unemp_15_64 l5.ihs_cf cap_gdp epl cov_brgn coord replacement almp_unemp lti tfp tot i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}": a5
estadd local fe "\ding{51}": a5

eststo a6: xtreg ln_unemp_15_64 l10.ihs_cf cap_gdp epl cov_brgn coord replacement almp_unemp lti tfp tot i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}": a6
estadd local fe "\ding{51}": a6

esttab a1 a2 a3 a35 a4 a5 a6 using "Output\Tables\unemp lag.tex", replace ///
	fragment unstack label ///
	cells(b(star fmt(3)) se(fmt(3))) ///
starlevels(* 0.10 ** 0.05 *** 0.01) ///
	keep(*ihs_cf* *ihs_c_cf*) ///
    booktabs ///
	collabels(none) ///
	nomtitles nodepvars noobs ///
	 stats(ctrl fe r2_a r2_o N, ///
	 fmt(%s %s 3 3 0) ///
    labels("Controls" "FE" "Adj. $ R^2$" "Overall $ R^2$" "Observations")) ///
	prehead("\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Climate Finance (CF) and Log Unemployment Rate} \begin{adjustbox}{max width=\textwidth}  \begin{tabular}{l*{7}{c}} \toprule") ///
    postfoot("\bottomrule \end{tabular} \end{adjustbox} \begin{center} \begin{minipage}{0.85\textwidth} \footnotesize \flushleft Climate finance is in mil. 2021 USD and is IHS transformed. The L indicates the number of lagged years. All,15+ indicates all workers regardless of gender 15 years or older. FE are year fixed effects. Standard errors clustered at the country level. *, **, *** denote significance at the 10, 5, and 1 percent levels. \end{minipage} \end{center} \end{table}")
