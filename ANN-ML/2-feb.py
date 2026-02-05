import kagglehub
import os
import pandas as pd


path=kagglehub.dataset_download("ayeshasiddiqa123/student-perfirmance")

csv_file=os.path.join(path,"StudentPerformanceFactors.csv")
df=pd.read_csv(csv_file)

# print(df)

print(df.isnull().sum()/len(df)*100)

df.isnull().fillna(df[df.isnull()]=df.isnull().mean())