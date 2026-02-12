# Spam detection using SVM

# Support Vector Machine is a supervised machine learning algorithm used for classification and refression tasks.
# Hyper plane should have maximum distance from both the groups
# SVM is robust to outliers :- Ignores the outliers
# Binary data classification 
# Hyperplane : A decision boundary separating  w:- weight , wx+b=0
# Support Vectors : The closest data points to the hyperplane, crucial for determining the hyperplane and margin in SVM
# Margin :  The distance between the hyperplane and the support vectors. SVM aims to maximuize this margin for better classification performance.

import kagglehub
import pandas as pd
import os
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split

path=kagglehub.dataset_download("ayeshasiddiqa123/student-perfirmance")
csv_path=os.path.join(path,"StudentPerformanceFactors.csv")

df=pd.read_csv(csv_path)

df=pd.get_dummies(df,drop_first=True)

X=df.drop(["Peer_Influence_Positive"],axis=1)
y=df["Peer_Influence_Positive"]

X_train,X_test,y_train,y_test=train_test_split(X,y,test_size=0.2,random_state=42)

scaler=StandardScaler()
X_train=scaler.fit_transform(X_train)
X_test=scaler.transform(X_test)

model=SVC(kernel='rbf',C=1,gamma='scale')

model.fit(X_train,y_train)

y_pred=model.predict(X_test)

print("Accuracy of model :",accuracy_score(y_test,y_pred))