*Ethan Hunt
*Poverty - Alvi and Senbeta 
set more off

*Pov in 2021 PPP USD. CF in 2021 current USD

set more off
cd "C:\Users\antho\OneDrive\Climate Finance"

pip, povline(2.15) clear
keep if (welfare_type == 2) & (reporting_level == "national") // Welfare - income
keep country_code year headcount poverty_gap poverty_severity
rename country_code code
rename year yr
tempfile pov
save `pov'

use "Output\Data\cf_data_v3_2021.dta", clear
merge 1:1 code yr using `pov'
keep if _merge == 3

encode code, gen(code_num)
xtset code_num yr

gen ln_gdp = ln(gdp/population)
gen ln_gini = ln(gini)
gen ln_trade = ln(net_trade_ppt)

*Fill with null value from Polity5 Democ
*-88 transitioning government status
replace democ = . if democ == -88

/*
gen ln_Financing = asinh(Financing)
replace headcount = asinh(headcount)
replace poverty_gap = asinh(poverty_gap)
replace poverty_severity = asinh(poverty_severity)
*/

label variable ln_Financing "IHS Climate Finance"

*slightly different - use all officials flow and not just concessional 

eststo a1: reg headcount ln_Financing aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ, vce(cluster code_num)
estadd local ctrl     "\ding{51}" : a1
estadd local code     "" : a1

eststo a2: xtreg headcount ln_Financing aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ i.yr, fe vce(cluster code_num)
estadd local ctrl     "\ding{51}" : a2
estadd local code     "\ding{51}" : a2

eststo b1: reg poverty_gap ln_Financing aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ, vce(cluster code_num)
estadd local ctrl     "\ding{51}" : b1
estadd local code     "" : b1

eststo b2: xtreg poverty_gap ln_Financing aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ i.yr, fe vce(cluster code_num)
estadd local ctrl     "\ding{51}" : b2
estadd local code     "\ding{51}" : b2

eststo c1: reg poverty_severity ln_Financing aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ, vce(cluster code_num)
estadd local ctrl     "\ding{51}" : c1
estadd local code     "" : c1

eststo c2: xtreg poverty_severity ln_Financing aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ i.yr, fe vce(cluster code_num)
estadd local ctrl     "\ding{51}" : c2
estadd local code     "\ding{51}" : c2

esttab a1 a2 b1 b2 c1 c2 using "Output\Tables\pov short.tex", replace ///
	title("Short Run Effect of Climate Finance on Poverty") ///
    cells(b(star fmt(3)) se(fmt(3))) label booktabs style(tex) ///
    collabels(none) keep(ln_Financing) numbers nodepvars ///
    star(* 0.10 ** 0.05 *** 0.01) starlevels(* 0.10 ** 0.05 *** 0.01) ///
    stats(ctrl code N, ///
          fmt(%s %s 0) ///
          labels("Controls" "FE" "Observations")) ///
    gaps nonotes nomtitles se(%4.2f) b(%4.2f) ///
    postfoot("\bottomrule \end{tabular} \begin{center} \begin{minipage}{0.87\textwidth} \footnotesize \flushleft Climate finance is in mil. 2021 USD and is IHS transformed. FE refers to country and year fixed effects. Standard errors clustered at the country level. *, **, *** denote significance at the 10, 5, and 1 percent levels. \end{minipage} \end{center} \end{table}")

estimate clear 

sort code_num yr
bysort code_num (yr): gen cum_cf = sum(Financing)
gen ihs_cum_cf = ln(cum_cf+sqrt(cum_cf^2 + 1))

label variable ihs_cum_cf "IHS Cumulative Climate Finance"

eststo a1: reg headcount ihs_cum_cf aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ, vce(cluster code_num)
estadd local ctrl     "\ding{51}" : a1
estadd local code     "" : a1

eststo a2: xtreg headcount ihs_cum_cf aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ i.yr, fe vce(cluster code_num)
estadd local ctrl     "\ding{51}" : a2
estadd local code     "\ding{51}" : a2

eststo b1: reg poverty_gap ihs_cum_cf aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ, vce(cluster code_num)
estadd local ctrl     "\ding{51}" : b1
estadd local code     "" : b1

