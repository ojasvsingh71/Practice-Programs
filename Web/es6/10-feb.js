// 1. Write ES6 code :-
// A. Create a function using the rest operator to accept multiple numbers and retturn their sum

// function add(...numbers){
//     return numbers.reduce((total,num)=> total+=num,0);
// }

const add = (...numbers) => {
    let sum = 0;
    for (let i of numbers) {
        sum += i;
    } return sum
}

console.log(add(1, 2, 3, 4, 5, 6))


// B. Merge two arrays using the spread operator

const array1 = [1, 2, 3]
const array2 = [4, 5, 6]

console.log([...array1, ...array2])


// C. Copy and update an object using the spread operator

const copy = [...array1, ...[6, 8], ...array1]
copy[1] = 10

console.log(copy)

const student = {
    name: "ojasv",
    age: 19,
    city: "Lucknow"
}

student.age = 20;

console.log(student)

// D.Passing array elements as function arguments using spead 

array3=[1,2,3];
const multiply=(a,b)=>{
    return a*b;
}

console.log(multiply(...array3))