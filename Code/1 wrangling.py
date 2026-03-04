import pandas as pd
import os
import glob
import wbgapi as wb
import requests
import time
import numpy as np
from io import StringIO
import statsmodels.formula.api as sm

# =============================================================================
# API Rate-Limiting Helper Function (Strict Bypass)
# =============================================================================
req_session = requests.Session()

# Add a User-Agent so the OECD server thinks this is a standard web browser.
# This often prevents automatic throttling of Python scripts.
req_session.headers.update({
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36'
})

def safe_get(url, session, params=None):
    """
    Makes a request with a heavy proactive delay to avoid rate limits,
    and a long penalty-box backoff if a 429 error is hit.
    """
    max_retries = 5
    base_wait = 60 # Start the penalty wait at 60 seconds since OCED limits to 60 per hour 
    
    for attempt in range(max_retries):
        response = session.get(url, params=params)
        
        if response.status_code == 200:
            # Wait a full 5 seconds between successful calls to stay under the radar
            time.sleep(5) 
            return response
            
        elif response.status_code == 429:
            # 30s, 60s, 90s...
            wait_time = base_wait * (attempt + 1) 
            print(f"Error 429 (Rate Limited). Server penalty box. Waiting {wait_time}s before retry {attempt + 1}/{max_retries}...")
            time.sleep(wait_time)
            
            # Clear cookies to reset any rate-limit tracking the server has on this session
            session.cookies.clear() 
            
        else:
            # Let other HTTP errors fail normally
            response.raise_for_status()
            
    raise Exception(f"Failed to fetch data from {url} after {max_retries} attempts.")
    
#Root Dir
os.chdir(r"C:\Users\antho\OneDrive\Climate Finance")

disag = pd.DataFrame()

path = r"Raw\Fan et al"
files = glob.glob(path + "/*.xlsx")
df = pd.concat((pd.read_excel(f) for f in files), ignore_index=True) #Merging all excel files
df = df.rename(columns = {'Country':'country','Year':'yr'})

# --- 
#Disaggregated CSV Export
disag = df 
df.to_csv(r'Output\Data\disag_cf.csv',index=False) 
df.to_stata(r'Output\Data\disag_cf.dta', version=118, write_index=False)

# --- 

#Disaggregated by subclass
df_1 = df.groupby(['country','yr','climate_class_sub'], as_index=False)['Financing'].sum()
df_1 = df_1.pivot(index=['country','yr'], columns='climate_class_sub', values='Financing').reset_index()

df_2 = df.groupby(['country','yr','climate_class'], as_index=False)['Financing'].sum()
df_2 = df_2.pivot(index=['country','yr'], columns='climate_class', values='Financing').reset_index()

# Merge the two pivot tables
df = df.groupby(['country','yr'], as_index=False)[['Financing', 'loan', 'grant', 'guarantee', 'equity']].sum()
clim = pd.merge(df, df_1, on=['country','yr'], how='outer')
clim = pd.merge(clim, df_2, on=['country','yr'], how='outer')

# Add ISO codes
iso = pd.read_csv(r"Raw\ISO Codes\fan ISO.csv")
clim = pd.merge(clim, iso, on='country', how='left')

# Rename columns
names = {
    'Adaptation':'adpt',
    'Mitigation':'mit',
    'Bioenergy':'bio',
    'Carbon dioxide removal technology':'carbon',
    'Disaster risk reduction and early warning system':'disaster',
    'Energy efficiency':'efficiency',
    'Environment':'env', 
    'Geothermal energy':'geo',
    'Hydro energy':'hydro',
    'Other adaptation projects':'other_adpt', 
    'Other mitigation projects':'other_mit',
    'Renewables multiple':'renew_multi', 
    'Solar energy':'solar', 
    'Wind energy':'wind'
}

#Final Disaggregated Data
clim = clim.rename(columns=names)


# =============================================================================
# API Call for World Bank Development + Governance Indicators
# =============================================================================

srs_wdi = [
    # Base Indicators
    'SP.DYN.IMRT.IN',     # Mortality rate, infant
    'SH.HIV.INCD.TL.P3',  # Incidence of HIV
    'FS.AST.PRVT.GD.ZS',  # Domestic credit to private sector
    'SI.POV.GINI',        # Gini index
    'SP.POP.DPND',        # Age dependency ratio
    'BN.KLT.DINV.CD',     # Foreign direct investment, net
    'NE.GDI.TOTL.CD',     # Gross capital formation
    'NY.GDP.MKTP.CD',     # GDP
    'SP.DYN.LE00.IN',     # Life expectancy at birth
    'BN.GSR.GNFS.CD',     # Net trade in goods and services
    'SH.XPD.CHEX.PC.CD',  # Current health expenditure per capita
    'SP.POP.TOTL',        # Population, total
    'FP.CPI.TOTL.ZG',     # Inflation, consumer prices
    'SP.DYN.TFRT.IN',     # Fertility rate
    'DT.ODA.ALLD.CD',     # Net official development assistance
    'NY.GNP.MKTP.PP.CD',  # GNI, PPP
    'SP.URB.TOTL.IN.ZS',  # Urban population
    'SE.SEC.CUAT.UP.ZS',  # Edu attainment, upper secondary
    'SE.TER.CUAT.ST.ZS',  # Edu attainment, tertiary
    'FM.LBL.BMNY.GD.ZS',  # M2 Money (% of GDP)
    'SL.UEM.TOTL.ZS'      # Unemployment rate, 15+
]

