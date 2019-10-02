const path = require("path");
const solc = require("solc"); 
const fs = require("fs-extra"); 

// Fetch paths
const buildPath = path.resolve(__dirname, "build/contracts");
const contractspath = path.resolve(__dirname, "contracts");
const interfacesPath = path.resolve(__dirname, "contracts/interfaces");
const librariesPath = path.resolve(__dirname, "contracts/libraries");

// Removes folder build/contracts and every file in it
fs.removeSync(buildPath);

// Fetch all Contract files, interfaces and libraries in Contracts folder
const fileNames = fs.readdirSync(contractspath);
const interfacesNames = fs.readdirSync(interfacesPath);
const librariesNames = fs.readdirSync(librariesPath);

// Get source code of all interfaces FIRST
let input = interfacesNames.reduce(
    (input, fileName) => {
        const filePath = path.resolve(__dirname, "contracts/interfaces", fileName);
        const source = fs.readFileSync(filePath, "utf8");
        return {
            sources: { ...input.sources, [fileName]: {content: source} },
        };
    },
    { 
        sources: {},
    }
);

// Get source code of all libraries SECOND
input = librariesNames.reduce(
    (input, fileName) => {
        const filePath = path.resolve(__dirname, "contracts/libraries", fileName);
        const source = fs.readFileSync(filePath, "utf8");
        return {
            sources: { ...input.sources, [fileName]: {content: source} },
        };
    },
    input
);

// Get source code of all contracts AS LAST
input = fileNames.reduce(
    (input, fileName) => {
        if(fileName !== "interfaces" && fileName !== "libraries") {
            const filePath = path.resolve(__dirname, "contracts", fileName);
            const source = fs.readFileSync(filePath, "utf8");
            return {
                sources: { ...input.sources, [fileName]: {content: source} },
            };
        } else return input;
    },
    input
);

// Auxiliary callback function for solc.compile to find all the imports
function findImports(importedPath) {
    if(importedPath.search("interfaces") >= 0) {
        const fileName = importedPath.split("/").pop();
        const filePath = path.resolve(__dirname, "contracts/interfaces", fileName);
        return {
            contents: fs.readFileSync(filePath, "utf8")
        }

    } else if(importedPath.search("libraries") >= 0) {
        const fileName = importedPath.split("/").pop();
        const filePath = path.resolve(__dirname, "contracts/libraries", fileName);
        return {
            contents: fs.readFileSync(filePath, "utf8")
        }

    } else if(importedPath.search("\./") >= 0) {
        const fileName = importedPath.split("/").pop();
        const filePath = path.resolve(__dirname, "contracts/interfaces", fileName);
        return {
            contents: fs.readFileSync(filePath, "utf8")
        }

    } else {
        return {error: "Can't find the importing file ".concat(importedPath)}
    }
}

// Create input object for solc.compile according to
// https://solidity.readthedocs.io/en/v0.5.0/using-the-compiler.html#compiler-input-and-output-json-description
const compilingObject = { 
    language: 'Solidity',
    sources: input.sources,
    settings: {
        optimizer: {
            enabled: true,
            runs: 10
        },
        outputSelection: {
            '*': {
                '*': ['*']
            }
        }
    }
}

// compìle all contracts finding also the imports
const output = JSON.parse(solc.compile(JSON.stringify(compilingObject), findImports));

// Re-Create build/contracts folder for output files from each contract
fs.ensureDirSync(buildPath);

// Output contains all objects from all contracts
// Write the contents of each to different files
try {
    for (let contract in output.contracts) {
        let fileName = contract.split(".")[0];

        if(fileName.search("interfaces") >= 0 || fileName.search("libraries") >= 0) fileName = fileName.split("/")[1];

        console.log("Writing JSON file for compiled ".concat(fileName))

        fs.outputJsonSync(
            path.resolve(buildPath, fileName + ".json"),
            {
                abi: output.contracts[contract][fileName].abi,
                bytecode: '0x'.concat(output.contracts[contract][fileName].evm.bytecode.object)
            }
        );
    }

    console.log("ABI and Bytecode of each corresponding contract has been saved under build/contracts directory")
} catch(error) {
    console.log(error);
}
