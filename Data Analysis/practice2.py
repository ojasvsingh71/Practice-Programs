
# Dataset Practice :-
# mean, max,mini ,avg, conditional and comparison operators

import kagglehub
import os
import pandas as pd

path = kagglehub.dataset_download("ashrafkhetran/the-movies-database-tmdb-1950-2025")

print(path)

csv_path=os.path.join(path,"tmdb_movies.csv")

df=pd.read_csv(csv_path)

print("Dataset :- \n",df)

print()

print("First 3 rows :- \n",df.head(3))

print()
print("Last 3 rows :- \n",df.tail(3))

print()

print(df.info())

print()

print("Sum of budget :-",df["budget"].sum())
print("Mean of revenue :-",df["revenue"].mean())
print("Runtime Min :-",df["runtime"].min())
print("Runtime Max :-",df["runtime"].max())

print("Data with vote average greater than 2.5\n",df[df["vote_average"]>2.5])