eststo b2: xtreg poverty_gap ihs_cum_cf aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ i.yr, fe vce(cluster code_num)
estadd local ctrl     "\ding{51}" : b2
estadd local code     "\ding{51}" : b2

eststo c1: reg poverty_severity ihs_cum_cf aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ, vce(cluster code_num)
estadd local ctrl     "\ding{51}" : c1
estadd local code     "" : c1

eststo c2: xtreg poverty_severity ihs_cum_cf aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ i.yr, fe vce(cluster code_num)
estadd local ctrl     "\ding{51}" : c2
estadd local code     "\ding{51}" : c2
	
esttab a1 a2 b1 b2 c1 c2 using "Output\Tables\pov acc.tex", replace ///
	title("Long Run Effect of Climate Finance on Poverty") ///
    cells(b(star fmt(3)) se(fmt(3))) label booktabs style(tex) ///
    collabels(none) keep(ihs_cum_cf) numbers nodepvars ///
    star(* 0.10 ** 0.05 *** 0.01) starlevels(* 0.10 ** 0.05 *** 0.01) ///
    stats(ctrl code N, ///
          fmt(%s %s 0) ///
          labels("Controls" "FE" "Observations")) ///
    gaps nonotes nomtitles se(%4.2f) b(%4.2f) ///
    postfoot("\bottomrule \end{tabular} \begin{center} \begin{minipage}{0.87\textwidth} \footnotesize \flushleft Climate finance is in mil. 2021 USD and is IHS transformed. FE refers to country and year fixed effects. Standard errors clustered at the country level. *, **, *** denote significance at the 10, 5, and 1 percent levels. \end{minipage} \end{center} \end{table}")
	
estimates clear 

eststo d1: reg headcount L.ln_Financing aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ, vce(cluster code_num)
estadd local ctrl "\ding{51}" : d1
estadd local fe   ""          : d1

eststo d2: xtreg headcount L.ln_Financing aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ i.yr, fe vce(cluster code_num)
estadd local ctrl "\ding{51}" : d2
estadd local fe   "\ding{51}" : d2

* Poverty Gap
eststo e1: reg poverty_gap L.ln_Financing aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ, vce(cluster code_num)
estadd local ctrl "\ding{51}" : e1
estadd local fe   ""          : e1

eststo e2: xtreg poverty_gap L.ln_Financing aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ i.yr, fe vce(cluster code_num)
estadd local ctrl "\ding{51}" : e2
estadd local fe   "\ding{51}" : e2

* Squared Gap
eststo f1: reg poverty_severity L.ln_Financing aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ, vce(cluster code_num)
estadd local ctrl "\ding{51}" : f1
estadd local fe   ""          : f1

eststo f2: xtreg poverty_severity L.ln_Financing aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ i.yr, fe vce(cluster code_num)
estadd local ctrl "\ding{51}" : f2
estadd local fe   "\ding{51}" : f2

esttab d1 d2 e1 e2 f1 f2 using"Output\Tables\pov lag.tex", replace ///
    title("One-Year Lagged Effect of Climate Finance on Poverty") ///
    cells(b(star fmt(3)) se(fmt(3))) label booktabs style(tex) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
    keep(L.ln_Financing) ///
    coeflabels(L.ln_Financing "IHS Climate Finance") ///
    stats(ctrl fe N, fmt(%s %s 0) labels("Controls" "FE" "Observations")) ///
    gaps nonotes nomtitles collabels(none) nodepvars numbers ///
    posthead("\midrule Dependent Variable & \multicolumn{2}{c}{Headcount} & \multicolumn{2}{c}{Poverty Gap} & \multicolumn{2}{c}{Squared Gap} \\ \cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7}") ///
    postfoot("\bottomrule \end{tabular} \begin{center} \begin{minipage}{0.8\textwidth} \footnotesize \flushleft Climate finance is in mil. 2021 USD and is IHS transformed. FE refers to country and year fixed effects. Standard errors clustered at the country level. *, **, *** denote significance at the 10, 5, and 1 percent levels. \end{minipage} \end{center} \end{table}")