rename = {
    # Health
    "SP.DYN.IMRT.IN": "inf_mort",       # Mortality rate, infant (per 1,000 live births)
    "SH.HIV.INCD.TL.P3": "hiv",         # Incidence of HIV, all (per 1,000 uninfected population)
    "SP.DYN.LE00.IN": "life_exp",       # Life expectancy at birth, total (years)
    "SH.XPD.CHEX.PC.CD": "health_pc",   # Current health expenditure per capita (current US$)

    # Finance / macro
    "FS.AST.PRVT.GD.ZS": "credit_ps",   # Domestic credit to private sector (% of GDP)
    "BN.KLT.DINV.CD": "fdi_net",        # Foreign direct investment, net (BoP, current US$)
    "NY.GDP.MKTP.CD": "gdp",            # GDP (current US$)
    "NE.GDI.TOTL.CD": "cap_form",       # Gross capital formation (current US$)
    "BN.GSR.GNFS.CD": "net_trade",      # Net trade in goods and services (BoP, current US$)
    "DT.ODA.ALLD.CD": "aid",            # Net official development assistance and official aid received (current US$)
    "NY.GNP.MKTP.PP.CD": "gni",         # GNI, PPP (current international $)
    "FM.LBL.BMNY.GD.ZS": "m2",          # Broad money (% of GDP)
    'SI.POV.GINI':'gini',
	'SL.UEM.TOTL.ZS':'unemp_15',        # Unemployment Rate, 15+

    # Population / demographics
    "SP.POP.TOTL": "population",        # Population, total
    "SP.DYN.TFRT.IN": "fert",           # Fertility rate, total (births per woman)
    "SP.POP.DPND": "dep",               # Age dependency ratio (% of working-age population)
    "SP.URB.TOTL.IN.ZS": "urban",       # Urban population (% of total population)

    # Education
    "SE.SEC.CUAT.UP.ZS": "edu_high_sec",# Educational attainment, at least completed upper secondary (% of population 25+)
    "SE.TER.CUAT.ST.ZS": "edu_tertiary",# Educational attainment, at least completed short-cycle tertiary (% of population 25+)

    # Prices / household
    "FP.CPI.TOTL.ZG": "inflation",      # Inflation, consumer prices (annual %)
}

types = {
    "health_pc": float,        # Current health expenditure per capita (current US$)
    "credit_ps": float,        # Domestic credit to private sector (% of GDP)
    "fdi_net": float,          # Foreign direct investment, net (BoP, current US$)
    "gdp": float,              # GDP (current US$)
    "gini": float,             # Gini index
    "cap_form": float,         # Gross capital formation (current US$)
    "hiv": float,              # Incidence of HIV, all (per 1,000 uninfected population)
    "inflation": float,        # Inflation, consumer prices (annual %)
    "life_exp": float,         # Life expectancy at birth, total (years)
    "inf_mort": float,         # Mortality rate, infant (per 1,000 live births)
    "net_trade": float,        # Net trade in goods and services (BoP, current US$)
    "population": int,         # Population, total
    'fert':float,              # Fertility rate
    'dep':float,               # Age dependency ratio (% of working age population)
    'aid':float,               # Net official development assistance and official aid received (current US$)
    'gni':float,               # GNI, PPP (current international $)
    'urban':float,             # Urban population (% of total population)
    'edu_high_sec':float,      # Educational attainment, at least completed upper secondary, population 25+, total (%) (cumulative)
    'edu_tertiary':float,      # Educational attainment, at least completed short-cycle tertiary, population 25+, total (%) (cumulative)
    'm2':float,                # Broad money (% of GDP)
    'unemp_15':float           # Unemployment, total (15+) (% of total labor force) (modeled ILO estimate)
}

#Makes the request to WDI
ctrl_wb = wb.data.DataFrame(srs_wdi,time=range(2000, 2024),labels=True).reset_index() 

ctrl_wb = ctrl_wb.melt(
    id_vars=['economy', 'series', 'Country', 'Series'],
    var_name='yr',
    value_name='Value'
)

ctrl_wb['yr'] = ctrl_wb['yr'].str.extract(r'(\d{4})')

#There are only some duplicates with with null values
ctrl_wb = ctrl_wb.pivot_table(
    index=['economy','yr'],
    columns='series',
    values='Value',
    aggfunc='first'  
).reset_index()

ctrl_wb.replace('..', np.nan, inplace=True)

ctrl_wb = ctrl_wb.rename(columns=rename)
ctrl_wb = ctrl_wb.astype(types)
ctrl_wb = ctrl_wb.rename(columns = {'economy':'code'})

# ----------------------------
#API Call for World Bank Governance Indicators
# ----------------------------
rename = {
    'Control of Corruption: Estimate':'corruption',
    'Rule of Law: Estimate':'law',
    'Government Effectiveness: Estimate':'gov',
    'Political Stability and Absence of Violence/Terrorism: Estimate':'pol',
    'Regulatory Quality: Estimate':'rgltn',
    'Voice and Accountability: Estimate':'acct'
}
types = {
    "corruption": float,   
    "law": float,       
    "gov": float,        
    "pol": float,            
    "rgltn": float,             
    "acct": float,         
}

