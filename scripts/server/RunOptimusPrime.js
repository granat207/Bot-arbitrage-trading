const {ethers, network, run } = require("hardhat"); 
const Web3 = require("web3");
//NOTE: This Bot trades on the Bsc. 

//run localhost --> sudo npx hardhat run scripts/bot-server/OptimusPrimeBot.js --network localhost

//run bscMainnet(Forked) --> sudo npx hardhat run scripts/bot-server/OptimusPrimeBot.js --network hardhat

//run arbMainnet --> sudo npx hardhat run scripts/server/RunOptimusPrime.js --network arbMainnet

const optimusPrimeContract = ""; 

const uniswapV3router = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"; 

const pancakeV3router = "0x32226588378236Fd0c7c4053999F88aC0e5cAc77"; 

const usdtAddress = "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9"; 

const wethAddress = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"; 

const minAmountWethOut = 0; 

const wethUniswapPoolFee = 100; 

const wethPancakePoolFee = 100; 

const expectedGas = 0; 


let optimusPrime; 

async function initializeBot(){

console.log(""); 
optimusPrime = await ethers.getContractAt("OptimusPrime", optimusPrimeContract); 
console.log("OptimusPrime is activating, address is: " + optimusPrimeContract); 

setInterval(runBot, 10000); 
}

async function runBot(){
    


}

try{
initializeBot(); 
}catch(e){
console.log("Oops, there's an error: " + e); 
}