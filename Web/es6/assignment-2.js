// 1. Create a Promise that resolves after 1 second with the message
// “Welcome to JavaScript Promises” and consume it using
// then().

const { resolve } = require("path");

const p1 = new Promise((resolve, reject) => {
    setTimeout(() => {
        resolve("Welcome to JavaScript Promises")
    }, 1000);
}).then((data) => console.log(data))

p1

// 2. Write a Promise that rejects if a number is negative, otherwise
// resolves with “Valid number”.

const check=(num)=>{
    return new Promise((resolve,reject)=>{
        if(num<0){
            reject("Negative");
        }else resolve("Valid number")
    })
    .then((data)=>console.log(data))
    .catch((data)=>console.log(data))
}

[1,-2].forEach((num)=>{
    check(num)
})

// 3. Create a Promise that checks whether a user is logged in and
// displays appropriate messages using then() and catch().

const p2=new Promise((resolve,reject)=>{
    let login=true;
    if(login) resolve("IN");
    else reject("OUT")
}).then((data)=> console.log(data))
.catch((data)=>console.log(data))

p2

// 4. Write a Promise that simulates online payment success or failure
// using setTimeout().

const p3=new Promise((resolve,reject)=>{
    console.log("Transction Started")
    setTimeout(() => {
        let success=0.5>Math.random();
        if(success) resolve("Success");
        else reject("Failed")
    }, 3000);
}).then((data)=> console.log(data))
.catch((data)=>console.log(data))

p3