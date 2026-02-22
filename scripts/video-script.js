// STRICTLY FOR EDUCATION & PRACTICE PURPOSE //



(async function () {

    console.log("Starting stable auto workflow...");

    function wait(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    function waitForPageLoad(timeout = 15000) {
        return new Promise(resolve => {
            const start = Date.now();

            const interval = setInterval(() => {
                if (document.readyState === "complete") {
                    clearInterval(interval);
                    resolve(true);
                }

                if (Date.now() - start > timeout) {
                    clearInterval(interval);
                    resolve(false);
                }
            }, 500);
        });
    }

    const modules = document.querySelectorAll(".activeProd");

    if (modules.length === 0) {
        console.log("No modules found.");
        return;
    }

    for (let i = 0; i < modules.length; i++) {

        console.log("Processing module", i + 1);

        const module = modules[i];

        const getStarted = module.querySelector("button.getStarted");
        if (!getStarted) continue;

        getStarted.click();
        await wait(2000);

        const viewContent = document.querySelector(".post_cont_view_content");
        if (!viewContent) continue;

        const idMatch = viewContent.id.match(/\d+/);
        if (!idMatch) continue;

        const productId = idMatch[0];

        if (typeof pre_mark_as_complete === "function") {
            pre_mark_as_complete(productId, 'false');
        }

        await wait(2000);

        let markBtn = document.getElementById("markasComplete");

        let attempts = 0;
        while ((markBtn?.disabled) && attempts < 15) {
            await wait(1000);
            markBtn = document.getElementById("markasComplete");
            attempts++;
        }

        if (markBtn && !markBtn.disabled) {
            markBtn.click();
            console.log("Clicked Mark as Complete");

            // ✅ WAIT for reload or completion
            await waitForPageLoad();
            await wait(3000);
        } else {
            console.log("Mark button not enabled.");
        }
    }

    console.log("Workflow finished.");

})();