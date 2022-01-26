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

/******************************************************************************
 * Builtins
 */

localStorage.setItem("Copy-Simple", JSON.stringify({
    "tape": { "left": ["0"], "right": ["1", "1"], "currentSymbol": "1", "emptySymbol": "0" },
    "currentState": "A",
    "finalState": "X",
    "rules": [
        { "currentState": "A", "currentSymbol": "0", "newSymbol": "0", "newState": "X", "moveDirection": "right" },
        { "currentState": "A", "currentSymbol": "1", "newSymbol": "_", "newState": "B", "moveDirection": "left" },
        { "currentState": "B", "currentSymbol": "1", "newSymbol": "1", "newState": "B", "moveDirection": "left" },
        { "currentState": "B", "currentSymbol": "0", "newSymbol": "1", "newState": "C", "moveDirection": "right" },
        { "currentState": "C", "currentSymbol": "1", "newSymbol": "1", "newState": "C", "moveDirection": "right" },
        { "currentState": "C", "currentSymbol": "0", "newSymbol": "0", "newState": "C", "moveDirection": "right" },
        { "currentState": "C", "currentSymbol": "_", "newSymbol": "1", "newState": "A", "moveDirection": "right" }
    ]
}));

localStorage.setItem("Copy-Interspace", JSON.stringify({
    "tape": { "left": ["0"], "right": ["1", "1"], "currentSymbol": "1", "emptySymbol": "0" },
    "currentState": "A",
    "finalState": "X",
    "rules": [
        { "currentState": "A", "currentSymbol": "0", "newSymbol": "0", "newState": "X", "moveDirection": "right" },
        { "currentState": "A", "currentSymbol": "1", "newSymbol": "_", "newState": "B1", "moveDirection": "left" },
        { "currentState": "B1", "currentSymbol": "1", "newSymbol": "1", "newState": "B1", "moveDirection": "left" },
        { "currentState": "B1", "currentSymbol": "0", "newSymbol": "_", "newState": "B2", "moveDirection": "left" },
        { "currentState": "B2", "currentSymbol": "1", "newSymbol": "1", "newState": "B2", "moveDirection": "left" },
        { "currentState": "B2", "currentSymbol": "0", "newSymbol": "1", "newState": "C1", "moveDirection": "right" },
        { "currentState": "C1", "currentSymbol": "1", "newSymbol": "1", "newState": "C1", "moveDirection": "right" },
        { "currentState": "C1", "currentSymbol": "0", "newSymbol": "0", "newState": "C1", "moveDirection": "right" },
        { "currentState": "C1", "currentSymbol": "_", "newSymbol": "0", "newState": "C2", "moveDirection": "right" },
        { "currentState": "C2", "currentSymbol": "1", "newSymbol": "1", "newState": "C2", "moveDirection": "right" },
        { "currentState": "C2", "currentSymbol": "0", "newSymbol": "0", "newState": "C2", "moveDirection": "right" },
        { "currentState": "C2", "currentSymbol": "_", "newSymbol": "1", "newState": "A", "moveDirection": "right" }
    ]
}));

