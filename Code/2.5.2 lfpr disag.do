set more off
set more off
cd "C:\Users\antho\OneDrive\Climate Finance"
use "Output\Data\cf_data_v4.dta", clear

encode code, gen(code_num)
xtset code_num yr

sort code_num yr
bysort code_num (yr): gen cum_cf = sum(Financing)
gen ihs_cum_cf = asinh(cum_cf)
gen ihs_cf = asinh(Financing)

*GII - Null Values (presumably) coded in -1
replace gii = . if gii == -1


gen ln_lfpr_15__T = ln(lfpr_15__T)
gen ln_lfpr_55_64_T = ln(lfpr_55_64_T) 
gen ln_lfpr_15_24_T = ln(lfpr_15_24_T)
gen ln_lfpr_25_54_M = ln(lfpr_25_54_M)
gen ln_lfpr_25_54_F = ln(lfpr_25_54_F)


eststo a: xtreg ln_lfpr_15__T ihs_cum_cf gap L.net_trade_ppt urban edu_high_sec ///
				edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)
				
eststo b: xtreg ln_lfpr_55_64_T ihs_cum_cf gap L.net_trade_ppt urban edu_high_sec ///
				 edu_tertiary tax unemp_ben almp union brgn mig_index ///
				 age_res incap_res i.yr, re  vce(cluster code_num)
				 				
eststo c: xtreg ln_lfpr_15_24_T ihs_cum_cf gap L.net_trade_ppt urban edu_high_sec ///
				 edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)

eststo d: xtreg ln_lfpr_25_54_M ihs_cum_cf gap L.net_trade_ppt urban edu_high_sec ///
				 edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)

eststo e: xtreg ln_lfpr_25_54_F ihs_cum_cf gap L.net_trade_ppt urban edu_high_sec ///
			     edu_tertiary tax unemp_ben almp union brgn mig_index ///
				 part care leave i.yr, re vce(cluster code_num)

esttab a b c d e using "Output\Tables\lfpr disag acc.tex", replace ///
    cells(b(star fmt(3)) se(fmt(3))) booktabs style(tex) unstack ///
    keep(ihs_cum_cf) coeflabels(ihs_cum_cf "IHS Cumulative Climate Finance") ///
	title("Cumulative Climate Finance (IHS) and Log Labor Force Participation") ///
    star(* 0.10 ** 0.05 *** 0.01) starlevels(* 0.10 ** 0.05 *** 0.01) ///
    collabels(none) gaps nonotes nonumbers nomtitles nodepvars se(%4.2f) b(%4.2f) ///
    stats(N, labels("Observations") fmt(0)) /// 
    posthead("&\multicolumn{1}{c}{(1)}   &\multicolumn{1}{c}{(2)}   &\multicolumn{1}{c}{(3)}   &\multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)}   \\ \midrule Dependent Variable & \shortstack{All \\ 15+} & \shortstack{All \\ 55-64} & \shortstack{All \\ 15-24} & \shortstack{Male \\ 25-54} & \shortstack{Female \\ 25-54} \\ \midrule") postfoot("\bottomrule \end{tabular} \begin{center} \begin{minipage}{0.7\textwidth} \footnotesize\footnotesize  \centering Standard errors clustered at the country level. *, **, *** denote significance at the 10, 5, and 1 percent levels \end{minipage} \end{center} \end{table}")



estimate clear
	
eststo a: xtreg ln_lfpr_15__T L.ihs_cf gap L.net_trade_ppt urban edu_high_sec ///
				edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)
				
eststo b: xtreg ln_lfpr_55_64_T L.ihs_cf gap L.net_trade_ppt urban edu_high_sec ///
				 edu_tertiary tax unemp_ben almp union brgn mig_index ///
				 age_res incap_res i.yr, re  vce(cluster code_num)
				 				
eststo c: xtreg ln_lfpr_15_24_T  L.ihs_cf gap L.net_trade_ppt urban edu_high_sec ///
				 edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)

eststo d: xtreg ln_lfpr_25_54_M  L.ihs_cf gap L.net_trade_ppt urban edu_high_sec ///
				 edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)