srs_gdi = ['CC.EST','RL.EST','GE.EST','PV.EST','RQ.EST','VA.EST']
ctrl_wgi = wb.data.DataFrame(srs_gdi,time=range(2000,2024), labels = True, db=3).reset_index()

ctrl_wgi = ctrl_wgi.melt(
    id_vars=['economy', 'series', 'Country', 'Series'],
    var_name='yr',
    value_name='Value'
)

ctrl_wgi['yr'] = ctrl_wgi['yr'].str.extract(r'(\d{4})')

#There are only some duplicates with with null values
ctrl_wgi = ctrl_wgi.pivot_table(
    index=['economy','yr'],
    columns='Series',
    values='Value',
    aggfunc='first'  
).reset_index()

ctrl_wgi.replace('..', np.nan, inplace=True)

ctrl_wgi = ctrl_wgi.rename(columns=rename)
ctrl_wgi = ctrl_wgi.astype(types)
ctrl_wgi = ctrl_wgi.rename(columns = {'economy':'code'})
# =============================================================================
# Wars
# =============================================================================

war = pd.read_excel(
    r'Raw\Controls\wars.xlsx',
    header=1
)

#Dropping obs that aren't wars. Trying to mimic Mishra health aid paper by borrowing from this data source. 
war= war.loc[war['intensity'] == 5]
war = war.loc[war['year']>=2000]

#Adding ISO codes, splitting multi-state conflicts into separate obs
iso_war = pd.read_excel(r"Raw\ISO Codes\ISO_war.xlsx")
war = pd.merge(war,iso_war,on=['ID'],how = 'left')
war["code"] = war["code"].str.split(", ")
war = war.explode("code").reset_index(drop=True)

war = war[['year','code']] # only keeping relevant columns
war = war.rename(columns = {'year':'yr'})
war['war']=1
war = war[~war.duplicated(subset=['code', 'yr'], keep='first')] #There are some duplicates because multiple wars can occur in the same country

# =============================================================================
# Labor Share
# =============================================================================

labsh = pd.read_excel(r"Raw\Controls\pwt.xlsx",sheet_name = 'Data')
labsh = labsh.loc[labsh['year']>=2000]
labsh = labsh.rename(columns={'countrycode':'code','year':'yr'})
labsh = labsh[['code','yr','labsh']]

# =============================================================================
# Labor Force Participation Rate
# =============================================================================


lfpr = pd.read_csv(r'Raw\Controls\lfpr.csv') #Modelled estimate

lfpr = pd.pivot_table(
    lfpr,
    values="obs_value",
    columns = ['classif1','sex'],
    index=["ref_area", 'time']
)

lfpr = lfpr.iloc[:,[0,1,5,8,11]]

lfpr.columns = [
    f"{c1}_{c2}" for (c1, c2) in lfpr.columns.to_flat_index()
]

names = {'AGE_AGGREGATE_Y25-54_SEX_F':'lfpr_25_54_F',
           'AGE_AGGREGATE_Y25-54_SEX_M':'lfpr_25_54_M',
           'AGE_AGGREGATE_Y55-64_SEX_T':'lfpr_55_64_T',
           'AGE_YTHADULT_Y15-24_SEX_T':'lfpr_15_24_T',
           'AGE_YTHADULT_YGE15_SEX_T':'lfpr_15+_T',
           'ref_area':'code',
           'time':'yr'}

lfpr = lfpr.reset_index()
lfpr = lfpr.rename(columns=names)

# =============================================================================
# Avg Schooling
# =============================================================================


base_url = "https://api.uis.unesco.org/api/public/data/indicators"
params = {
    'indicator': "MYS.1T8.AG25T99",
    "start": 2000,      
    "end": 2023,       
}

# Send request
response = requests.get(base_url, params=params)
response.raise_for_status()
json_data = response.json()
sch = pd.DataFrame(json_data["records"])
sch = sch[['geoUnit','year','value']]
sch = sch.rename(columns = {'geoUnit':'code','year':'yr','value':'sch'}) #Pretty sure geoUnits are ISO-3 codes


# =============================================================================
# ND-GAIN (Climate Change Exposure + Gov Readiness)
# =============================================================================

gain = pd.read_csv(r'Raw\Controls\gain.csv')

gain = pd.melt(gain,id_vars=['ISO3'],
               value_vars =['1995', '1996', '1997', '1998', '1999', '2000', '2001',
                      '2002', '2003', '2004', '2005', '2006', '2007', '2008', '2009', '2010',
                      '2011', '2012', '2013', '2014', '2015', '2016', '2017', '2018', '2019',
                      '2020', '2021', '2022', '2023'],
               value_name='gain')

gain = gain.rename(columns={'ISO3':'code','variable':'yr'})


# =============================================================================
# OECD Aid API Calls (12/10/2025)
# =============================================================================

#Needed to separate into two functions because the first code could be resused for aid flow, and the second could be reused for pulling a single indicator