localStorage.setItem("Sum-Decimal", JSON.stringify({
    "tape": { "left": ["3", "0"], "right": ["_"], "currentSymbol": "2", "emptySymbol": "_" },
    "currentState": "A",
    "finalState": "X",
    "rules": [
        { "currentState": "A", "currentSymbol": "4", "newSymbol": "3", "newState": "B+A", "moveDirection": "left" },
        { "currentState": "A", "currentSymbol": "3", "newSymbol": "2", "newState": "B+A", "moveDirection": "left" },
        { "currentState": "A", "currentSymbol": "2", "newSymbol": "1", "newState": "B+A", "moveDirection": "left" },
        { "currentState": "A", "currentSymbol": "1", "newSymbol": "0", "newState": "B+A", "moveDirection": "left" },
        { "currentState": "A", "currentSymbol": "0", "newSymbol": "0", "newState": "B", "moveDirection": "left" },
        { "currentState": "B+A", "currentSymbol": "0", "newSymbol": "1", "newState": "A", "moveDirection": "right" },
        { "currentState": "B+A", "currentSymbol": "1", "newSymbol": "2", "newState": "A", "moveDirection": "right" },
        { "currentState": "B+A", "currentSymbol": "2", "newSymbol": "3", "newState": "A", "moveDirection": "right" },
        { "currentState": "B+A", "currentSymbol": "3", "newSymbol": "4", "newState": "A", "moveDirection": "right" },
        { "currentState": "B+A", "currentSymbol": "4", "newSymbol": "5", "newState": "A", "moveDirection": "right" },
        { "currentState": "B+A", "currentSymbol": "5", "newSymbol": "6", "newState": "A", "moveDirection": "right" },
        { "currentState": "B+A", "currentSymbol": "6", "newSymbol": "7", "newState": "A", "moveDirection": "right" },
        { "currentState": "B+A", "currentSymbol": "7", "newSymbol": "8", "newState": "A", "moveDirection": "right" },
        { "currentState": "B", "currentSymbol": "8", "newSymbol": "7", "newState": "C+B", "moveDirection": "left" },
        { "currentState": "B", "currentSymbol": "7", "newSymbol": "6", "newState": "C+B", "moveDirection": "left" },
        { "currentState": "B", "currentSymbol": "6", "newSymbol": "5", "newState": "C+B", "moveDirection": "left" },
        { "currentState": "B", "currentSymbol": "5", "newSymbol": "4", "newState": "C+B", "moveDirection": "left" },
        { "currentState": "B", "currentSymbol": "4", "newSymbol": "3", "newState": "C+B", "moveDirection": "left" },
        { "currentState": "B", "currentSymbol": "3", "newSymbol": "2", "newState": "C+B", "moveDirection": "left" },
        { "currentState": "B", "currentSymbol": "2", "newSymbol": "1", "newState": "C+B", "moveDirection": "left" },
        { "currentState": "B", "currentSymbol": "1", "newSymbol": "0", "newState": "C+B", "moveDirection": "left" },
        { "currentState": "B", "currentSymbol": "0", "newSymbol": "0", "newState": "X", "moveDirection": "left" },
        { "currentState": "C+B", "currentSymbol": "0", "newSymbol": "1", "newState": "B", "moveDirection": "right" },
        { "currentState": "C+B", "currentSymbol": "1", "newSymbol": "2", "newState": "B", "moveDirection": "right" },
        { "currentState": "C+B", "currentSymbol": "2", "newSymbol": "3", "newState": "B", "moveDirection": "right" },
        { "currentState": "C+B", "currentSymbol": "3", "newSymbol": "4", "newState": "B", "moveDirection": "right" },
        { "currentState": "C+B", "currentSymbol": "4", "newSymbol": "5", "newState": "B", "moveDirection": "right" },
        { "currentState": "C+B", "currentSymbol": "5", "newSymbol": "6", "newState": "B", "moveDirection": "right" },
        { "currentState": "C+B", "currentSymbol": "6", "newSymbol": "7", "newState": "B", "moveDirection": "right" },
        { "currentState": "C+B", "currentSymbol": "7", "newSymbol": "8", "newState": "B", "moveDirection": "right" }
    ]
}));

localStorage.setItem("Invert-Two-Zeroes", JSON.stringify({
    "tape": { "left": ["1", "1", "0", "1"], "right": ["0"], "currentSymbol": "1", "emptySymbol": "0" },
    "currentState": "+2",
    "finalState": "X",
    "rules": [
        { "currentState": "+2", "currentSymbol": "1", "newSymbol": "1", "newState": "+2", "moveDirection": "left" },
        { "currentState": "+2", "currentSymbol": "0", "newSymbol": "1", "newState": "+1", "moveDirection": "left" },
        { "currentState": "+1", "currentSymbol": "1", "newSymbol": "1", "newState": "+1", "moveDirection": "left" },
        { "currentState": "+1", "currentSymbol": "0", "newSymbol": "1", "newState": "X", "moveDirection": "left" }
    ]
}));

localStorage.setItem("Infinite-Increment", JSON.stringify({
    "tape": { "left": ["0"], "right": ["0"], "currentSymbol": ".", "emptySymbol": "0" },
    "currentState": ">>.",
    "finalState": "X",
    "rules": [
        { "currentState": ">>.", "currentSymbol": "0", "newSymbol": "0", "newState": ">>.", "moveDirection": "right" },
        { "currentState": ">>.", "currentSymbol": "1", "newSymbol": "0", "newState": ">>.", "moveDirection": "right" },
        { "currentState": ">>.", "currentSymbol": ".", "newSymbol": ".", "newState": "++", "moveDirection": "left" },
        { "currentState": "++", "currentSymbol": "0", "newSymbol": "1", "newState": ">>.", "moveDirection": "right" },
        { "currentState": "++", "currentSymbol": "1", "newSymbol": "1", "newState": "++", "moveDirection": "left" }
    ]
}));

localStorage.setItem("Infinite-Decrement", JSON.stringify({
    "tape": { "left": ["0", "0", "1"], "right": ["0"], "currentSymbol": ".", "emptySymbol": "0" },
    "currentState": ">>.",
    "finalState": "X",
    "rules": [
        { "currentState": ">>.", "currentSymbol": "0", "newSymbol": "1", "newState": ">>.", "moveDirection": "right" },
        { "currentState": ">>.", "currentSymbol": "1", "newSymbol": "1", "newState": ">>.", "moveDirection": "right" },
        { "currentState": ">>.", "currentSymbol": ".", "newSymbol": ".", "newState": "--", "moveDirection": "left" },
        { "currentState": "--", "currentSymbol": "0", "newSymbol": "0", "newState": "--", "moveDirection": "left" },
        { "currentState": "--", "currentSymbol": "1", "newSymbol": "0", "newState": ">>.", "moveDirection": "right" }
    ]
}));

