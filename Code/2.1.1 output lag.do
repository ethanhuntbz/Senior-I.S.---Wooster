*Ethan Hunt
*Entity Effects Regression - Capital Formation

*Drawing heavily from Hasen and Tarp 2001 w/ this estimation 

set more off
cd "C:\Users\antho\OneDrive\Climate Finance"
use "Output\Data\cf_data_v4.dta", clear

encode code, gen(code_num)
xtset code_num yr

*GDP Variables
sort code 
gen gdppc = gdp/population
by code: gen i_gdppc = gdppc[1]

sort code_num yr
by code_num: gen gdppc_g = 100 * (gdppc - L.gdppc) / L.gdppc

*IHS Transforming Climate Finance (levels) (real 2023 USD)
sort country yr
bysort country (yr): gen cum_cf = sum(Financing)
gen ihs_cum_cf = asinh(cum_cf)
gen ihs_cf = asinh(Financing) 

*Working variable
*Needed to keep esttab output on the same line. 

sort code_num yr
eststo a0: reg gdppc_g ihs_cf, vce(cluster code_num)
estadd local ctrl     "": a0
estadd local fe      "": a0

label variable ihs_cf "IHS Climate Finance"
label variable ihs_cum_cf "IHS Cumulative Climate Finance"

eststo a1: reg gdppc_g ihs_cf aid inflation l.gdppc_g pol private_flows cap_form sch budget m2, vce(cluster code_num)
estadd local ctrl     "\ding{51}": a1
estadd local fe      "": a1

*Had to take out initial gdp because of country fixed effects
eststo a2: xtreg gdppc_g ihs_cf aid inflation l.gdppc_g pol private_flows cap_form sch budget m2 i.yr, fe vce(cluster code_num)
estadd local ctrl "\ding{51}": a2
estadd local fe  "\ding{51}": a2

eststo a25: xtreg gdppc_g ihs_cum_cf aid inflation l.gdppc_g pol private_flows cap_form sch budget m2 i.yr, fe vce(cluster code_num)
estadd local ctrl "\ding{51}": a25
estadd local fe  "\ding{51}": a25

eststo a3: xtreg gdppc_g l.ihs_cf aid inflation l.gdppc_g pol private_flows cap_form sch budget m2 i.yr, fe vce(cluster code_num)
estadd local ctrl "\ding{51}": a3
estadd local fe  "\ding{51}": a3

eststo a4: xtreg gdppc_g l5.ihs_cf aid inflation l.gdppc_g pol private_flows cap_form sch budget m2 i.yr, fe vce(cluster code_num)
estadd local ctrl "\ding{51}": a4
estadd local fe  "\ding{51}": a4

eststo a5: xtreg gdppc_g l10.ihs_cf aid inflation l.gdppc_g pol private_flows cap_form sch budget m2 i.yr, fe vce(cluster code_num)	
estadd local ctrl "\ding{51}": a5
estadd local fe  "\ding{51}": a5

esttab a0 a1 a2 a25 a3 a4 a5 using "Output\Tables\output lag.tex", replace ///
	fragment unstack label ///
	starlevels(* 0.10 ** 0.05 *** 0.01) ///
    cells(b(star fmt(3)) se(fmt(3))) ///
	keep(*ihs_cf* *ihs_cum_cf*) ///
    booktabs ///
	collabels(none) ///
	nomtitles nodepvars noobs ///
	 stats(r2_a ctrl fe N, ///
	 fmt(3 %s %s 0) ///
    labels("adj. $ R^2$ ""Controls" "FE" "Observations")) ///
	prehead("\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{IHS Climate Finance and GDP per Capita Growth} \begin{adjustbox}{max width=\textwidth}  \begin{tabular}{l*{7}{c}} \toprule") ///
postfoot("\bottomrule \end{tabular} \end{adjustbox}  \begin{center}\begin{minipage}{0.98\textwidth} \footnotesize \flushleft Climate finance is in mil. 2021 USD and is IHS transformed. The L refers to the number of lags. FE refers to country and year fixed effects. Standard errors clustered at the country level. *, **, *** denote significance at the 10, 5, and 1 percent levels. \end{minipage} \end{center}\end{table}")
	
/*

r2_a option note
https://www.statalist.org/forums/forum/general-stata-discussion/general/1461115-is-e-r2_a-the-adjusted-within-r-squared-in-xtreg-fe

Interesting note from the stata forum
Alvaro:
welcome to this forum.
-r- is the abbreviation of -robust- (ie, cluster-robust standard error).
Interestingly, while you can invoke it via -robust- or -vce(cluster clusterid)- in -xtreg- (as both these options do the very same job, that is taking heteroskedasticity and/or autocorrelation into account), in -regress- the -robust- option takes heteroskedasticity only into account, whereas -.vce(cluster clusterid- does the same with autocorrelation of the epsilon