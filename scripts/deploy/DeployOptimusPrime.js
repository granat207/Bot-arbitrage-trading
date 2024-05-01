const {ethers, network, run } = require("hardhat"); 

//NOTE: This Bot trades on the Arbitrum blockchain. 

//run localhost --> sudo npx hardhat run scripts/deploy/DeployOptimusPrime.js --network localhost

//run on ARB mainnet --> sudo npx hardhat run scripts/deploy/DeployOptimusPrime.js --network arbMainnet

//verify contract --> sudo npx hardhat verify --network arbMainnet CONTRACT_ADDRESS 0x1b81D678ffb9C0263b24A97847620C99d213eB14

async function deploy(){
    
console.log(""); 

                                                                  
const optimusPrime = await ethers.deployContract("OptimusPrime", ["0x1b81D678ffb9C0263b24A97847620C99d213eB14"]); 
console.log("🤖 OptimusPrime 🤖 deployed, address is :", await optimusPrime.getAddress());

}


try{
deploy(); 
}catch(e){
console.log("Oops, there's an error: " + e); 
}