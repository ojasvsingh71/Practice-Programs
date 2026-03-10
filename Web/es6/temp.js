/*
===========================================================
ES6 Assignment - Moodle Template
Course: Web Technology / JavaScript ES6
Instructions:
- DO NOT change function names
- DO NOT modify driver function
- Implement logic only inside the marked sections
- Each function carries 1 mark
===========================================================
*/

const { MIN_VALUE } = require("long");
const { resolve } = require("path");

/*
-----------------------------------------------------------
DUMMY DATA (You may use these for testing)
-----------------------------------------------------------
*/

const numberArray = [10, 20, 30, 40];
const student = {
  name: "Aarav",
  age: 21,
  course: "B.Tech"
};

const extraInfo = {
  city: "Delhi",
  college: "KIET"
};

/*
-----------------------------------------------------------
FUNCTION 1
-----------------------------------------------------------
Purpose:
Accept multiple numbers using the REST operator and return their sum

Parameters:
- ...nums (rest parameter)

Constraints:
- Must use REST operator
- Return a single number (sum)

Base Test Cases:
sumNumbers(1, 2, 3) → 6
sumNumbers(10, 20) → 30
*/

function sumNumbers(...nums) {
  // STUDENT CODE STARTS HERE
  return nums.reduce((total, num) => total + num, 0);

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 2
-----------------------------------------------------------
Purpose:
Merge two arrays using the SPREAD operator

Parameters:
- arr1 (Array)
- arr2 (Array)

Constraints:
- Must use spread operator
- Must return a new array

Base Test Cases:
mergeArrays([1,2], [3,4]) → [1,2,3,4]
mergeArrays([], [5]) → [5]
*/

function mergeArrays(arr1, arr2) {
  // STUDENT CODE STARTS HERE
  return [...arr1, ...arr2];

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 3
-----------------------------------------------------------
Purpose:
Copy and update an object using the SPREAD operator

Parameters:
- obj (Object)
- newKey (String)
- newValue (Any)

Constraints:
- Must NOT modify original object
- Must return a new object

Base Test Cases:
updateObject({a:1}, "b", 2) → {a:1, b:2}
updateObject({}, "x", 10) → {x:10}
*/

function updateObject(obj, newKey, newValue) {
  // STUDENT CODE STARTS HERE
  return { ...obj, [newKey]: newValue };

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 4
-----------------------------------------------------------
Purpose:
Demonstrate passing array elements as function arguments using SPREAD

Parameters:
- arr (Array of numbers)

Constraints:
- Must use spread operator
- Must return the maximum number

Base Test Cases:
findMax([1,5,3]) → 5
findMax([10,2]) → 10
*/

function findMax(arr) {
  // STUDENT CODE STARTS HERE
  return Math.max(...arr);

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 5
-----------------------------------------------------------
Purpose:
Use ARRAY DESTRUCTURING to extract first and last elements

Parameters:
- arr (Array)

Constraints:
- Must use destructuring
- Return an object: { first, last }

Base Test Cases:
extractElements([10,20,30]) → {first:10, last:30}
extractElements([5]) → {first:5, last:5}
*/

function extractElements(arr) {
  // STUDENT CODE STARTS HERE
  let [first, ...rest] = [...arr];
  console.log(rest);
  let last = rest.length > 0 ? rest[rest.length - 1] : first;
  return `first: ${first}, last: ${last}`

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 6
-----------------------------------------------------------
Purpose:
Use OBJECT DESTRUCTURING and TEMPLATE LITERALS

Parameters:
- obj (Object with name and course)

Constraints:
- Must use destructuring
- Must use template literals

Return Format:
"Student <name> is enrolled in <course>"

Base Test Cases:
formatStudent({name:"Aarav", course:"B.Tech"})
→ "Student Aarav is enrolled in B.Tech"
*/

function formatStudent(obj) {
  // STUDENT CODE STARTS HERE
  let { name, course } = obj;
  return `Student ${name} is enrolled in ${course}`;

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 7
-----------------------------------------------------------
Purpose:
Demonstrate DEFAULT PARAMETERS

Parameters:
- a (Number, default = 5)
- b (Number, default = 10)

Constraints:
- Must use default values
- Return sum of a and b

Base Test Cases:
addDefault() → 15
addDefault(10, 5) → 15
*/

function addDefault(a = 5, b = 10) {
  // STUDENT CODE STARTS HERE
  return a + b;

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 8
-----------------------------------------------------------
Purpose:
Create a PROMISE that resolves after 2 seconds

Parameters:
- message (String)

Constraints:
- Must return a Promise
- Use setTimeout
- Resolve after 2000ms

Base Test Cases:
createSuccessPromise("Done")
→ Resolves with "Done"
*/

function createSuccessPromise(message) {
  // STUDENT CODE STARTS HERE
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      resolve(message);
    }, 2000)
  })

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 9
-----------------------------------------------------------
Purpose:
Create a PROMISE that rejects if condition fails

Parameters:
- condition (Boolean)

Constraints:
- If true → resolve("Success")
- If false → reject("Failed")

Base Test Cases:
createConditionalPromise(true) → Resolve
createConditionalPromise(false) → Reject
*/

function createConditionalPromise(condition) {
  // STUDENT CODE STARTS HERE
  return new Promise((resolve, reject) => {
    if (condition) resolve("Success");
    else reject("Failed")
  })

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 10
-----------------------------------------------------------
Purpose:
Consume a Promise using THEN and CATCH

Parameters:
- promise (Promise)

Constraints:
- Must use then() and catch()
- Print success or error message using console.log()

Base Test Cases:
handlePromise(createConditionalPromise(true))
→ "Success"

handlePromise(createConditionalPromise(false))
→ "Failed"
*/

function handlePromise(promise) {
  // STUDENT CODE STARTS HERE
  promise.then((resolve) => console.log(resolve)).catch((reject) => console.log(reject))

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 11 (DRIVER FUNCTION)
-----------------------------------------------------------
Purpose:
Test all student functions
DO NOT MODIFY THIS FUNCTION
-----------------------------------------------------------
*/

function driver() {
  console.log("---- ES6 ASSIGNMENT DRIVER START ----");

  console.log("Sum:", sumNumbers(1, 2, 3));
  console.log("Merged:", mergeArrays([1, 2], [3, 4]));
  console.log("Updated Object:", updateObject(student, "city", "Delhi"));
  console.log("Max Value:", findMax(numberArray));
  console.log("Extracted:", extractElements(numberArray));
  console.log("Formatted Student:", formatStudent(student));
  console.log("Default Add:", addDefault());

  const successPromise = createSuccessPromise("Operation Successful");
  const conditionPromise = createConditionalPromise(false);

  handlePromise(successPromise);
  handlePromise(conditionPromise);

  console.log("---- ES6 ASSIGNMENT DRIVER END ----");
}

/*
-----------------------------------------------------------
RUN DRIVER
-----------------------------------------------------------
*/

driver();
