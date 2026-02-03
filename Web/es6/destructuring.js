const arr = [1, 2, 3];
const [first, second, third, fourth] = arr;

console.log(first, second, third, fourth)

const [a, d, b = 10, c = 20] = [1];

console.log(a, d, b, c);