#Shortening aid API calls for brevity
def oecd_aid(c1,c2,url):
    print(f"Fetching OECD Aid: {c2}...")
    response = safe_get(url, session=req_session)

    # Load into pandas DataFrame
    df = pd.read_csv(StringIO(response.text))
    
    print(df.columns)
    #No duplicate countries in same time period and have the same donor
    
    df = pd.pivot_table(
        df,
        values="OBS_VALUE",
        columns='FLOW_TYPE',
        index=["RECIPIENT", 'TIME_PERIOD'],
        aggfunc="sum",
        fill_value=0
    ).reset_index()
    
    df = df.rename(columns={
        c1: c2,
        'TIME_PERIOD': 'yr',
        'RECIPIENT': 'code'
    })
    
    return df

#Aggregates Health Aid Across Sectoral Uses (as in Mishra). No duplicate countries
health = oecd_aid('D','health_aid_d',"https://sdmx.oecd.org/dcd-public/rest/data/OECD.DCD.FSD,DSD_CRS@DF_CRS,1.4/ALLD..12110+12181+12182+12191+12220+12230+12240+12250+12261+12281.100._T._T.D.V._T..?endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels")
aid = oecd_aid("_Z","off_flows","https://sdmx.oecd.org/public/rest/data/OECD.DCD.FSD,DSD_DAC2@DF_OFFICIAL,1.3/ALLD+9PRIV0..967.USD.V?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels")

def oecd_2(c2,url):
    print(f"Fetching OECD Data: {c2}...")
    response = safe_get(url, session=req_session)
    df = pd.read_csv(StringIO(response.text))
    df = pd.pivot_table(
        df,
        values="OBS_VALUE",
        index=["REF_AREA", 'TIME_PERIOD'],
    ).reset_index()
    df = df.rename(columns={
        "OBS_VALUE":c2,
        'TIME_PERIOD': 'yr',
        'REF_AREA': 'code'
    })
    return df

#Diff from IMF here - I can only get the settings with 67% of average income with their other settings
tax = oecd_2('tax',"https://sdmx.oecd.org/public/rest/data/OECD.CTP.TPS,DSD_TAX_WAGES_COU@DF_TW_COU,2.1/.AV_TW.PT_COS_LB.S_C2.AW67._Z.A?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels")   # avg tax wedge, % of labor costs, single parent - two kids, 67% of avg wage
pension = oecd_2('pension',"https://sdmx.oecd.org/public/rest/data/OECD.ELS.SPD,DSD_PAG@DF_IPOP,1.0/.A.PTOP.PT_B6G_A_POP_Y_GT65..Y_GE66.?startPeriod=2014&endPeriod=2024&dimensionAtObservation=AllDimensions&format=csvfilewithlabels")  # percentage of GDP
almp = oecd_2('almp',"https://sdmx.oecd.org/public/rest/data/OECD.ELS.SPD,DSD_SOCX_AGG@DF_PUB_PRV,1.0/.A..USD_PPP_PS.ES10._T.TP60.V?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels")       # ALMP, current USD per person, ppp converted
unemp_pop = oecd_2('unemp_pop',"https://sdmx.oecd.org/public/rest/data/OECD.SDD.TPS,DSD_LFS@DF_IALFS_UNE_Q,1.0/.UNE.PS._Z.Y._T.Y_GE15..A?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels" ) # thousands of people, seasonally and calender adjusted
union = oecd_2('union',"https://sdmx.oecd.org/public/rest/data/OECD.ELS.SAE,DSD_TUD_CBC@DF_TUD,1.0/all?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels" )                                   # Index of Trade Union Density
care = oecd_2('care',"https://sdmx.oecd.org/public/rest/data/OECD.ELS.SPD,DSD_SOCX_AGG@DF_PUB_PRV,1.0/.A..PT_B1GQ.ES10..TP521.?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels")             # Early Childcare and Education Spending (% of GDP)
leave = oecd_2('leave',"https://sdmx.oecd.org/public/rest/data/OECD.WISE.CWB,DSD_CWB@DF_CWB,1.0/.C1_4.?startPeriod=2009&endPeriod=2020&dimensionAtObservation=AllDimensions&format=csvfilewithlabels")                                     # Total length of paid maternity and parental leave available to mothers
part = oecd_2('part','https://sdmx.oecd.org/public/rest/data/OECD.ELS.SAE,DSD_FTPT@DF_FTPT,1.0/.EMP.PT_POP_SUB._T._T.EMP.MAIN._T.PT.OECD_DEF.A?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels') # Part time employment as a percent of total employed population, OECD haromonized                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 # 3 months, claim social assistance, claim rent supplements - if empty I don't fill w/ 0
emp_people = oecd_2('emp_people','https://sdmx.oecd.org/public/rest/data/OECD.ELS.SAE,DSD_FTPT@DF_FTPT,1.0/.EMP.PS._T._T.EMP.MAIN._T..OECD_DEF.A?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels')  #Total employed peoplation

