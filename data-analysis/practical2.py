# DataFrame Creation
# Q. Create a Pandas DataFrame of at least four countries with the
# following details:
# • Population
# • Capital
# The country name should be the index.

import pandas as pd

data={
    "Population":[1000,2000,1500,4000],
    "Capital":["Mumbai","Lucknow","New Delhi","Ghaziabad"]
}
countries=["India","Dholakpur","USA","Russia"]

df=pd.DataFrame(data,index=countries)
print()
print("Q1")
print(df)

# Q. Data Inspection
# Using the created DataFrame:
# 1. Display the first few rows.
# 2. Display DataFrame information and column data types.

print()
print("Q2")
print("First 2 rows are :-\n",df.head(2))
print()
print(df.info())

# Q. Data Selection and Filtering
# 1. Display the population of a specific country.
# 2. Filter countries with population greater than a given value.

print()
print("Q3")
print("Population of Country India :-",df.loc["India"]["Population"])
print()
print("Countries with population greater than 1500 :-\n",df[df["Population"]>1500])

# Q. Data Manipulation
# 1. Add a new column named GDP.
# 2. Rename a column.
# 3. Remove one column from the DataFrame.

print()
print("Q4")
df["GDP"]=[10.0,21.4,12.7,13.9]
print("Added a new column GDP :-\n",df)

df.rename(columns={"Population" : "Population_Millions"},inplace=True)
print()
print("Renamed column Population :-\n",df)

print()
df.drop(columns={"GDP"},inplace=True)
print("Removed column GDP :-\n",df)

# Q. Aggregation and Sorting
# 1. Sort the DataFrame based on population.
# 2. Find the average population.

print()
print("Q5")
print("Sorted the DataFrame based on population :-\n",df.sort_values(by="Population_Millions"))
print()

print("Average Population is :-",df["Population_Millions"].mean())
print()
