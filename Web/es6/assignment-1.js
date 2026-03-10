// 1. Write a function using the rest operator that accepts any number of
// integers and returns their average.

function calAverage(...arr) {
    let sum = 0;
    arr.forEach((val) => sum += val);
    return sum / arr.length;
}

console.log(calAverage(1, 2, 3, 5, 5, 6));

// 2. Create a function that accepts student marks using the rest operator
// and returns the highest mark.

function highestMarks(...arr) {
    return Math.max(...arr);
}

console.log(highestMarks(50, 10, 52, 86, 99))

// 3. Merge three different arrays using the spread operator and
// display the result.

function merge(arr1, arr2, arr3) {
    return [...arr1, ...arr2, ...arr3];
}

console.log(merge([1, 2, 3], [4, 2, 1], [9, 7, 4]))

// 4. Copy an object representing an employee and update only the
// salary using the spread operator.

const employee = {
    "name": "ojasv",
    "salary": 150
}

const newdata = {
    ...employee,
    "salary": 200
}

console.log(newdata)

// 5. Write a function that accepts multiple strings using the rest operator
// and joins them into a single sentence.

function concat(...arr) {
    return arr.reduce((s, a) => s += a, "");
}

console.log(concat("ojasv ", "is ", "a ", "good ", "boy"))

// 6. Pass elements of an array as arguments to a function that calculates
// the maximum of three numbers using the spread operator.

function maxThree(a, b, c) {
    return Math.max(a, b, c)
}

console.log(maxThree(10, 29, 19))

// 7. Create two objects representing user profiles and merge them into a
// single object using the spread operator.

const p1 = {
    "name": "ojasv1",
    "age": 19
}
const p2 = {
    "email": "ojasvsingh191919@gmail.com",
    "DOB": "12-09-2000"
}

const n = { ...p1, ...p2 }

console.log(n)

// 8. Write a function that accepts n numbers using rest operator and
// returns the count of even numbers.

function count(...arr) {
    let c = 0;
    arr.forEach((v) => {
        if (v % 2 === 0) c += 1;
    })
    return c;
}

console.log(count(2, 3, 4, 5, 6))

// 9. Clone an array using the spread operator and add two new elements
// to the cloned array without modifying the original array.

let arra = [1, 2, 3, 4, 5]

let arra1 = [...arra]
arra1.push(1,2)

console.log(arra)
console.log(arra1)

// 10. Write a function that accepts a list of prices using the rest operator
// and returns the total bill amount.

function total(...arr){
    return arr.reduce((s,t)=>s+=t,0)
}

console.log(total(2,3,4,1,2,5))