min_wage = oecd_2('m_wage',"https://sdmx.oecd.org/public/rest/data/OECD.ELS.SAE,DSD_EARNINGS@MIN2AVE,1.0/.....MEDIAN.?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels") #Minimum wage (1/28/2026)
min_wage.loc[min_wage['code'] == 'DEU', :] = min_wage.loc[min_wage['code'] == 'DEU', :].fillna(0) #Following paper, but only filling 0s for countries with no minimum wage in database. This is only Germany
almp_unemp = oecd_2('almp_unemp','https://sdmx.oecd.org/public/rest/data/OECD.ELS.JAI,DSD_LMP@DF_LMP,1.0/.EXP.LMP_10+LMP_20+LMP_40+LMP_50+LMP_60+LMP_70.PT_B1GQ?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels') #Active Labor Market programs, 6 components, % of GDP (1/28/2026)
replacement_2 = oecd_2('replacement',"https://sdmx.oecd.org/public/rest/data/OECD.ELS.JAI,DSD_TAXBEN_NRR@DF_NRR,/...S_C0+C_C2..AW100.NOEARN_UNEMP_WO_CONBEN.M2.NO.NO.A?startPeriod=2001&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels") #Unemp Replacement Rate (1/29/2026)
tot = oecd_2('tot','https://sdmx.oecd.org/public/rest/data/OECD.SDD.NAD,DSD_NAAG@DF_NAAG_III,/A..TOT.IX.?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels') #Terms of Trade, 2020 base year (1/29/2026)
cov_brgn = oecd_2('cov_brgn',"https://sdmx.oecd.org/public/rest/data/OECD.ELS.SAE,DSD_TUD_CBC@DF_CBC,/all?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels") #Converage of employees w/ collective bargaining agreements
unemp_rate = oecd_2('unemp_15_64',"https://sdmx.oecd.org/public/rest/data/OECD.CFE.EDS,DSD_REG_LABOUR@DF_LAB,2.0/A.CTRY...UNE_RATE.Y15T64._T.PT_LF_SUB?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels")  #Unemp rate, 15-64, % of the same subgroup (2/6/2026)

#Old age + incapacity spending (% of GDP),  public and mandatory private

print("Fetching OECD Data: Incapacity and Old Age...")
url = "https://sdmx.oecd.org/public/rest/data/OECD.ELS.SPD,DSD_SOCX_AGG@DF_PUB_PRV,1.0/.A..PT_B1GQ.._T.TP11+TP31.?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels" 
response = safe_get(url, session=req_session)
df = pd.read_csv(StringIO(response.text))
df = pd.pivot_table(
    df,
    values="OBS_VALUE",
    columns='Programme type',
    index=["REF_AREA", 'TIME_PERIOD'],
    aggfunc="sum",
    fill_value=0
).reset_index()
spending = df.rename(columns={
    'TIME_PERIOD': 'yr',
    'REF_AREA': 'code',
    'Incapacity related':'incap', 
    'Old age':'age'
})


#Population by Age Group (% of total pop)
print("Fetching OECD Data: Population by Age Group...")
url = "https://sdmx.oecd.org/public/rest/data/OECD.CFE.EDS,DSD_REG_DEMO@DF_POP_BROAD,2.0/A.CTRY...POP.Y_LT15+Y15T64+Y_GE65._T.PT_POP?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels" 
response = safe_get(url, session=req_session)
df = pd.read_csv(StringIO(response.text))
df = pd.pivot_table(
    df,
    values="OBS_VALUE",
    columns='AGE',
    index=["REF_AREA", 'TIME_PERIOD'],
    aggfunc="sum",
    fill_value=0
).reset_index()
pop_by_age = df.rename(columns={
    'TIME_PERIOD': 'yr',
    'REF_AREA': 'code'
})

# Unemployment benefits - 67% + 100% of avg wage; 1 parent w/ children, 
# couple w/o children, couple w/ children; 1, 6, 12 month; avg across types, interpolated
# Spouse earns minimum wage; within year + country average 
# % of household income before unemployment

print("Fetching OECD Data: Unemployment Benefits...")
url = "https://sdmx.oecd.org/public/rest/data/OECD.ELS.JAI,DSD_TAXBEN_NRR@DF_NRR,1.0/...C_C0+S_C2+C_C2..AW67+AW100..M6+M1+M12...A?startPeriod=2001&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels" 
response = safe_get(url, session=req_session)
df = pd.read_csv(StringIO(response.text))
df = pd.pivot_table(
    df,
    values="OBS_VALUE",
    index=["REF_AREA", 'TIME_PERIOD'],
    aggfunc="mean",
    fill_value=0
).reset_index()
unemp_benefits = df.rename(columns={
    'TIME_PERIOD': 'yr',
    'REF_AREA': 'code',
    'OBS_VALUE':'unemp_benefits'
})

#Private Flows

print("Fetching OECD Data: Private Flows...")
url = "https://sdmx.oecd.org/public/rest/data/OECD.DCD.FSD,DSD_DAC2@DF_DAC4,1.3/..405.USD.?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels" 
response = safe_get(url, session=req_session)
df = pd.read_csv(StringIO(response.text))
df = pd.pivot_table(
    df,
    values="OBS_VALUE",
    index=["RECIPIENT", 'TIME_PERIOD'],
    fill_value=0
).reset_index()
private_flows = df.rename(columns={
    'TIME_PERIOD': 'yr',
    'RECIPIENT': 'code',
    'OBS_VALUE':'private_flows'
})

#(Presumably Nominal) Long-term Interest Rates - 1/28/2026 
# Adjusted later with inflation from WDI