eststo e: xtreg ln_lfpr_25_54_F  L.ihs_cf gap L.net_trade_ppt urban edu_high_sec ///
			     edu_tertiary tax unemp_ben almp union brgn mig_index ///
				 part care leave i.yr, re vce(cluster code_num)
				 
				 
esttab a b c d e using "Output\Tables\lfpr disag lag.tex", replace ///
    cells(b(star fmt(3)) se(fmt(3))) booktabs style(tex) unstack ///
    keep(L.ihs_cf) coeflabels(L.ihs_cf "L.IHS Climate Finance") ///
	title("One-Year Lagged Climate Finance and Log Labor Force Participation") ///
    star(* 0.10 ** 0.05 *** 0.01) starlevels(* 0.10 ** 0.05 *** 0.01) ///
    collabels(none) gaps nonotes nonumbers nomtitles nodepvars se(%4.2f) b(%4.2f) ///
    stats(N, labels("Observations") fmt(0)) /// 
    posthead("&\multicolumn{1}{c}{(1)}   &\multicolumn{1}{c}{(2)}   &\multicolumn{1}{c}{(3)}   &\multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)}   \\ \midrule Dependent Variable & \shortstack{All \\ 15+} & \shortstack{All \\ 55-64} & \shortstack{All \\ 15-24} & \shortstack{Male \\ 25-54} & \shortstack{Female \\ 25-54} \\ \midrule") postfoot("\bottomrule \end{tabular} \begin{center} \begin{minipage}{0.7\textwidth} \footnotesize\footnotesize \centering All specifications have covariates as described. The L indicates the number of lagged years.  Standard errors clustered at the country level. *, **, *** denote significance at the 10, 5, and 1 percent levels \end{minipage} \end{center} \end{table}")


estimates clear 
	
eststo a: xtreg ln_lfpr_15__T ihs_cf gap L.net_trade_ppt urban edu_high_sec ///
				edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)
				
eststo b: xtreg ln_lfpr_55_64_T ihs_cf gap L.net_trade_ppt urban edu_high_sec ///
				 edu_tertiary tax unemp_ben almp union brgn mig_index ///
				 age_res incap_res i.yr, re  vce(cluster code_num)
				 				
eststo c: xtreg ln_lfpr_15_24_T ihs_cf gap L.net_trade_ppt urban edu_high_sec ///
				 edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)

eststo d: xtreg ln_lfpr_25_54_M ihs_cf gap L.net_trade_ppt urban edu_high_sec ///
				 edu_tertiary tax unemp_ben almp union brgn mig_index i.yr, re vce(cluster code_num)

eststo e: xtreg ln_lfpr_25_54_F ihs_cf gap L.net_trade_ppt urban edu_high_sec ///
			     edu_tertiary tax unemp_ben almp union brgn mig_index ///
				 part care leave i.yr, re vce(cluster code_num)
				 
esttab a b c d e using "Output\Tables\lfpr disag short.tex", replace ///
    cells(b(star fmt(3)) se(fmt(3))) booktabs style(tex) unstack ///
    keep(ihs_cf) coeflabels(ihs_cf "IHS Climate Finance") ///
	title("Short Run Effects of Climate Finance on Log Labor Force Participation") ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    collabels(none) gaps nonotes nonumbers nomtitles nodepvars se(%4.2f) b(%4.2f) ///
    stats(N, labels("Observations") fmt(0)) /// 
    posthead("&\multicolumn{1}{c}{(1)}   &\multicolumn{1}{c}{(2)}   &\multicolumn{1}{c}{(3)}   &\multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)}   \\ \midrule Dependent Variable & \shortstack{All \\ 15+} & \shortstack{All \\ 55-64} & \shortstack{All \\ 15-24} & \shortstack{Male \\ 25-54} & \shortstack{Female \\ 25-54} \\ \midrule") postfoot("\bottomrule \end{tabular} \begin{center} \begin{minipage}{0.7\textwidth} \footnotesize\footnotesize  \centering All specifications have covariates as described. Standard errors clustered at the country level. *, **, *** denote significance at the 10, 5, and 1 percent levels \end{minipage} \end{center} \end{table}")


