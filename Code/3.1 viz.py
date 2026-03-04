import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd
import os
import plotly.express as px
import plotly.io as pio
pio.renderers.default = 'browser'  # or 'iframe_connected' for inline

os.chdir(r"C:\Users\antho\OneDrive\Climate Finance")

# Load data
ag = pd.read_csv(r"Output\Data\ag_cf.csv")  # aggregated by year
disag = pd.read_csv(r"Output\Data\disag_cf.csv")  # project-level

plt.clf()
plt.rcdefaults()
plt.close('all')

# --- Climate Finance by Fiscal Year and Instrument Type ---

# Assuming ag has columns: yr, loan, grant, guarantee, equity (values in current USD)
# Aggregate by year
ag_grouped = ag.groupby('yr')[['loan', 'grant', 'guarantee', 'equity']].sum().reset_index()

# Define categories and colors (bottom → top)
categories = ['loan', 'grant', 'guarantee', 'equity']
colors = ['#4a2377', '#8cc5e7', '#f55f74', '#0d7d87']

# Plot setup
sns.set_style("whitegrid")
plt.figure(figsize=(10, 6))

# Build stacked bars
bottom = pd.Series([0] * len(ag_grouped))
for category, color in zip(categories, colors):
    plt.bar(
        ag_grouped['yr'],
        ag_grouped[category],
        bottom=bottom,
        label=category.capitalize(),
        color=color,
        width=0.7
    )
    bottom += ag_grouped[category]

# Labels, legend, and formatting
# Labels, legend, and formatting
plt.xlabel("Year", fontsize=12)
plt.ylabel("Climate Finance", fontsize=12)

# Ensure a tick for every year
plt.xticks(ag_grouped['yr'], rotation=90, fontsize=10)

# Move legend to top-left inside the plot
plt.legend(title="Instrument Type", loc='upper left', fontsize=10)


# Save & show
plt.grid(False)
plt.savefig(r'Output\Graphs\time_instrument.png', bbox_inches='tight', pad_inches = 0.2)




#--- Adaptation/Mitigation ---

disag = disag.rename(columns={'climate_class':'Type'})
ad_mit = pd.pivot_table(
    disag,
    values="Financing",
    index="yr",
    columns="Type",
    aggfunc="sum",
    fill_value=0
)

ad_mit.plot(kind='bar', stacked=True, color=["#4a2377", "#8cc5e7", "#f55f74", "#0d7d87"])
plt.xlabel("Year")
plt.ylabel("Climate Finance")
plt.grid(False)
plt.savefig(r'Output\Graphs\time_purpose.png', bbox_inches='tight', pad_inches = 0.2)
plt.show()


#--- Further Disaggregation ---

ad_mit = pd.pivot_table(
    disag,
    values="Financing",
    index="yr",
    columns="climate_class_sub",
    aggfunc="sum",
    fill_value=0
)

ad_mit.plot(kind='bar', stacked=True)
plt.xlabel("Year")
plt.ylabel("Climate Finance")
plt.legend(title="Project Type", fontsize=6, title_fontsize=6, loc='upper left')
plt.grid(False)
plt.savefig(r'Output\Graphs\time_type.png', bbox_inches='tight', pad_inches = 0.2)
plt.show()

# --- Adaptation vs. Mitigation ---

# --- Load and group data ---
df = pd.read_csv(r"Output\Data\disag_real.csv")
df_country_class = df.groupby(["country", "climate_class"], as_index=False)["Financing"].sum()
df_pivot = df_country_class.pivot(index="country", columns="climate_class", values="Financing").fillna(0) / 1e9

# --- Compute total finance for sorting ---
df_pivot["Total"] = df_pivot.sum(axis=1)
top_countries = df_pivot.nlargest(10, "Total").index  # label only top 10

# --- Scatterplot ---
plt.figure(figsize=(10, 6))
plt.scatter(df_pivot["Mitigation"], df_pivot["Adaptation"], color="teal", alpha=0.7)

# Label only the top countries
for country in top_countries:
    plt.text(
        df_pivot.loc[country, "Mitigation"] + 0.1,
        df_pivot.loc[country, "Adaptation"],
        country,
        fontsize=8,
        alpha=0.9
    )

plt.xlabel("Mitigation Finance (bil. of 2023 USD)")
plt.ylabel("Adaptation Finance (bil. of 2023 USD)")
plt.grid(True, linestyle="--", alpha=0.6)
plt.tight_layout()
plt.savefig(r'Output\Graphs\scatter_cf_type.png', dpi=300)
plt.show()

# --- Adaptation & Mitigation on Map ---

df = pd.read_csv(r"Output\Data\disag_real.csv")

df = pd.pivot_table(
    df,
    values="Financing",
    index=['country'],
    columns="climate_class",
    aggfunc="sum",
    fill_value=0
).reset_index()



# Map 1: Total Adaptation Financing
fig_adapt = px.choropleth(df,
                          locations='country',
                          locationmode='country names',
                          color='Adaptation',
                          hover_name='country',
                          color_continuous_scale=px.colors.sequential.Reds,
                         )

# Map 2: Total Mitigation Financing
fig_mit = px.choropleth(df,
                        locations='country',
                        locationmode='country names',
                        color='Mitigation',
                        hover_name='country',
                        color_continuous_scale=px.colors.sequential.Blues,
                       )


fig_adapt.write_image("Output/Graphs/map_adpt.png")
fig_mit.write_image("Output/Graphs/map_mit.png")


# --- Total Share of Financing by Instrument --- 
df = pd.read_csv(r"Output\Data\disag_real.csv")

cols = ["loan", "grant", "guarantee", "equity","Financing"]
totals = df[cols].sum().to_frame(name="Total")
total_financing = df["Financing"].sum()
totals = totals.drop('Financing')

totals["Percent_of_Financing"] = (totals["Total"] / total_financing) * 100
totals["Percent_of_Financing"] = totals["Percent_of_Financing"].round(2)

plt.figure(figsize=(6,4))
totals["Percent_of_Financing"].sort_values(ascending=False).plot.bar()
plt.ylabel("Percent of Total Financing")
plt.tight_layout()
plt.grid(axis='x')
plt.savefig(r"Output/Graphs/bar_instrument.png")

# --- Share of Adaptation Vs. Mitigation
ad_mit_2 = pd.pivot_table(
    disag,
    values="Financing",
    index="Type",
    aggfunc="sum",
)

total_financing = ad_mit_2['Financing'].sum()
ad_mit_2["Percent_of_Financing"] = (ad_mit_2["Financing"] / total_financing) * 100

plt.figure(figsize=(6,4))
ad_mit_2["Percent_of_Financing"].sort_values(ascending=False).plot.bar()
plt.ylabel("Percent of Total Financing")
plt.tight_layout()
plt.grid(axis='x')
plt.savefig(r"Output/Graphs/bar_purpose.png")

