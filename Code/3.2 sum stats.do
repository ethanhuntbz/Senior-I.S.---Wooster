*Ethan Hunt
*11/3/2025
*Main File - Senior IS

*Set folder here
cd "C:\Users\antho\OneDrive\Climate Finance"

pip, povline(2.15) clear
keep if (welfare_type == 2) & (reporting_level == "national") // Welfare - income
keep country_code year headcount poverty_gap poverty_severity
rename country_code code
rename year yr
tempfile pov
save `pov'

estimate clear 
use "Output\Data\cf_data_v4.dta", clear
merge 1:1 code yr using `pov'
keep if _merge == 3

label variable country "Country Name"
label variable yr "Year"
label variable Financing "Total Climate Finance"
label variable loan "Loan Amount"
label variable grant "Grant Amount"
label variable guarantee "Guarantee Amount"
label variable equity "Equity Amount"
label variable code "Country Code"
label variable dep "Age dependency ratio"
label variable credit_ps "Domestic Credit to Private Sector"
label variable fdi_net "Net Foreign Direct Investment Inflows"
label variable gdp "Gross Domestic Product"
label variable gini "Gini Index"
label variable cap_form "Gross Fixed Capital Formation"
label variable hiv "HIV Prevalence"
label variable inflation "Inflation Rate (CPI)"
label variable life_exp "Life Expectancy at Birth"
label variable inf_mort "Infant Mortality Rate"
label variable net_trade_ppt "Net Trade"
label variable population "Total Population"
label variable gov "Government Effectiveness Index"
label variable pol "Political Stability Index"
label variable rgltn "Regulatory Quality Index"
label variable war "War/Conflict Indicator"
label variable sch "Mean Years of Schooling"
label variable gain "ND-GAIN"
label variable health_aid_d "Health Aid Disbursements"
label variable fert "Fertility Rate"

// New variables 12/19/2025
label variable edu_high_sec "Secondary Education"
label variable edu_tertiary "Teritary Education"
label variable aid "ODA"
label variable off_flows "Official Flows"
label variable urban "Urbanization"
label variable lfpr_25_54_F "LFPR (25-54 yrs, Female) "
label variable lfpr_25_54_M "LFPR (25-54 yrs, Male) "
label variable lfpr_55_64_T "LFPR (55-64 yrs, All) "
label variable lfpr_15_24_T "LFPR (15-24 yrs, All)"
label variable lfpr_15__T "LFPR (15+ yrs, All)"
label variable gain "ND-GAIN"
label variable democ "Democracy Index"
label variable gap "Output Gap"
label variable brgn "Bargaining Index"
label variable gii "Global Innovation Index"
label variable incap "Incapacity Spending"
label variable age "Old Age Spending"
label variable part "Part Time Employment"
label variable unemp_benefits "Unemployment Benefits"
label variable leave "Maternity Leave"
label variable care "Early Childhood Education and Care Spending"
label variable almp "ALMP"
label variable tax "Average Tax Wedge"
label variable emp_people "Total Employment"
label variable cap_form_gov "Government Captial Formation"
label variable cap_form_ppp "PPP Captial Formation"
label variable cap_form_priv "Private Captial Formation"
label variable emp_svc "Industry/Services Employment"
label variable headcount "Poverty Headcount"
label variable poverty_gap "Poverty Gap"
label variable poverty_severity "Squared Poverty Gap"

*Summary Stats
	estpost summarize country yr Financing loan grant guarantee equity code dep ///
credit_ps fdi_net gdp gini cap_form hiv inflation life_exp ///
inf_mort net_trade_ppt population gov pol rgltn war sch gain ///
health_aid_d fert edu_high_sec edu_tertiary ///
aid off_flows urban lfpr_25_54_F lfpr_25_54_M lfpr_55_64_T ///
lfpr_15_24_T lfpr_15__T democ gap brgn gii incap ///
age part unemp_benefits leave care almp tax emp_people ///
cap_form_gov cap_form_ppp cap_form_priv headcount poverty_gap poverty_severity

	esttab using "Output\Tables\sum stats.tex", cells("count mean sd min max") ///
		label replace nomtitles nonumber ///
		title("Summary Statistics") 

/*Correlation Matrix
	//
	// Enter varlist HERE when complete with IS
	//
	// estpost corr HERE
	// esttab using "$output\corr.tex",label replace title("Correlation Matrix")
	
// *Quick testing
// gen f2 = ln(Financing)
//
// scatter inf_mort f2
//
// scatter net_trade f2
//
// scatter labsh f2

bysort country: keep if _n == 1

listtab country using "$output\countries.tex", ///
	rstyle(tabular) replace ///
    head("List of Countries") ///


*Need to defalte it properly so I can get the correct classificaiton
gen gdppc  = gdp/population
gen inc = 0 
replace inc = 1 if gdppc <= 1135
replace inc = 2 if gdppc > 1136 & gdppc <= 4495
replace inc = 3 if gdppc > 4496 & gdppc <= 13935
replace inc = 4 if gdppc > 13935
twoway bar Financing inc 

		