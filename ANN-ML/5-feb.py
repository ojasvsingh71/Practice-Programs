import pandas as pd
import kagglehub
import os

path=kagglehub.dataset_download("ayeshasiddiqa123/student-perfirmance")
csv_file = os.path.join(path, "StudentPerformanceFactors.csv")  # adjust name if needed
df = pd.read_csv(csv_file)

# Cleaning & Transforming an incomplete and noisy dataset
# common data issues:
# missing values
# outlers

# (a) Removing duplicates
df.drop_duplicates(inplace=True)

# (b) Handling outliers(using IQR method)
q1=df['Salary'].quantile(0.25)
q3=df['Salary'].quantile(0.75)
IQR=q3-q1

df=df[(df['Salary']>=q1-1.5*IQR) &
      (df['Salary']<=q3+1.5*IQR)]

# (c) Feature scaling(Normalization, Standardidation & )

from sklearn.preprocessing import StandardScaler

scaler=StandardScaler()
df[['Age','Salary']]=scaler.fit_transform(df[['Age','Salary']])

# Algo like Linear Regression/PCA

# (Normatization [0 to 1])

from sklearn.preprocessing import MinMaxScaler

scaler=MinMaxScaler()
df[['Age','Salary']]=scaler.fit_transform(df[['Age','Salary']])
# KNN ,Neural Networks

# (d) Noise reduction (smoothing -example)
df['Sales']=df['Sales'].rolling(window=3).mean()

