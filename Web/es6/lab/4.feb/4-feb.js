// Hello World
console.log("Hello world")

// Sum of n numbers
let sum = 0;
for (let i = 1; i <= 10; i++) {
    sum += i;
}
console.log("Sum of numbers in the range 1-10 :-", sum);

// Total number of even number in the range if of 1-n
let even = 0;
for (let i = 1; i <= 10; i++) {
    if (i % 2 == 0) even++;
}
console.log("Even numbers in the range of 1-10 :-", even)

// Max of 3 numbers
let a = 5, b = 1, c = 10;
console.log("Max of a,b,c :-", Math.max(a, b, c));

// Factorial
let n = 10, fac = 1;
for (let i = n; i >= 2; i--) fac *= i;
console.log("Factorial of", n, "is", fac)

// Reverse
n = 12345
let temp = n;
let rev = 0;
while (n > 0) {
    rev = rev * 10 + n % 10
    n = Math.floor(n / 10);
}
console.log("Reverse of", temp, "is", rev)

// Palindrome
let s1, s2 = ["ojasv", "naman"]


// sum of array
// function (square)
// object