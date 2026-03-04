set more off
cd "C:\Users\antho\OneDrive\Climate Finance"
use "Output\Data\cf_data_v4.dta", clear
*Drawing from Mishra 

encode code, gen(code_num)
xtset code_num yr

sort code_num yr
bysort code_num (yr): gen cum_cf = sum(Financing)
gen ihs_cum_cf = asinh(cum_cf)
gen ihs_cf = asinh(Financing)

*GII - Null Values (presumably) coded in -1
replace gii = . if gii == -1

gen ln_lfpr = ln(lfpr_15__T)


label variable ihs_cf "IHS CF"
label variable ihs_cum_cf "IHS Cumulative CF"

* ----------------------------------------------------------------------------
* LABOR FORCE PARTICIPATION REGRESSIONS: FLOW, LAGGED, AND CUMULATIVE
* ----------------------------------------------------------------------------
estimates clear


* 1. Basic OLS (Current Flow)
eststo a1: reg ln_lfpr ihs_cf, vce(cluster code_num)
estadd local ctrl "" : a1
estadd local fe   "" : a1

* 2. OLS with Controls
eststo a2: reg ln_lfpr ihs_cf gap L.net_trade_ppt urban edu_high_sec ///
				edu_tertiary tax unemp_ben almp union brgn mig_index, vce(cluster code_num)
estadd local ctrl "\ding{51}" : a2
estadd local fe   ""  : a2

* 3. Random Effects (Current Flow)
eststo a3: xtreg ln_lfpr ihs_cf gap L.net_trade_ppt urban edu_high_sec ///
				edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}" : a3
estadd local fe   "" : a3

* 4. Random Effects (Cumulative)
eststo a35: xtreg ln_lfpr ihs_cum_cf gap L.net_trade_ppt urban edu_high_sec ///
				edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}": a35
estadd local fe   "\ding{51}" : a35

* 5. Random Effects (L1, L5, L10 Lags)
eststo a4: xtreg ln_lfpr l.ihs_cf gap L.net_trade_ppt urban edu_high_sec ///
				edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}": a4
estadd local fe "\ding{51}": a4

eststo a5: xtreg ln_lfpr l5.ihs_cf gap L.net_trade_ppt urban edu_high_sec ///
				edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}": a5
estadd local fe "\ding{51}": a5

eststo a6: xtreg ln_lfpr l10.ihs_cf gap L.net_trade_ppt urban edu_high_sec ///
				edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}": a6
estadd local fe "\ding{51}": a6

* ----------------------------------------------------------------------------
* TABLE EXPORT (LaTeX)
* ----------------------------------------------------------------------------

esttab a1 a2 a3 a35 a4 a5 a6 using "Output\Tables\lfpr ag lags.tex", replace ///
    fragment booktabs style(tex) label ///
    cells(b(star fmt(3)) se(fmt(3))) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    keep(ihs_cf ihs_cum_cf L.ihs_cf L5.ihs_cf L10.ihs_cf) ///
    collabels(none) nomtitles nodepvars noobs ///
    stats(ctrl fe r2_a r2_o N, ///
          fmt(%s %s 3 3 0) ///
          labels("Controls" "Year FE" "Adj. $ R^2$" "Overall $ R^2$" "Observations")) ///
    prehead("\begin{table}[htbp]\centering \caption{Climate Finance and Log Labor Force Participation Rates (15+)} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{7}{c}} \toprule") ///
    postfoot("\bottomrule \end{tabular} \end{adjustbox} \begin{center} \begin{minipage}{0.85\textwidth} \footnotesize \flushleft Climate finance is in mil. 2021 USD and is IHS transformed. The L indicates the number of lagged years. All,15+ indicates all workers regardless of gender 15 years or older. FE are year fixed effects. Standard errors clustered at the country level. *, **, *** denote significance at the 10, 5, and 1 percent levels. \end{minipage} \end{center} \end{table}")	
	
estimates clear


* ----------------------------------------------------------------------------
* LABOR FORCE PARTICIPATION REGRESSIONS: AGGREGATED LAGS W/ INTERACTION
* ----------------------------------------------------------------------------

* 3. Random Effects (Current Flow)
eststo a3: xtreg ln_lfpr c.ihs_cf##c.gain gap L.net_trade_ppt urban edu_high_sec ///
				edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}" : a3
estadd local fe   "" : a3

* 4. Random Effects (Cumulative)
eststo a35: xtreg ln_lfpr c.ihs_cum_cf##c.gain gap L.net_trade_ppt urban edu_high_sec ///
				edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}": a35
estadd local fe   "\ding{51}" : a35

* 5. Random Effects (L1, L5, L10 Lags)
eststo a4: xtreg ln_lfpr c.l.ihs_cf##c.l.gain gap L.net_trade_ppt urban edu_high_sec ///
				edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}": a4
estadd local fe "\ding{51}": a4

eststo a5: xtreg ln_lfpr c.l5.ihs_cf##c.l5.gain  gap L.net_trade_ppt urban edu_high_sec ///
				edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)
estadd local ctrl "\ding{51}": a5
estadd local fe "\ding{51}": a5

* ----------------------------------------------------------------------------
* TABLE EXPORT (LaTeX)
* ----------------------------------------------------------------------------

esttab a3 a35 a4 a5 using "Output\Tables\lfpr ag lag int.tex", replace ///
    fragment booktabs style(tex) label ///
    cells(b(star fmt(3)) se(fmt(3))) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    keep(*ihs_cf* *gain* *ihs_cum_cf*) ///
    collabels(none) nomtitles nodepvars noobs ///
    stats(ctrl fe r2_o N, ///
          fmt(%s %s 3 3 0) ///
          labels("Controls" "Year FE" "Overall $ R^2$" "Observations")) ///
    prehead("\begin{table}[htbp]\centering \caption{Climate Finance (CF), Adaptation Readiness (ND-GAIN), and Log Labor Force Participation Rates (15+)} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{7}{c}} \toprule") ///
    postfoot("\bottomrule \end{tabular} \end{adjustbox} \begin{center} \begin{minipage}{0.8\textwidth} \footnotesize \flushleft Climate finance is in mil. 2021 USD and is IHS transformed. The L indicates the number of lagged years. All,15+ indicates all workers regardless of gender 15 years or older. FE are year fixed effects. Standard errors clustered at the country level. *, **, *** denote significance at the 10, 5, and 1 percent levels. \end{minipage} \end{center} \end{table}")