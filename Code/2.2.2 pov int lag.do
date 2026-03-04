*Ethan Hunt
*Poverty - Alvi and Senbeta 
set more off

*Pov in 2021 PPP USD. CF in 2021 current USD

pip, povline(2.15) clear
keep if (welfare_type == 2) & (reporting_level == "national") // Welfare - income
keep country_code year headcount poverty_gap poverty_severity
rename country_code code
rename year yr
tempfile pov
save `pov'

set more off
cd "C:\Users\antho\OneDrive\Climate Finance"
use "Output\Data\cf_data_v4.dta", clear

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

gen ln_Financing = ln(Financing+sqrt(Financing^2 + 1))

label variable ln_Financing "Climate Financing (IHS)"
label variable gain "ND-GAIN"


*slightly different - use all officials flow and not just concessional 

eststo a1: reg headcount c.l.ln_Financing##c.l.gain aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ, vce(cluster code_num)
estadd local ctrl     "\ding{51}" : a1
estadd local code     "" : a1

eststo a2: xtreg headcount c.l.ln_Financing##c.l.gain aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ i.yr, fe vce(cluster code_num)
estadd local ctrl     "\ding{51}" : a2
estadd local code     "\ding{51}" : a2

eststo b1: reg poverty_gap c.l.ln_Financing##c.l.gain aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ, vce(cluster code_num)
estadd local ctrl     "\ding{51}" : b1
estadd local code     "" : b1

eststo b2: xtreg poverty_gap c.l.ln_Financing##c.l.gain aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ i.yr, fe vce(cluster code_num)
estadd local ctrl     "\ding{51}" : b2
estadd local code     "\ding{51}" : b2

eststo c1: reg poverty_severity c.l.ln_Financing##c.l.gain aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ, vce(cluster code_num)
estadd local ctrl     "\ding{51}" : c1
estadd local code     "" : c1

eststo c2: xtreg poverty_severity c.l.ln_Financing##c.l.gain aid ln_gdp credit_ps ln_gini net_trade_ppt dep democ i.yr, fe vce(cluster code_num)
estadd local ctrl     "\ding{51}" : c2
estadd local code     "\ding{51}" : c2

esttab a1 a2 b1 b2 c1 c2 using "Output\Tables\pov int lag.tex", replace ///
	title("Climate Finance on Poverty with ND-GAIN Interaction and One-Year Lag") ///
    cells(b(star fmt(3)) se(fmt(3))) label booktabs style(tex) ///
	keep(*ln_Financing* *gain*) ///
    collabels(none) numbers nodepvars ///
    star(* 0.10 ** 0.05 *** 0.01) starlevels(* 0.10 ** 0.05 *** 0.01) ///
    stats(ctrl code N, ///
          fmt(%s %s 0) ///
          labels("Controls" "FE" "Observations")) ///
    gaps nonotes nomtitles se(%4.2f) b(%4.2f) ///
    posthead("\midrule Dependent Variable & \multicolumn{2}{c}{Poverty Rate} & \multicolumn{2}{c}{Poverty Gap} & \multicolumn{2}{c}{Squared Gap} \\ \cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7}") postfoot("\bottomrule \end{tabular} \end{table}")


	

