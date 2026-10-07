"""
Regional Growth Analysis - Task 30
VEDA TECHNOLOGY Internship
Author: Archana - Data Analytics Track

Objective: Compare region growth rates over time
Tools: Python (pandas, matplotlib)
Dataset: Superstore
"""

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from datetime import datetime

# Set style for better visualizations
plt.style.use('seaborn-v0_8')

# Load the Superstore dataset
df = pd.read_excel('sample_-_superstore.xls')

# Convert Order Date to datetime
df['Order Date'] = pd.to_datetime(df['Order Date'])

# Extract year and month for period-over-period analysis
df['Year'] = df['Order Date'].dt.year
df['YearMonth'] = df['Order Date'].dt.to_period('M')

print("=" * 80)
print("REGIONAL GROWTH ANALYSIS")
print("=" * 80)

# ============================================
# STEP 1: Calculate Sales by Region and Year
# ============================================
print("\n1. SALES BY REGION AND YEAR")
print("-" * 80)

sales_by_region_year = df.groupby(['Region', 'Year'])['Sales'].sum().reset_index()
sales_pivot = sales_by_region_year.pivot(index='Year', columns='Region', values='Sales')

print("\nSales by Region and Year:")
print(sales_pivot)

# ============================================
# STEP 2: Calculate Growth Rates (Year-over-Year)
# ============================================
print("\n2. YEAR-OVER-YEAR GROWTH RATES (%)")
print("-" * 80)

growth_rates = sales_pivot.pct_change() * 100
print("\nGrowth Rates (%):")
print(growth_rates.round(2))

# ============================================
# STEP 3: Create Growth Table
# ============================================
print("\n3. DETAILED GROWTH TABLE")
print("-" * 80)

# Create a comprehensive growth table
growth_table = pd.DataFrame()

for region in sales_pivot.columns:
    for i in range(1, len(sales_pivot)):
        prev_year = sales_pivot.index[i-1]
        curr_year = sales_pivot.index[i]
        prev_sales = sales_pivot.loc[prev_year, region]
        curr_sales = sales_pivot.loc[curr_year, region]
        growth_rate = ((curr_sales - prev_sales) / prev_sales) * 100 if prev_sales != 0 else 0

        growth_table = pd.concat([growth_table, pd.DataFrame({
            'Region': [region],
            'Year': [curr_year],
            'Previous Year': [prev_year],
            'Previous Sales': [round(prev_sales, 2)],
            'Current Sales': [round(curr_sales, 2)],
            'Growth Rate (%)': [round(growth_rate, 2)],
            'Absolute Change': [round(curr_sales - prev_sales, 2)]
        })], ignore_index=True)

print("\nDetailed Growth Table:")
print(growth_table)

# Save growth table to CSV
growth_table.to_csv('growth_table.csv', index=False)
print("\n✓ Growth table saved to 'growth_table.csv'")

# ============================================
# STEP 4: Create Charts
# ============================================
print("\n4. CREATING VISUALIZATIONS")
print("-" * 80)

# Chart 1: Sales by Region over Time
fig, axes = plt.subplots(2, 2, figsize=(15, 12))
fig.suptitle('Regional Growth Analysis - Superstore Data', fontsize=16, fontweight='bold')

# Subplot 1: Sales by Region (Bar Chart)
ax1 = axes[0, 0]
sales_pivot.plot(kind='bar', ax=ax1, width=0.8)
ax1.set_title('Sales by Region and Year', fontweight='bold')
ax1.set_xlabel('Year')
ax1.set_ylabel('Sales ($)')
ax1.legend(title='Region')
ax1.tick_params(axis='x', rotation=45)

# Subplot 2: Growth Rates (Line Chart)
ax2 = axes[0, 1]
growth_rates.plot(kind='line', marker='o', ax=ax2, linewidth=2, markersize=8)
ax2.set_title('Year-over-Year Growth Rates (%)', fontweight='bold')
ax2.set_xlabel('Year')
ax2.set_ylabel('Growth Rate (%)')
ax2.legend(title='Region')
ax2.grid(True, alpha=0.3)
ax2.axhline(y=0, color='black', linestyle='--', linewidth=1)

# Subplot 3: Stacked Area Chart
ax3 = axes[1, 0]
sales_pivot.plot(kind='area', ax=ax3, alpha=0.7)
ax3.set_title('Regional Sales Composition (Stacked Area)', fontweight='bold')
ax3.set_xlabel('Year')
ax3.set_ylabel('Sales ($)')
ax3.legend(title='Region')

# Subplot 4: Average Growth Rate by Region
ax4 = axes[1, 1]
avg_growth = growth_rates.mean().sort_values(ascending=False)
colors = ['green' if x > 0 else 'red' for x in avg_growth]
avg_growth.plot(kind='bar', ax=ax4, color=colors, alpha=0.7)
ax4.set_title('Average Annual Growth Rate by Region', fontweight='bold')
ax4.set_xlabel('Region')
ax4.set_ylabel('Average Growth Rate (%)')
ax4.axhline(y=0, color='black', linestyle='--', linewidth=1)
ax4.tick_params(axis='x', rotation=45)

plt.tight_layout()
plt.savefig('regional_growth_charts.png', dpi=300, bbox_inches='tight')
print("✓ Charts saved to 'regional_growth_charts.png'")

