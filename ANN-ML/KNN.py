# K-nearest neighbours (KNN)
# "Tell me your neighbor, I'll tell who you are"

import numpy as np
import kagglehub
import os
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import accuracy_score

path=kagglehub.dataset_download("ayeshasiddiqa123/student-perfirmance")
csv_path=os.path.join(path,"StudentPerformanceFactors.csv")

df=pd.read_csv(csv_path)

df=pd.get_dummies(df,drop_first=True)
# print(df.columns)
X=df.drop(["Peer_Influence_Positive"],axis=1)
y=df["Peer_Influence_Positive"]

X_train,X_test,y_train,y_test=train_test_split(X,y,test_size=0.2,random_state=42)

scaler=StandardScaler()
X_train=scaler.fit_transform(X_train)
X_test=scaler.transform(X_test)

model=KNeighborsClassifier(n_neighbors=5)
model.fit(X_train,y_train)

y_pred=model.predict(X_test)

print("Accuracy:", accuracy_score(y_test, y_pred))