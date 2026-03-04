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

sort code_num yr

eststo a1: xtreg gdppc_g c.ihs_cf##c.gain aid inflation l.gdppc_g pol private_flows cap_form sch budget m2 i.yr, fe vce(cluster code_num)
estadd local cntl "\ding{51}": a1
estadd local fe  "\ding{51}": a1

eststo a2: xtreg gdppc_g c.l.ihs_cf##c.l.gain aid inflation l.gdppc_g pol private_flows cap_form sch budget m2 i.yr, fe vce(cluster code_num)
estadd local cntl "\ding{51}": a2
estadd local fe  "\ding{51}": a2

eststo a3: xtreg gdppc_g c.l5.ihs_cf##c.l5.gain aid inflation l.gdppc_g pol private_flows cap_form sch budget m2 i.yr, fe vce(cluster code_num)
estadd local cntl "\ding{51}": a3
estadd local fe  "\ding{51}": a3

eststo a4: xtreg gdppc_g c.l10.ihs_cf##c.l10.gain aid inflation l.gdppc_g pol private_flows cap_form sch budget m2 i.yr, fe vce(cluster code_num)
estadd local cntl "\ding{51}": a4
estadd local fe  "\ding{51}": a4

esttab a1 a2 a3 a4 using "Output\Tables\output int.tex", replace ///
    cells(b(star fmt(3)) se(fmt(3))) label booktabs style(tex) ///
    keep(*ihs_cf* *gain*) ///  <-- Wildcard to keep main variables
    coeflabel(L.ihs_cf "Lagged IHS Climate Finance (L1)" ///
              L5.ihs_cf "Lagged IHS Climate Finance (L5)" ///
              L10.ihs_cf "Lagged IHS Climate Finance (L10)" ///
              ihs_cf "IHS Climate Finance" ///
              gain "ND-GAIN Index" ///
              L.gain "Lagged ND-GAIN Index (L1)" ///
              L5.gain "Lagged ND-GAIN Index (L5)" ///
              L10.gain "Lagged ND-GAIN Index (L10)" ///
			 c.ihs_cf#c.gain "Interaction" ///
			 c.L.ihs_cf#c.L.gain "Lagged Interaction (L1)" ///
			 c.l5.ihs_cf#c.l5.ihs_cf "Lagged Interaction (L5)" ///
			 c.l10.ihs_cf#c.l10.ihs_cf "Lagged Interaction (L10)") /// 
    stats(cntl fe N, fmt(%s %s 0) labels("Controls" "FE" "Observations")) ///
    nomtitles collabels(none)

/* Keep in Results
	xtreg gdppc_g c.l5.ihs_cum_cf##c.l5.gain aid inflation l.gdppc_g pol private_flows cap_form sch budget m2 i.yr, fe vce(cluster code_num)