# ============================================
# STEP 5: Calculate Quarterly Growth (More Granular)
# ============================================
print("\n5. QUARTERLY GROWTH ANALYSIS")
print("-" * 80)

df['Quarter'] = df['Order Date'].dt.quarter
sales_by_region_quarter = df.groupby(['Region', 'Year', 'Quarter'])['Sales'].sum().reset_index()
sales_by_region_quarter['Period'] = sales_by_region_quarter['Year'].astype(str) + '-Q' + sales_by_region_quarter['Quarter'].astype(str)

quarterly_pivot = sales_by_region_quarter.pivot(index='Period', columns='Region', values='Sales')
print("\nQuarterly Sales:")
print(quarterly_pivot)

quarterly_growth = quarterly_pivot.pct_change() * 100
print("\nQuarterly Growth Rates (%):")
print(quarterly_growth.round(2))

# ============================================
# STEP 6: Generate 5 Insights
# ============================================
print("\n6. KEY INSIGHTS")
print("-" * 80)

insights = []

# Insight 1: Best performing region
total_sales_by_region = df.groupby('Region')['Sales'].sum().sort_values(ascending=False)
best_region = total_sales_by_region.index[0]
insights.append(f"1. {best_region} is the highest-performing region with total sales of ${total_sales_by_region.iloc[0]:,.2f}")

# Insight 2: Fastest growing region
avg_growth_by_region = growth_rates.mean().sort_values(ascending=False)
fastest_growing = avg_growth_by_region.index[0]
insights.append(f"2. {fastest_growing} has the highest average annual growth rate at {avg_growth_by_region.iloc[0]:.2f}%")

# Insight 3: Small-base effect detection
small_base_check = []
for region in sales_pivot.columns:
    first_year_sales = sales_pivot.iloc[0][region]
    if first_year_sales < 100000:
        small_base_check.append((region, first_year_sales))

if small_base_check:
    insights.append(f"3. Small-base effect detected: {[x[0] for x in small_base_check]} started with lower initial sales (<$100K), which may inflate early growth rates")
else:
    insights.append("3. No significant small-base effect detected - all regions started with substantial initial sales")

# Insight 4: Volatility analysis
growth_volatility = growth_rates.std().sort_values(ascending=False)
most_volatile = growth_volatility.index[0]
insights.append(f"4. {most_volatile} shows the most volatile growth pattern (std dev: {growth_volatility.iloc[0]:.2f}%), indicating inconsistent performance")

# Insight 5: Trend analysis
last_two_years = growth_rates.iloc[-2:]
for region in sales_pivot.columns:
    recent_trend = last_two_years[region].mean()
    if recent_trend > 0:
        insights.append(f"5. {region} shows positive recent growth trend ({recent_trend:.2f}% average over last 2 years)")
        break

for insight in insights:
    print(insight)

# Save insights to file
with open('insights.txt', 'w') as f:
    f.write("REGIONAL GROWTH ANALYSIS - 5 KEY INSIGHTS\n")
    f.write("=" * 80 + "\n\n")
    for insight in insights:
        f.write(insight + "\n")
print("\n✓ Insights saved to 'insights.txt'")

# ============================================
# STEP 7: Interview Question Answers
# ============================================
print("\n7. INTERVIEW QUESTION ANSWERS")
print("-" * 80)

interview_answers = {
    "Why can growth rate mislead?": [
        "Growth rates can be misleading due to:",
        "• Small-base effect: A small absolute increase can show a huge percentage when starting from a low base",
        "• Volatility: Short-term fluctuations may not represent long-term trends",
        "• Seasonality: Growth may be seasonal rather than indicative of true performance",
        "• One-time events: Special promotions or unusual events can skew growth rates temporarily",
        "• Inflation: Nominal growth may not reflect real growth after adjusting for inflation"
    ],
    "What is a small-base effect?": [
        "Small-base effect occurs when:",
        "• A region/product starts with a very low initial value (small base)",
        "• Even a small absolute increase appears as a large percentage growth",
        "• Example: Growing from $100 to $200 = 100% growth, but $10,000 to $11,000 = only 10% growth",
        "• This creates an illusion of superior performance",
        "• Solution: Always look at absolute values alongside growth rates"
    ]
}

for question, answers in interview_answers.items():
    print(f"\n{question}")
    print("-" * 80)
    for answer in answers:
        print(answer)

# Save interview answers to file
with open('interview_answers.txt', 'w') as f:
    for question, answers in interview_answers.items():
        f.write(f"{question}\n")
        f.write("=" * 80 + "\n")
        for answer in answers:
            f.write(answer + "\n")
        f.write("\n")

print("\n✓ Interview answers saved to 'interview_answers.txt'")

print("\n" + "=" * 80)
print("ANALYSIS COMPLETE!")
print("=" * 80)
print("\nDeliverables Created:")
print("1. growth_table.csv - Detailed growth table with YoY comparisons")
print("2. regional_growth_charts.png - 4 visualization charts")
print("3. insights.txt - 5 key insights from the analysis")
print("4. interview_answers.txt - Answers to interview questions")
print("\nRun this script in Spyder to generate all deliverables!")
