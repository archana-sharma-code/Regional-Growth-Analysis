"""
Regional Growth Analysis - Task 30
VEDA TECHNOLOGY Internship
Author: Archana - Data Analytics Track
"""

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Load the Superstore dataset
df = pd.read_excel('sample_-_superstore.xls')

# Display basic information about the dataset
print("Dataset Shape:", df.shape)
print("\nColumn Names:")
print(df.columns.tolist())
print("\nFirst few rows:")
print(df.head())
print("\nData Types:")
print(df.dtypes)
print("\nMissing Values:")
print(df.isnull().sum())

# Check if 'Region' column exists
if 'Region' in df.columns:
    print("\nUnique Regions:")
    print(df['Region'].unique())
    print("\nRegion counts:")
    print(df['Region'].value_counts())
