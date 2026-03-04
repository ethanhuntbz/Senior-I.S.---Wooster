*Ethan Hunt
*Entity Effects Regression - Capital Formation

*Drawing heavily from Hasen and Tarp 2001 w/ this estimation 


set more off
cd "C:\Users\antho\OneDrive\Climate Finance"
use "Output\Data\cf_data_v4.dta", clear

*GDP Variables
sort code 
by code: gen gdppc = gdp/population
by code: gen i_gdppc = gdppc[1]
bysort code: generate gdppc_g = 100 * (gdppc - gdppc[_n-1]) / gdppc[_n-1]

encode code,gen(code_num)
xtset code_num yr

gen ln_cap_form = ln(cap_form)
*Adjusting cap_form to be millions to match climate finance. 


* -----------------------------
* PANEL A: IHS financing
* -----------------------------
gen ihs_cf = asinh(Financing) // estimates don't vary heavily in r^2 when scaling
eststo b4: reg ln_cap_form ihs_cf , vce(cluster code_num)

eststo b5: reg ln_cap_form ihs_cf gain gain off_flows private_flows inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol, vce(cluster code_num)

eststo b6: xtreg ln_cap_form ihs_cf gain off_flows private_flows inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol i.yr, ///
    fe vce(cluster code_num)

* -------------------------------
* PANEL B: IHS Lag Financing
* -------------------------------

eststo c4: reg ln_cap_form l.ihs_cf , vce(cluster code_num)
estadd local controls "": c4
estadd local fe "": c4


eststo c5: reg ln_cap_form l.ihs_cf gain gain off_flows private_flows inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol, vce(cluster code_num)
estadd local controls "\ding{51}": c5
estadd local fe "": c5

eststo c6: xtreg ln_cap_form l.ihs_cf gain off_flows private_flows inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol i.yr, ///
    fe vce(cluster code_num)
estadd local controls "\ding{51}": c6
estadd local fe "\ding{51}": c6

* -----------------------------
* PANEL C: IHS cumulative financing
* -----------------------------
sort country yr
bysort country (yr): gen c_cf = sum(Financing)
gen ihs_c_cf = asinh(c_cf)

eststo d4: reg ln_cap_form ihs_c_cf gain, vce(cluster code_num)
estadd local controls "": d4
estadd local fe "": d4

eststo d5: reg ln_cap_form ihs_c_cf gain off_flows private_flows fdi_net inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol, ///
     vce(cluster code_num)
estadd local controls "\ding{51}": d5
estadd local fe "": d5

eststo d6: xtreg ln_cap_form ihs_c_cf gain off_flows private_flows fdi_net inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol i.yr, ///
    fe vce(cluster code_num)
estadd local controls "\ding{51}": d6
estadd local fe "\ding{51}": d6


esttab b4 b5 b6 using "Output\Tables\cap form ag short&acc.tex", replace ///
	fragment ar2 ///
    keep(ihs_cf) ///
    coeflabels(ihs_cf "IHS Climate Finance") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
    cells(b(star fmt(3)) se(fmt(3))) ///
    booktabs ///
	collabels(none) ///
	nomtitles nodepvars noobs ///
	prehead("\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Climate Finance and Log Gross Capital Formation} \begin{adjustbox}{max width=\textwidth}  \begin{tabular}{l*{4}{c}} \toprule ") ///

	

esttab d4 d5 d6 using "Output\Tables\cap form ag short&acc.tex", append ///
	fragment ar2 ///
    keep(ihs_c_cf) ///
    coeflabels(ihs_c_cf "IHS Cumulative Climate Finance") ///
    cells(b(star fmt(3)) se(fmt(3))) ///
    booktabs ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	collabels(none) ///
	nomtitles nodepvars nonumbers ///
    stats(r2_a controls fe N, ///
    labels("adj. $ R^2$ ""Controls" "FE" "Observations")) ///
	postfoot("\bottomrule \end{tabular} \end{adjustbox}  \begin{center}  \begin{minipage}{0.6 \textwidth} \footnotesize\footnotesize Climate finance is in mil. 2023 USD and capital formation in 2023 USD. No scale factor was applied variables that were IHS transformed. All regressions include country and year fixed effects (FE). Standard errors clustered at the country level. *, **, *** denote significance at the 10, 5, and 1 percent levels. \end{minipage} \end{center} \end{table}")


label variable ihs_cf "IHS Climate Finance"

esttab c4 c5 c6 using "Output\Tables\cap form ag lag.tex", replace ///
	fragment ar2 label ///
    keep(*ihs_cf*) ///
    cells(b(star fmt(3)) se(fmt(3))) ///
    booktabs ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	collabels(none) ///
	nomtitles nodepvars noobs ///
	   stats(r2_a controls fe N, ///
    labels("adj. $ R^2$ ""Controls" "FE" "Observations")) ///
	prehead("\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Climate Finance and Log Gross Capital Formation} \begin{adjustbox}{max width=\textwidth}  \begin{tabular}{l*{3}{c}} \toprule ") ///
	postfoot("\bottomrule \end{tabular} \end{adjustbox}  \begin{center}  \begin{minipage}{0.6 \textwidth} \footnotesize\footnotesize Climate finance is in mil. 2023 USD and capital formation in 2023 USD. No scale factor was applied variables that were IHS transformed. All regressions include country and year fixed effects (FE). Standard errors clustered at the country level. *, **, *** denote significance at the 10, 5, and 1 percent levels. \end{minipage} \end{center} \end{table}")

	
	
	