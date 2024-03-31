const {ethers, network, run } = require("hardhat"); 

//NOTE: This Bot trades on the Arbitrum blockchain. 

//run localhost --> sudo npx hardhat run scripts/deploy/DeployOptimusPrime.js --network localhost

//run on ARB mainnet --> sudo npx hardhat run scripts/deploy/DeployOptimusPrime.js --network arbMainnet

//run on forked mainnet --> sudo npx hardhat run scripts/deploy/DeployOptimusPrime.js --network hardhat

//verify contract --> sudo npx hardhat verify --network arbMainnet CONTRACT_ADDRESS 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45 0x32226588378236Fd0c7c4053999F88aC0e5cAc77

async function deploy(){
    
console.log(""); 

                                                                                  //uniswapRouter                                  //pancakeRouter
const optimusPrime = await ethers.deployContract("OptimusPrime", ["0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45", "0x32226588378236Fd0c7c4053999F88aC0e5cAc77"]); 
console.log("🤖 OptimusPrime 🤖 deployed, address is :", await optimusPrime.getAddress());

}


try{
deploy(); 
}catch(e){
console.log("Oops, there's an error: " + e); 
}