print("Fetching OECD Data: Long-term Interest Rates...")
url = "https://sdmx.oecd.org/public/rest/data/OECD.SDD.STES,DSD_KEI@DF_KEI,4.0/.A.IRLT....?startPeriod=2000&endPeriod=2023&dimensionAtObservation=AllDimensions&format=csvfilewithlabels"
response = safe_get(url, session=req_session)
df = pd.read_csv(StringIO(response.text))
df = pd.pivot_table(
    df,
    values="OBS_VALUE",
    index=["REF_AREA", 'TIME_PERIOD'],
    fill_value=0
).reset_index()
lti = df.rename(columns={
    'TIME_PERIOD': 'yr',
    'REF_AREA': 'code',
    'OBS_VALUE':'lti'
})

#EPL Measures - 1/28/2026

print("Fetching OECD Data: EPL Measures...")
url = "https://sdmx.oecd.org/public/rest/data/OECD.ELS.JAI,DSD_EPL@DF_EPL,/A..EPL_R+EPL_T..VERSION1?startPeriod=2000&endPeriod=2019&dimensionAtObservation=AllDimensions&format=csvfilewithlabels"
response = safe_get(url, session=req_session)
df = pd.read_csv(StringIO(response.text))
df = pd.pivot_table(
    df,
    values="OBS_VALUE",
    columns=["MEASURE"],
    index=["REF_AREA", 'TIME_PERIOD']).reset_index()
epl = df.rename(columns={
    'TIME_PERIOD': 'yr',
    'REF_AREA': 'code',
    'EPL_R':'RC',
    'EPL_T':'TC'
})

# =============================================================================
# EPL Variables for Estonia (2/4/2026)
# =============================================================================

est = pd.read_excel(r"Raw\Controls\eu epl.xls", header = 1, sheet_name = "Estonia_done")
est = est.loc[est['item'].isin(['RC','TC'])]
est = pd.melt(est, id_vars=['item'], value_vars = ['y2000', 'y2001', 'y2002', 'y2003', 
        'y2004', 'y2005', 'y2006', 'y2007'])
est = est.pivot_table(
    index="variable",
    columns="item",
    values="value"
).reset_index()
est = est.rename(columns = {'variable':'yr'})
est['yr'] = est['yr'].str.replace('y', '', regex=False)
est['code'] = 'EST'

# =============================================================================
# Merging EPL Data Together + Conversion to float
# =============================================================================

epl = pd.concat([est, epl],axis = 0)
epl = epl.astype({'RC':float,'TC':float})
epl['epl'] = (epl['RC'] + epl['TC'])/2

# =============================================================================
# Global Innovation Index (12/10/2025)
# =============================================================================

gii = pd.read_csv(r"Raw\Controls\GII_2011_2024_long_format.tsv",sep='\t')
gii = gii.drop('Rank',axis=1)
gii = gii .rename(columns={
    'Country': 'code',
    'Year': 'yr',
    'Score':'gii'
})

# =============================================================================
# Centralization of Bargaining - Index (12/10/2025)
# =============================================================================

brgn = pd.read_csv(r'Raw\Controls\ICTWSS_Controls.csv')
brgn = brgn[['iso3','year','Central']]
brgn = brgn.rename(columns={
    'iso3': 'code',
    'year': 'yr',
    'Central':'brgn'
})

# =============================================================================
# IMF - Output Gap - % of potential GDP (12/10/2025)
# =============================================================================

gap = pd.read_csv(r'Raw\Controls\output_gap.csv')
gap["code"] = gap["SERIES_CODE"].str.split(".", n=1).str[0]
gap = gap.loc[gap['INDICATOR']=='Output gap, Percent of potential GDP'] 
cols_to_keep = ["code"] + [str(y) for y in range(2000, 2024)]
gap = gap[cols_to_keep]
gap = gap.melt(id_vars="code", var_name="yr", value_name="gap")

# =============================================================================
# Polity IV - Democracy Score
# =============================================================================

demo = pd.read_csv(r"Raw\polity_iv.csv")
demo = demo[['year','scode','democ']]
demo = demo.rename(columns={'year':'yr','scode':'code'})
demo = demo.loc[demo['yr']>=2000]

# =============================================================================
# Migration Policy Changes (12/10/2025)
# =============================================================================

mig2 = pd.read_stata(r'Raw\Controls\demig-policy-database_version-1-3.dta')
iso = pd.read_csv(r'Raw\ISO Codes\mig ISO.csv')
mig2 = pd.merge(mig2,iso,on=['country'],how='outer') #Every one should get a match

mig2 = mig2.loc[mig2['change_level'] == "Major change"]
mig2 = mig2.loc[
    mig2['pol_area'].isin([
        'Integration',
        'Legal entry and stay',
    ])
]
mig2 = mig2.loc[mig2['change_restrict'].isin(["More restrictive", "Less restrictive"])]
mig2['change_restrict'] = np.where(mig2['change_restrict'] == 'More restrictive', 1, -1)  #They don't mention restrictiveness of policies. I think its important. Additionally, I extend back from 1980
mig2 = mig2.rename(columns={'change_restrict':'Restrictiveness','year':'yr'}) 
mig2 = mig2.groupby(['code','yr'])['Restrictiveness'].sum().reset_index()

