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

*Transformations of Key IVs
gen ln_cap_gov = ln(cap_form_gov)
gen ln_cap_priv = ln(cap_form_priv)
*Apply IHS - has 0s - scale w/ R^2 as suggested by Aihounton & Henningsen (2019)
gen ihs_cap_ppp = asinh(cap_form_ppp) // Highest is 0.0094 for a6

*Adjusting scale of DV - all in constant prices as a % of GDP
*gdp is in current USD; I keep it small to see coefficients better
replace cap_form_gov = cap_form_gov*gdp
replace cap_form_priv = cap_form_priv*gdp
replace cap_form_ppp = cap_form_ppp*gdp
	
* -----------------------------
* PANEL A: IHS financing
* -----------------------------
gen ihs_cf = asinh(Financing) // estimates don't vary heavily in r^2 when scaling


eststo b2: xtreg ln_cap_gov ihs_cf off_flows gain fdi_net inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol i.yr, ///
    fe vce(cluster code_num)


eststo b4: xtreg ln_cap_priv ihs_cf off_flows gain fdi_net inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol i.yr, ///
    fe vce(cluster code_num)

eststo b6: xtreg ihs_cap_ppp ihs_cf off_flows gain fdi_net inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol i.yr, ///
    fe vce(cluster code_num)

* -----------------------------
* PANEL B: IHS cumulative financing
* -----------------------------
bysort country (yr): gen c_cf = sum(Financing)
gen ihs_c_cf = asinh(c_cf)

eststo d2: xtreg ln_cap_gov ihs_c_cf off_flows gain fdi_net inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol i.yr, ///
    fe vce(cluster code_num)

eststo d4: xtreg ln_cap_priv ihs_c_cf off_flows gain fdi_net inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol i.yr, ///
    fe vce(cluster code_num)


eststo d6: xtreg ihs_cap_ppp ihs_c_cf off_flows gain fdi_net inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol i.yr, ///
    fe vce(cluster code_num)


* -----------------------------
* Panel C: One-year lag
* -----------------------------

sort code_num yr

eststo e2: xtreg ln_cap_gov L.ihs_cf off_flows gain fdi_net inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol i.yr, ///
    fe vce(cluster code_num)
estadd local controls "\ding{51}": e2
estadd local fe "\ding{51}": e2

eststo e4: xtreg ln_cap_priv L.ihs_cf off_flows gain fdi_net inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol i.yr, ///
    fe vce(cluster code_num)
estadd local controls "\ding{51}": e4
estadd local fe "\ding{51}": e4

eststo e6: xtreg ihs_cap_ppp L.ihs_cf off_flows gain fdi_net inflation ///
    net_trade_ppt gdppc_g sch credit_ps population pol i.yr, ///
    fe vce(cluster code_num)
estadd local controls "\ding{51}": e6
estadd local fe "\ding{51}": e6
	
* -----------------------------
* Standard Output
* -----------------------------

esttab b2 b4 b6 using "Output\Tables\cap form disag.tex", replace ///
	fragment ar2 ///
    keep(ihs_cf) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
    coeflabels(ihs_cf "IHS Climate Finance") ///
    cells(b(star fmt(3)) se(fmt(3))) ///
    booktabs ///
	collabels(none) ///
	mtitles("Public (Log)" "Private (Log)" "PPPs (IHS)") ///
	noobs nodepvars ///
	prehead("\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Capital Formation in the Public Sector, Private Sector, and Public-Private Partnerships (PPPs)} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{3}{c}} \toprule") 

	
esttab d2 d4 d6 using "Output\Tables\cap form disag.tex", append ///
	fragment ar2 ///
    keep(ihs_c_cf) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
    coeflabels(ihs_c_cf "IHS Cumulative Climate Finance") ///
    cells(b(star fmt(3)) se(fmt(3))) ///
    booktabs ///
	collabels(none) ///
	nomtitles noobs nodepvars nonumbers 

label variable ihs_cf "IHS Climate Finance"
esttab e2 e4 e6 using  "Output\Tables\cap form disag.tex", append ///
	fragment ar2 ///
    keep(*ihs_cf*) ///
 	star(* 0.10 ** 0.05 *** 0.01) ///
   coeflabels(L.ihs_cf "L.IHS Climate Finance") ///
    cells(b(star fmt(3)) se(fmt(3))) ///
    booktabs ///
	collabels(none) ///
	nomtitles nodepvars nonumbers ///
    stats(r2_a controls fe N, ///
    labels("adj. $ R^2$ ""Controls" "FE" "Observations")) ///
	postfoot("\bottomrule \end{tabular} \end{adjustbox}  \begin{center}  \begin{minipage}{0.8 \textwidth} \footnotesize\footnotesize Climate finance is in mil. 2023 USD and capital formation in 2023 USD. No scale factor was applied variables that were IHS transformed. The L indicates a lag of one year. All regressions include country and year fixed effects. Standard errors clustered at the country level. *, **, *** denote significance at the 10, 5, and 1 percent levels. \end{minipage} \end{center} \end{table}")


