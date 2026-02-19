// 1. Write ES6 code script to:
// a. Create a function using the rest operator to accept multiple numbers and return thier sum.
// b. Merge two arrays using the spread operator.
// c. Copy and update an object using the spread operator.
// d. Demonstrate passing array element as function arguments using spread

// 2. Write ES6 Promise that:
// e. Resolves after 2 seconds with a success meassage.
// f. Rejects if a condition fails.
// g. Consume the Promise using then() and catch().
// h. Display appropriate success or error messages.

// Function that returns a Promise
const fetchdata = () => {
    // Create a new Promise with executor function (resolve, reject)
    return new Promise((resolve, reject) => {
        // Flag to determine if operation succeeds or fails
        let success = false;

        // Set a timer to resolve/reject after 2 seconds
        setTimeout(() => {
            // Check if operation was successful
            if (success) {
                // e. Resolve the promise with success message after 2 seconds
                resolve("Success!!!");
            } else {
                // f. Reject the promise if condition fails
                reject("Failed!!!");
            }
        }, 2000); // 2 second delay

    })
        // g. Consume the promise using then() for success
        .then((res) => {
            // h. Display success message
            console.log(res);
        })
        // g. Consume the promise using catch() for error handling
        .catch((error) => {
            // h. Display error message
            console.log(error);
        })
        // Optional: finally block executes regardless of success/failure
        .finally(() => {
            console.log("Done!!!");
        });
};

// Test the promise
console.log("Data coming after 2 seconds --");
fetchdata();



// const getData = (dataId, getNextData) => {
//     setTimeout(() => {
//         console.log("data", dataId)
//         if (getNextData) {
//             getData()
//         }
//     }, 2000)
// }

// getData(1, () => {
//     console.log("getting data2...");
//     getData(2);
// })