const {ethers, network, run } = require("hardhat"); 
const { providers } = require("web3");

//NOTE: This Bot trades on the Arb network. 

//run localhost --> sudo npx hardhat run scripts/bot-server/OptimusPrimeBot.js --network localhost

//run arbMainnet --> sudo npx hardhat run scripts/server/OptimusPrimeBot.js --network arbMainnet

const optimusPrimeContract = "0x9805fF690bdb2CBd4d7b711F908Fb7A58e0fB623"; 

const pancakeV3router = "0x1b81D678ffb9C0263b24A97847620C99d213eB14"; 

const usdtAddress = "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9"; 

const usdcAddress = "0xaf88d065e77c8cC2239327C5EDb3A432268e5831"; 

const wethAddress = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"; 

const minAmountWethOut = 0; 

let optimusPrime; 
let usdcWethPancakePool; 
let usdtWethPancakePool; 

async function initializeBot(){

console.log(""); 
optimusPrime = await ethers.getContractAt("OptimusPrime", optimusPrimeContract); 
console.log("OptimusPrime is activating, address is: " + optimusPrimeContract); 
usdcWethPancakePool = await ethers.getContractAt("IPancakeV3Pool", "0x7fCDC35463E3770c2fB992716Cd070B63540b947"); 
usdtWethPancakePool = await ethers.getContractAt("IPancakeV3Pool", "0x389938CF14Be379217570D8e4619E51fBDafaa21"); 
setInterval(() => {
    searchForGoodTradeOpportunities();
}, 8000);   //run every 8 seconds
}

async function searchForGoodTradeOpportunities(){
let isUsdcWethPriceHigher; 
let isUsdtWethPriceHigher; 
let diff; 
const getUsdcWethSlot0 = await usdcWethPancakePool.slot0(); 
const getUsdtWethSlot0 = await usdtWethPancakePool.slot0(); 
const usdcWethSqrtPrice = parseInt(getUsdcWethSlot0[0]); 
const usdtWethSqrtPrice = parseInt(getUsdtWethSlot0[0]); 
const usdcWethPrice = ((usdcWethSqrtPrice**2)/(2**192))*(10**(1e18-1e18)); 
const usdtWethPrice = ((usdtWethSqrtPrice**2)/(2**192))*(10**(1e18-1e18)); 
console.log("USDC / WETH price is " + usdcWethPrice.toString().substring(0, 5).replace('.', ''));
console.log("USDT / WETH price is " + usdtWethPrice.toString().substring(0, 5).replace('.', ''));

if(usdcWethPrice > usdtWethPrice){
isUsdcWethPriceHigher = true; 
isUsdtWethPriceHigher = false; 
diff = ((usdcWethPrice / usdtWethPrice) - 1) * 100;
console.log("USDC / WETH price is higher by " + diff + " % "); 
console.log(""); 
}else{
isUsdcWethPriceHigher = false; 
isUsdtWethPriceHigher = true; 
diff =  ((usdtWethPrice / usdcWethPrice) - 1) * 100;
console.log("USDT / WETH price is higher by " + diff + " % "); 
console.log(""); 
}

if(diff > 0.16 ){
   if(isUsdcWethPriceHigher == true){
    call_trade4(); 
   }else{
    call_trade3(); 
   }
 }
}

//USDC --> WETH --> USDT --> USDC
async function call_trade3(){
try{
const getEncodedPath = await optimusPrime.returnPathData(usdcAddress, 100, wethAddress); 
const getContractUsdcBalance = await optimusPrime.returnTokenBalance(usdcAddress); 
const deadline = await optimusPrime.returnBlockTimestamp(); 
const deadlineUint = parseInt(deadline); 
const params = [getEncodedPath, optimusPrimeContract, deadlineUint + 2, getContractUsdcBalance, 0]; 
const tx = await optimusPrime.trade3(params, {gasPrice: 10000000}); 
await tx.wait(); 
console.log("✅ Possible profit made calling trade3 func ✅"); 
console.log(""); 
}catch(e){
console.log("❌ No possible profit made calling trade3 func ❌"); 
console.log(""); 
}
}


//USDT --> WETH --> USDC --> USDT
async function call_trade4(){}

try{
initializeBot(); 
}catch(e){
console.log("Oops, there's an error: " + e); 
}