// 1. Write ES6 code script to:
// a. Create a function using the rest operator to accept multiple numbers and return thier sum.
// b. Merge two arrays using the spread operator.
// c. Copy and update an object using the spread operator.
// d. Demonstrate passing array element as function arguments using spread

// // 2. Write ES6 Promise that:
// // e. Resolves after 2 seconds with a success meassage.
// // f. Rejects if a condition fails.
// // g. Consume the Promise using then() and catch().
// // h. Display appropriate success or error messages.

console.log("Q2.")

const fetchdata = async () => {
    for (let i = 0; i < 7; i++) {
        await new Promise((resolve, reject) => {
            const success = i % 2 === 0
            setTimeout(() => {

                if (success) {
                    resolve("Sucess!!!")
                } else {
                    reject("Failed!!!")
                }
            }, 2000)


        }).then((res) => console.log(res)).catch((error) => console.log(error)).finally(() => console.log("Chonchu"))
    }
};

console.log("Data comming after 2 seconds --")





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