#Reformatting for merge later
mig2 = mig2.loc[(mig2['yr'] >= 1980) & (mig2['yr'] < 1990)]
mig2 = mig2[['code','yr','Restrictiveness']]

# =============================================================================
# Migration Policy Changes - Quantmig (1990-2020) (1/20/2025)
# =============================================================================

mig = pd.read_csv(r'Raw\Controls\quantmig.xls', sep="\t")
mig = mig.rename(columns={'Country':'country','Year':'yr'})
mig = mig.dropna(subset=['yr','Magnitude'])
mig['yr'] = mig['yr'].astype(int)
mig = pd.merge(mig,iso,on=['country'],how='outer') #Every one should get a match
mig = mig.loc[mig['Magnitude'] == "Major change"]
mig = mig.loc[
    mig['Policy area'].isin([
        'Integration',
        'integration',
        'Legal entry and stay',
        'legal entry and stay'
    ])
]
mig = mig.loc[mig['Restrictiveness'].isin(["More restrictive", "Less restrictive"])]
mig['Restrictiveness'] = np.where(mig['Restrictiveness'] == 'More restrictive', 1, -1)  #They don't mention Restrictiveness of policies. I think its important. Additionally, I extend back from 1980
mig = mig.groupby(['code','yr'])['Restrictiveness'].sum().reset_index()
mig = mig.sort_values(['code','yr'])

#Extending Quantmig to 1980
mig = pd.concat([mig,mig2], ignore_index=True)

#Creating the cumulative index from start date
mig['mig_index'] = mig.groupby('code')['Restrictiveness'].cumsum()

#Need to forward fill years inbetween changes

# 1. Define the Timeline
# You can hardcode this (e.g., range(1980, 2016)) or use your data's min/max
all_years = range(1990, 2021)
unique_countries = mig['code'].unique()

# 2. Create the MultiIndex (The Skeleton)
# This creates every combination of Country + Year
full_idx = pd.MultiIndex.from_product([unique_countries, all_years], names=['code', 'yr'])

# 3. Reindex your data
# We set the index of your current data to match the skeleton, then expand it
mig = mig.set_index(['code', 'yr']).reindex(full_idx)

# 4. Forward Fill (Propagate the policy index forward)
# We group by level 0 (country) so data doesn't leak from China to Switzerland
mig['mig_index'] = mig.groupby(level='code')['mig_index'].ffill()

# 5. Handle Start Years (Optional)
# Years BEFORE the first change will still be NaN. 
# Usually, in index construction, these are assumed to be 0 (the baseline).
mig['mig_index'] = mig['mig_index'].fillna(0)

# 6. Cleanup
mig = mig.reset_index()
# Keep only years greater than or equal to 2000
mig = mig.loc[mig['yr'] >= 2000]


# =============================================================================
# IMF Capital Stock and Captial Formation Data (12/17/2025) 
# - Constant prices, Percent of GDP
# - I assume Purchasing power parity (PPP) international dollar, ICP benchmark 2017
# =============================================================================

cap = pd.read_csv(r'Raw\Controls\cap_form.csv',usecols=['COUNTRY.ID','INDICATOR.ID','TIME_PERIOD','OBS_VALUE'])

cap = cap.pivot(
    index=["COUNTRY.ID", "TIME_PERIOD"],
    columns="INDICATOR.ID",
    values="OBS_VALUE"
).reset_index()

label = {
    'P51G_S13_Q_POGDP_PT':'cap_form_gov',
    'P51G_PS_Q_POGDP_PT':'cap_form_priv',
    'P51G_PUPVT_Q_POGDP_PT':'cap_form_ppp',
    'CAPSTCK_S13_Q_POGDP_PT':'cap_stock_gov',
    'CAPSTCK_PS_Q_POGDP_PT':'cap_stock_priv',
    'CAPSTCK_PUPVT_Q_POGDP_PT':'cap_stock_ppp',
    'COUNTRY.ID':'code',
    'TIME_PERIOD':'yr'
    }

label = {
    'P51G_S13_Q_POGDP_PT':'cap_form_gov',
    'P51G_PS_Q_POGDP_PT':'cap_form_priv',
    'P51G_PUPVT_Q_POGDP_PT':'cap_form_ppp',
    'CAPSTCK_S13_Q_POGDP_PT':'cap_stock_gov',
    'CAPSTCK_PS_Q_POGDP_PT':'cap_stock_priv',
    'CAPSTCK_PUPVT_Q_POGDP_PT':'cap_stock_ppp',
    'COUNTRY.ID':'code',
    'TIME_PERIOD':'yr'
    }

cap = cap.rename(columns=label)
cap = cap.dropna(subset=['yr'])
cap = cap.astype({'yr':'int'})

# =============================================================================
# Budget Data (1/20/2026)
# =============================================================================

budget = pd.read_csv(r"Raw\Controls\budget.csv")
budget = budget.rename(columns={'COUNTRY.ID':'code','TIME_PERIOD':'yr','OBS_VALUE':'budget'})
budget = budget[['code','yr','budget']]

# =============================================================================
# TFP (2/4/2026)
# =============================================================================

tfp = pd.read_excel(r"Raw\Controls\tfp.xlsx",
                  header = 5, sheet_name = "Data")
