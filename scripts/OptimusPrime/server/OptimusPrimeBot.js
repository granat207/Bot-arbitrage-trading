const {ethers, network, run } = require("hardhat"); 
const { providers } = require("web3");

//NOTE: This Bot trades on the Arb network. 

//run localhost --> sudo npx hardhat run scripts/OptimusPrime/bot-server/OptimusPrimeBot.js --network localhost

//run arbMainnet --> sudo npx hardhat run scripts/OptimusPrime/server/OptimusPrimeBot.js --network arbMainnet

const optimusPrimeContract = "0xd10C111eF437D64F32731eCbCA8F86738E76F911"; 

const pancakeV3router = "0x1b81D678ffb9C0263b24A97847620C99d213eB14"; 

const usdtAddress = "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9"; 

const usdcAddress = "0xaf88d065e77c8cC2239327C5EDb3A432268e5831"; 

const wethAddress = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"; 

let optimusPrime; 
let wethUsdcPancakePool; 
let wethUsdtPancakePool; 

async function initializeBot(){

console.log(""); 
optimusPrime = await ethers.getContractAt("OptimusPrime", optimusPrimeContract); 
console.log("OptimusPrime is activating, address is: " + optimusPrimeContract); 
wethUsdcPancakePool = await ethers.getContractAt("IPancakeV3Pool", "0x7fCDC35463E3770c2fB992716Cd070B63540b947"); 
wethUsdtPancakePool = await ethers.getContractAt("IPancakeV3Pool", "0x389938CF14Be379217570D8e4619E51fBDafaa21"); 
setInterval(() => {
    searchForGoodTradeOpportunities();
}, 2000);   //run every 2 seconds
}

async function searchForGoodTradeOpportunities(){
let isWethUsdcPriceHigher; 
let isWethUsdtPriceHigher; 
let diff; 
const getWethUsdcSlot0 = await wethUsdcPancakePool.slot0(); 
const getWethUsdtSlot0 = await wethUsdtPancakePool.slot0(); 
const wethUsdcSqrtPrice = parseInt(getWethUsdcSlot0[0]); 
const wethUsdtSqrtPrice = parseInt(getWethUsdtSlot0[0]); 
const wethUsdcPrice = ((wethUsdcSqrtPrice**2)/(2**192))*(10**(1e18-1e18)); 
const wethUsdtPrice = ((wethUsdtSqrtPrice**2)/(2**192))*(10**(1e18-1e18)); 
console.log("WETH / USDC price is " + wethUsdcPrice.toString().substring(0, 5).replace('.', ''));
console.log("WETH / USDT price is " + wethUsdtPrice.toString().substring(0, 5).replace('.', ''));

if(wethUsdcPrice > wethUsdtPrice){
isWethUsdcPriceHigher = true; 
isWethUsdtPriceHigher = false; 
diff = ((wethUsdcPrice / wethUsdtPrice) - 1) * 100;
console.log("WETH / USDC price is higher by " + diff.toString().substring(0,7) + " % "); 
console.log(""); 
}else{
isWethUsdcPriceHigher = false; 
isWethUsdtPriceHigher = true; 
diff =  ((wethUsdtPrice / wethUsdcPrice) - 1) * 100;
console.log("WETH / USDT price is higher by " + diff.toString().substring(0,7) + " % "); 
console.log(""); 
}

if(diff > 0.025 ){
  if(isWethUsdcPriceHigher == true){
  call_trade2(); 
  } else {
  call_trade1(); 
  }
 }
}

//USDC --> WETH --> USDT
async function call_trade1(){
const getContractUsdcBalance1 = await optimusPrime.returnTokenBalance(usdcAddress); 
if(getContractUsdcBalance1 != 0){
  try{
   const getEncodedPath = await optimusPrime.returnPathData(usdcAddress, 100, wethAddress, 100, usdtAddress); 
   const getContractUsdcBalance = await optimusPrime.returnTokenBalance(usdcAddress); 
   const deadline = await optimusPrime.returnBlockTimestamp(); 
   const deadlineUint = parseInt(deadline); 
   const params = [getEncodedPath, optimusPrimeContract, deadlineUint + 1, getContractUsdcBalance, 0]; 
   const tx = await optimusPrime.trade1(params, getContractUsdcBalance, {gasPrice: 10000000}); 
   await tx.wait(); 
   console.log("✅ Possible profit made calling trade1 func ✅"); 
   console.log(""); 
  } catch(e) {
   console.log("❌ No possible profit made calling trade1 func ❌"); 
   console.log(""); 
  }
  } else {
   console.log("❌ No funds (USDC) in the contract to perform this operation ❌"); 
   console.log("");
   return; 
  }
}


//USDT --> WETH --> USDC
async function call_trade2(){
const getContractUsdtBalance1 = await optimusPrime.returnTokenBalance(usdtAddress); 
if(getContractUsdtBalance1 != 0){
  try{
   const getEncodedPath = await optimusPrime.returnPathData(usdtAddress, 100, wethAddress, 100, usdcAddress); 
   const getContractUsdtBalance = await optimusPrime.returnTokenBalance(usdtAddress); 
   const deadline = await optimusPrime.returnBlockTimestamp(); 
   const deadlineUint = parseInt(deadline); 
   const params = [getEncodedPath, optimusPrimeContract, deadlineUint + 2, getContractUsdtBalance, 0]; 
   const tx = await optimusPrime.trade2(params, getContractUsdtBalance, {gasPrice: 10000000}); 
   await tx.wait(); 
   console.log("✅ Possible profit made calling trade2 func ✅"); 
   console.log(""); 
  } catch(e) {
   console.log("❌ No possible profit made calling trade2 func ❌"); 
   console.log(""); 
  }
  } else {
   console.log("❌ No funds (USDT) in the contract to perform this operation ❌"); 
   console.log("");
   return; 
  }
}


try{
initializeBot(); 
}catch(e){
console.log("Oops, there's an error: " + e); 
}