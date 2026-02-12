const fetchdata = new Promise((resolve) => {
    setTimeout(() => {
        resolve("Data loaded!")
    }, 1000);
});

fetchdata.then((data) => console.log(data))