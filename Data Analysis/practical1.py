import numpy as np

x = np.array([
 [10, 12, 14, 16, 18],
 [20, 22, 24, 26, 28],
 [30, 32, 34, 36, 38],
 [40, 42, 44, 46, 48]
])

# Q1. Array Creation and Properties
# Using the dataset x:
# 1. Display the shape, size, and datatype of the array.
# 2. Find the sum of all elements in the dataset.

print("Q1")
print("Shape :-",x.shape)
print("Size :-",x.size)
print("DataType :-",x.dtype)

print("Sum :-",np.sum(x))
print()

# Q2. Even Value Extraction
# From the same dataset x:
# 1. Create a 1-D NumPy array that contains only even values.
# 2. Count the total number of even elements.

print("Q2")
even=x[x%2==0]
print("1-D array of only even numbers :-",even)
print("Total number of even numbers :-",len(even))

print()

# Q3. Indexing and Slicing
# Using the dataset x:
# 1. Extract the third column.
# 2. Extract the second row.
# 3. Extract a sub-matrix consisting of rows 2–3 and columns 3–5.

print("Q3")

print("3rd column :-",x[:,2])
print("2nd row :-",x[1,:])
print("Sub-matrix consisting of rows 2–3 and columns 3–5 :-\n",x[1:3,2:5])
print()

# Q4. Array Modification
# Using the same dataset:
# 1. Replace all values greater than 30 with −1.
# 2. Set the fourth row to [1, 2, 3, 4, 5].

print("Q4")

x[x>30]=-1
print("All values greater than 30 replaced by −1 :-\n",x)

x[3:]= [1, 2, 3, 4, 5]
print("Modified row :-\n",x)
print()

# Q5. Boolean Indexing (Single-Line Operations)
# Given:
# names = np.array(["Roxana", "Statira", "Roxana", "Statira",
# "Roxana"])
# scores = np.array([126, 115, 130, 141, 132])
# Perform the following using vectorized NumPy operations:
# 1. Extract all scores less than 130.
# 2. Extract all scores of Statira.
# 3. Add 10 marks to Roxana’s scores only.

print("Q5")

names = np.array(["Roxana", "Statira", "Roxana", "Statira","Roxana"])
scores = np.array([126, 115, 130, 141, 132])

fil=scores[scores<130]
print("Scores less than 130 :-",fil)

statira_scores=scores[names=="Statira"]
print("All scores of Statira :-",statira_scores)

scores[names=="Roxana"]+=10
print("Modified scores by Roxana:-",scores)

print()