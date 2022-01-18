const root = document.getElementById("app");

const app = Elm.Main.init({
    node: root
});

/******************************************************************************
 * Port subscriptions
 */

app.ports.centerCurrentTapeCell.subscribe(() => {
    setTimeout(() => {
        const tape = document.querySelector(".tape");
        const currentTapeCell = tape.querySelector(".current");
        tape.scrollTo({
            top: 0,
            left: currentTapeCell.offsetLeft - currentTapeCell.offsetWidth * 3,
            behavior: "smooth"
        });
    }, 250);
});

app.ports.scrollTape.subscribe((offsetCells) => {
    const tape = document.querySelector(".tape");
    const currentTapeCell = tape.querySelector(".current");
    tape.scrollLeft = tape.scrollLeft + offsetCells * currentTapeCell.offsetWidth;
});

app.ports.saveMachine.subscribe(([name, data]) => {
    let isAllowedToWriteData = true;
    if (localStorage.getItem(name)) {
        isAllowedToWriteData = confirm("There is already a saved machine with same name, do you want to overwrite data?");
    }
    if (isAllowedToWriteData) {
        localStorage.setItem(name, JSON.stringify(data));
    }
})

app.ports.getSavedMachines.subscribe(() => {
    app.ports.onGetSavedMachinesSuccess.send(Array.from(Object.entries(localStorage)));
});

app.ports.provideBuiltinMachines.subscribe((builtinMachines) => {
    for (const [name, data] of builtinMachines) {
        localStorage.setItem(name, JSON.stringify(data));
    }
    app.ports.onProvideBuiltinMachinesSuccess.send(null);
});

/******************************************************************************
 * Saved machine links positioning
 */

const hashCode = (string) =>
    string.split('').reduce((a, b) => {
        a = ((a << 5) - a) + b.charCodeAt(0);
        return a & a
    }, 0);

const RNG = (seed) => {
    let x = hashCode(seed);
    return () => {
        x = Math.sin(x) * 10000;
        return x - Math.floor(x);
    };
};

const resetSavedMachineLinkPositions = () => {
    for (const node of root.childNodes) {
        if (node.nodeName == "A") {
            node.removeAttribute("positioned");
        }
    }
};

const invalidateSavedMachineLinkPositions = () => {
    for (const node of root.childNodes) {
        if (node.nodeName == "A" && !node.getAttribute("positioned")) {
            resetSavedMachineLinkPositions();
            break;
        }
    }
    const rootBounds = root.getBoundingClientRect();
    for (const node of root.childNodes) {
        if (node.nodeName == "A") {
            const rng = RNG(node.textContent);
            let left = rootBounds.left + rootBounds.width / 2;
            let top = rootBounds.top + rootBounds.height / 2;
            while (
                left > rootBounds.left - 64 &&
                left < rootBounds.right &&
                top > rootBounds.top - 64 &&
                top < rootBounds.bottom
            ) {
                left = rng() * (window.innerWidth - 128);
                top = rng() * (window.innerHeight - 64);
            }
            node.setAttribute("style", `left:${left}px;top:${top}px`);
            node.setAttribute("positioned", "true");
        }
    }
    requestAnimationFrame(invalidateSavedMachineLinkPositions);
};

window.addEventListener("resize", () => {
    resetSavedMachineLinkPositions();
});

invalidateSavedMachineLinkPositions();

/******************************************************************************
 * Saved machines removal
 */

let currentlyHoveredSavedMachineLink = null;

window.addEventListener("mouseover", (e) => {
    if (e.target.nodeName === "A") {
        currentlyHoveredSavedMachineLink = e.target;
    } else {
        currentlyHoveredSavedMachineLink = null;
    }
});

window.addEventListener("keydown", (e) => {
    if (currentlyHoveredSavedMachineLink && (e.key === "Delete" || e.key === "Backspace")) {
        const savedMachineName = currentlyHoveredSavedMachineLink.innerText;
        if (confirm(`Do you want to delete the save called ${savedMachineName}?`)) {
            localStorage.removeItem(savedMachineName);
            app.ports.onDeleteMachineSuccess.send(savedMachineName);
        }
    }
});
