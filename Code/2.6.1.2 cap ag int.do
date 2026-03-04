*Ethan Hunt
*Entity Effects Regression - Capital Formation

*Drawing heavily from Hasen and Tarp 2001 w/ this estimation 


set more off
cd "C:\Users\antho\OneDrive\Climate Finance"
use "Output\Data\cf_data_v4.dta", clear

*GDP Variables
sort code 
by code: gen gdppc = gdp/population
by code: gen i_gdppc = ln(gdppc[1])
bysort code: generate gdppc_g = 100 * (gdppc - gdppc[_n-1]) / gdppc[_n-1]

encode code,gen(code_num)
xtset code_num yr


gen ln_cap_form = ln(cap_form)
*Adjusting cap_form to be millions to match climate finance. 

*INITIAL GDP NOT INCLUDED SINCE OMITTED B/C NO CHANGE

gen ihs_cf = asinh(Financing) 
sort country yr
bysort country (yr): gen c_cf = sum(Financing)
gen ihs_c_cf = asinh(c_cf)

estimates clear 
sort code_num yr

label variable ihs_cf "Climate Finance (IHS)"
label variable ihs_c_cf "Cumulative Climate Finance (IHS)"
label variable gain "ND-GAIN"

* ---------------------------------------------------------
* RE-ESTIMATING INTERACTION MODELS (b6, c6, d6)
* ---------------------------------------------------------

* PANEL A: Current Flow Interaction
eststo b6: xtreg ln_cap_form c.ihs_cf##c.gain off_flows private_flows inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol i.yr, ///
    fe vce(cluster code_num)
estadd local controls "\ding{51}": b6
estadd local fe "\ding{51}": b6

* PANEL B: Lagged Flow Interaction
* Note: Interacting the lagged finance with lagged GAIN for consistency
eststo c6: xtreg ln_cap_form c.L.ihs_cf##c.L.gain off_flows private_flows inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol i.yr, ///
    fe vce(cluster code_num)
estadd local controls "\ding{51}": c6
estadd local fe "\ding{51}": c6

* PANEL C: Cumulative Finance Interaction
eststo d6: xtreg ln_cap_form c.ihs_c_cf##c.gain off_flows private_flows fdi_net inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol i.yr, ///
    fe vce(cluster code_num)
estadd local controls "\ding{51}": d6
estadd local fe "\ding{51}": d6

* ---------------------------------------------------------
* EXPORTING COMBINED TABLE
* ---------------------------------------------------------

esttab b6 c6 d6 using "Output\Tables\cap form gross int lag", replace ///
    fragment ar2 booktabs style(tex) label ///
	star(* 0.10 ** 0.05 *** 0.01) ////
    cells(b(star fmt(3)) se(fmt(3))) ///
    keep(*ihs_cf* *ihs_c_cf* *gain*) ///  <-- Keeps levels, lags, and interactions
    stats(r2_a controls fe N, labels("adj. $ R^2$" "Controls" "FE" "Observations")) ///
    nomtitles collabels(none) nodepvars ///
    prehead("\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Climate Finance, Adaptation Readiness (ND-GAIN), and Log Gross Capital Formation} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{3}{c}} \toprule") ///
    postfoot("\bottomrule \end{tabular} \end{adjustbox} \begin{center} \begin{minipage}{0.83\textwidth} \footnotesize \flushleft Climate finance is in mil. 2023 USD and is IHS transformed. All regressions include country and year fixed effects (FE). Standard errors clustered at the country level. *, **, *** denote significance at the 10, 5, and 1 percent levels. \end{minipage} \end{center} \end{table}")