localStorage.setItem("Flood-Fill", JSON.stringify({
    "tape": { "left": [], "right": [], "currentSymbol": "0", "emptySymbol": "0" },
    "currentState": "<<",
    "finalState": "X",
    "rules": [
        { "currentState": "<<", "currentSymbol": "0", "newSymbol": "1", "newState": ">>", "moveDirection": "right" },
        { "currentState": "<<", "currentSymbol": "1", "newSymbol": "1", "newState": "<<", "moveDirection": "left" },
        { "currentState": ">>", "currentSymbol": "0", "newSymbol": "1", "newState": "<<", "moveDirection": "left" },
        { "currentState": ">>", "currentSymbol": "1", "newSymbol": "1", "newState": ">>", "moveDirection": "right" }
    ]
}));

localStorage.setItem("Sum-Binary", JSON.stringify({
    "tape": { "left": ["1", "0", "0", ";", "1", "1", "1", "0", ";"], "right": [";"], "currentSymbol": "1", "emptySymbol": "0" },
    "currentState": "S",
    "finalState": "X",
    "rules": [
        { "currentState": "S", "currentSymbol": "0", "newSymbol": "0", "newState": "S", "moveDirection": "left" },
        { "currentState": "S", "currentSymbol": "1", "newSymbol": "0", "newState": "L4", "moveDirection": "left" },
        { "currentState": "L4", "currentSymbol": "0", "newSymbol": "0", "newState": "L3", "moveDirection": "left" },
        { "currentState": "L4", "currentSymbol": "1", "newSymbol": "1", "newState": "L3", "moveDirection": "left" },
        { "currentState": "L4", "currentSymbol": ";", "newSymbol": ";", "newState": "L3", "moveDirection": "left" },
        { "currentState": "L3", "currentSymbol": "0", "newSymbol": "0", "newState": "L2", "moveDirection": "left" },
        { "currentState": "L3", "currentSymbol": "1", "newSymbol": "1", "newState": "L2", "moveDirection": "left" },
        { "currentState": "L3", "currentSymbol": ";", "newSymbol": ";", "newState": "L2", "moveDirection": "left" },
        { "currentState": "L2", "currentSymbol": "0", "newSymbol": "0", "newState": "L1", "moveDirection": "left" },
        { "currentState": "L2", "currentSymbol": "1", "newSymbol": "1", "newState": "L1", "moveDirection": "left" },
        { "currentState": "L2", "currentSymbol": ";", "newSymbol": ";", "newState": "L1", "moveDirection": "left" },
        { "currentState": "L1", "currentSymbol": "0", "newSymbol": "0", "newState": "W", "moveDirection": "left" },
        { "currentState": "L1", "currentSymbol": "1", "newSymbol": "1", "newState": "W", "moveDirection": "left" },
        { "currentState": "L1", "currentSymbol": ";", "newSymbol": ";", "newState": "W", "moveDirection": "left" },
        { "currentState": "W", "currentSymbol": "0", "newSymbol": "1", "newState": ">>;2", "moveDirection": "right" },
        { "currentState": "W", "currentSymbol": "1", "newSymbol": "0", "newState": "W", "moveDirection": "left" },
        { "currentState": ">>;2", "currentSymbol": "1", "newSymbol": "1", "newState": ">>;2", "moveDirection": "right" },
        { "currentState": ">>;2", "currentSymbol": "0", "newSymbol": "0", "newState": ">>;2", "moveDirection": "right" },
        { "currentState": ">>;2", "currentSymbol": ";", "newSymbol": ";", "newState": ">>;1", "moveDirection": "right" },
        { "currentState": ">>;1", "currentSymbol": "1", "newSymbol": "1", "newState": ">>;1", "moveDirection": "right" },
        { "currentState": ">>;1", "currentSymbol": "0", "newSymbol": "0", "newState": ">>;1", "moveDirection": "right" },
        { "currentState": ">>;1", "currentSymbol": ";", "newSymbol": ";", "newState": "1<<", "moveDirection": "left" },
        { "currentState": "1<<", "currentSymbol": "0", "newSymbol": "0", "newState": "1<<", "moveDirection": "left" },
        { "currentState": "1<<", "currentSymbol": "1", "newSymbol": "1", "newState": "S", "moveDirection": "right" },
        { "currentState": "1<<", "currentSymbol": ";", "newSymbol": ";", "newState": "X", "moveDirection": "left" }
    ]
}));
