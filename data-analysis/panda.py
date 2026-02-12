import pandas as pd
import numpy as np
import kagglehub
import os

# pop=pd.Series([20,30,40,50], index=['ca','as','sd','lo'])

# print(pop)

path = kagglehub.dataset_download("vishardmehta/indian-engineering-college-placement-dataset")

# print("Path to dataset files:", path)

# csv_path=os.path(path)
csv_path=os.path.join(path,"indian_engineering_student_placement.csv")
df=pd.read_csv(csv_path)

# print(df)

print(df.shape)
print(df.columns)