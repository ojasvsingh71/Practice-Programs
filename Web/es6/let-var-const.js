function varExample() {
    console.log(x);
    var x = 1;
    console.log(x);
    if (true) {
        var x = 2;
        console.log("Inside Block :- " + x);
    }
    console.log("Outside Block :- " + x);
}

varExample();

function letExample() {
    // console.log(x);
    let x = 1;
    console.log(x);
    if (true) {
        let x = 2;
        console.log("Inside Block :- " + x);
    }
    console.log("Outside Block :- " + x);
}

letExample();

const arr = [1, 2];
arr.push(3);
console.log(arr);
// arr=[2]               // Error