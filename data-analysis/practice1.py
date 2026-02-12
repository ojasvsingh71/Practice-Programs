import numpy as np

oneD=np.array([1,2,3])
twoD=np.array([[1,2,3,1,2],[4,5,6,1,2]])

print(oneD)

print(twoD.shape)

print(twoD.reshape(2,5))

z=np.zeros(5)
o=np.ones(5)

print(z)
print(o)

val=np.array(2*5*[0]).reshape(2,5)

val[:,0]=1

print(val)

arr = np.hstack((np.zeros((5, 2)), np.ones((5, 2))))
print(arr)
print()
arr2 = np.vstack((np.ones((1, 4)), np.zeros((1, 4)), np.ones((1, 4))))
print(arr2)

first=np.arange(10)
second=2*np.arange(10)


first=np.ones((5,))
second=np.zeros((5,2))

# first row -1
# second row 0
# third row 2


val=np.arange(3*5).reshape(3,5)

val[0,:]=-1
val[1,:]=0
val[2,:]=2

print(val)

arr = np.vstack((
   -1* np.ones((1, 4)),
    np.zeros((1, 4)),
    2 * np.ones((1, 4))
))
print(arr)