tfp = tfp.drop(columns=['TED2_CHN_TFPG'])
tfp.columns = tfp.columns.str[5:8]
tfp = tfp.rename(columns={'ed:':'yr'})
tfp = tfp.iloc[1:]
tfp = tfp.melt(id_vars="yr",var_name="code",value_name="tfp")
tfp = tfp.astype({'tfp':float})

# =============================================================================
# Coordination of Bargaining (2/6/2026) (ICTWSS)
# =============================================================================

coord = pd.read_csv(r"Raw\Controls\ICTWSS_Controls.csv", usecols = ['Coord','year','iso3'])
coord = coord.rename(columns={'iso3':'code','year':'yr','Coord':'coord'})
# =============================================================================
# Merge
# =============================================================================

dfs = [clim, ctrl_wb, ctrl_wgi, war, labsh, lfpr, sch,gain,health,aid,demo,
       private_flows,
       #LFPR Regression - 12/11/2025
       mig,gap,brgn,gii,pop_by_age,spending,part,unemp_benefits,leave,
       care,union,unemp_pop,almp,pension,tax,emp_people,
       
       #Additional Capital Formation Regresion - 12/17/2025
       cap,budget,
       #Unemployment Regression - 2/4/2026
       cov_brgn,min_wage,almp_unemp,replacement_2,tot,
       epl,lti,tfp, coord, unemp_rate]

# Ensure 'yr' is int in all DataFrames
for i in range(len(dfs)):
    dfs[i]['yr'] = dfs[i]['yr'].astype(int)

panel = dfs[0].copy()
for df_i in dfs[1:]:
    panel = pd.merge(panel, df_i, on=['code', 'yr'], how='outer')
    
if 'war' in panel.columns:
    panel['war'] = panel['war'].fillna(0) #Assuming if war data doesn't report war in that year that there is no war at all in any other
panel['yr'] = panel['yr'].astype(int)

panel = panel.loc[panel['Financing'].notna()] #IMPORTANT: Since everything is outer merged, I dropping nulls for financing gets rid of all values not present in the Fan et al data


# =============================================================================
# Final Adjustments (Conversions,etc)
# =============================================================================

# -- Converting to Real (2023 US$ Values)---

# Load the CSV file
df_cpi = pd.read_csv(r"Raw\USA CPI.csv")

# 1. Filter the DataFrame to keep only the data row (index 0)
# The uploaded file contains header/metadata in other rows.
df_cpi = df_cpi.iloc[[0]].copy()

# 2. Drop the redundant country and series identifier columns
drop_cols = ['Country Name', 'Country Code', 'Series Name', 'Series Code']
df_cpi = df_cpi.drop(columns=drop_cols)

# 3. Use the melt function to transform the wide-format year columns to long format.
# All remaining columns (the years) are treated as value columns.
df_cpi = df_cpi.melt(var_name='yr', value_name='cpi')

# 4. Clean the 'year' column to extract the 4-digit year.
# The format is 'YYYY [YRYYYY]', so we extract the first 4 characters and convert to integer.
df_cpi['yr'] = df_cpi['yr'].str[:4].astype(int)

df_cpi = df_cpi.set_index('yr')
df_cpi = df_cpi['cpi'] #Converting to series

# --- Conversion  for main export ----

panel['health_aid_d'] = panel['health_aid_d']*1.0e6 #originally in mil. current USD
panel['off_flows'] = panel['off_flows']*1.0e6 #originally in mil. current USD

col = ['Financing', 'loan', 'grant', 'guarantee', 
       'equity','gdp','health_pc',
       'fdi_net','cap_form','net_trade',
       'health_aid_d','off_flows',
       'aid','almp','gni','private_flows',
       
       'adpt','mit','bio','carbon','disaster',
       'efficiency','env','geo','hydro','other_adpt',
       'other_mit','renew_multi','solar','wind']

for c in col:
    panel[c] = panel[c] * (df_cpi[2023] / panel['yr'].map(df_cpi))
    
# --- ALMP adjustment per IMF/Grigoli et al. (2018) ---

panel['almp'] = (panel['almp']/panel['unemp_pop'])/panel['gdp']

# --- Taking out residuals for data --- 

model = sm.ols(formula = ' incap ~ Y15T64 + Y_GE65 + Y_LT15 + life_exp', data=panel).fit()
panel['incap_res'] = model.resid

model = sm.ols(formula = ' age  ~ Y15T64 + Y_GE65 + Y_LT15 + life_exp', data=panel).fit()
panel['age_res'] = model.resid

# ---  Real Net trade as a % of real gdp-- 

panel['net_trade_ppt'] = panel['net_trade']/panel['gdp']

# --- Adjusting long-term interest rate with inflation

panel['lti'] = panel['lti']-panel['inflation']

# --- Conversion for disaggregated data --- 

col = ['Financing', 'loan', 'grant', 'guarantee', 'equity']
for c in col:
    disag[c] = disag[c] * (df_cpi[2023] / disag['yr'].map(df_cpi))

disag.to_csv(r'Output\Data\disag_real.csv', index=False)

# =============================================================================
# Export
# =============================================================================

panel.to_stata(r'Output\Data\cf_data_Controls.dta', version=118, write_index=False)
