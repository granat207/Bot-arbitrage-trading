// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//run test --> sudo forge test --match-path test/Foundry/OptimusPrimeTradeTest.t.sol -vvvvv --fork-url https://convincing-rough-vineyard.arbitrum-mainnet.quiknode.pro/fc6cefc5774214bf87fce9243adf40285dc3b96f/ --gas-report

import {Test, console} from "forge-std/Test.sol";

import {OptimusPrime} from "../../contracts/OptimusPrime.sol"; 

import "../../contracts/uniswap/IV3UniswapSwapRouter.sol"; 

import "../../contracts/pancakeswap/IV3PancakeSwapRouter.sol"; 

import "../../contracts/camelot/v3/IV3CamelotSwapRouter.sol"; //CamelotV3

import "../../contracts/camelot/v2/IV2CamelotSwapRouter.sol"; //CamelotV2

import "../../contracts/sushiswap/IV2SushiswapRouter.sol"; //SushiswapV2

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 
contract OptimusPrimeTest is Test {

address public constant uniswapRouterV3 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45; 

address public constant pancakeRouterV3 = 0x1b81D678ffb9C0263b24A97847620C99d213eB14;

address public constant camelotRouterV2 = 0xc873fEcbd354f5A56E00E710B90EF4201db2448d; 

address public constant camelotRouterV3 = 0x1F721E2E82F6676FCE4eA07A5958cF098D339e18; 

address public constant sushiswapRouterV2 = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; 

IERC20 public constant usdt = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);  
IERC20 public constant weth = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); 
IERC20 public constant usdc = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831); 
IERC20 public constant wbtc = IERC20(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f); 
IERC20 public constant arb = IERC20(0x912CE59144191C1204E64559FE8253a0e49E6548); 
IERC20 public constant pendle = IERC20(0x0c880f6761F1af8d9Aa9C466984b80DAb9a8c9e8); 
IERC20 public constant link = IERC20(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4); 


address public owner; 

address public tradeExecutor; 

OptimusPrime public optimusPrime; 

function setUp() public {
owner = address(this); 
optimusPrime = new OptimusPrime(uniswapRouterV3, pancakeRouterV3, camelotRouterV3, camelotRouterV2, sushiswapRouterV2); 
vm.startPrank(owner);
//Approve USDT in order to deposit them to the contract
deal(address(weth), owner, 10e18);
IERC20(weth).approve(address(optimusPrime), 1e18);

tradeExecutor = address(123);
optimusPrime.setTradeExecutor(tradeExecutor); 

optimusPrime.depositWETH(1e17); // 1 / 10 ETH

optimusPrime.approveToken(address(weth), uniswapRouterV3, type(uint256).max);
optimusPrime.approveToken(address(weth), pancakeRouterV3, type(uint256).max);
optimusPrime.approveToken(address(weth), camelotRouterV3, type(uint256).max);
optimusPrime.approveToken(address(weth), camelotRouterV2, type(uint256).max);
optimusPrime.approveToken(address(weth), sushiswapRouterV2, type(uint256).max);

vm.stopPrank();
}

address public tokenToTrade = address(usdc); 

// //TRADE BUYING FROM PancakeV3 AND SELLING TO OTHERS DEXES
// function test_canTradeWETHBuyingFromPancakeV3AndSellingToUniswapV3() public {
    
// vm.startPrank(owner); 
// address tokenToBuy = tokenToTrade; 
// optimusPrime.approveToken(address(tokenToBuy), uniswapRouterV3, type(uint256).max);
// optimusPrime.approveToken(address(tokenToBuy), pancakeRouterV3, type(uint256).max);
// vm.stopPrank();

// vm.startPrank(tradeExecutor); 

// address[] memory pancakePath = new address[](2); 
// pancakePath[0] = address(weth); 
// pancakePath[1] = tokenToBuy; 

// uint256 minAmountTokenOut = 0; //It is better to add a more specifc value, obtaining the USDT/WBNB ratio - the % of slippage
// uint24 uniswapPoolFee = 100;  //The uniswap USDT/WBNB fee
// uint24 pancakePoolFee = 100; 
// uint256 expectedGas = 0; //In this Foundry test we keep them 0 

// IV3PancakeSwapRouter.ExactInputParams memory pancakeParams = IV3PancakeSwapRouter.ExactInputParams({
// path: abi.encodePacked(pancakePath[0], pancakePoolFee, pancakePath[1]), 
// recipient: address(optimusPrime), 
// deadline: block.timestamp,
// amountIn: optimusPrime.returnWETHbalance(), 
// amountOutMinimum: minAmountTokenOut
// }); 
                                                         
// optimusPrime.buyWithWETHFromPancakeV3AndSellToUniswapV3(pancakeParams, address(tokenToBuy), uniswapPoolFee, expectedGas);
// assertGe(optimusPrime.returnWETHbalance(), 1e17); 
// }



// //TRADE BUYING FROM UniswapV3 AND SELLING TO OTHERS DEXES
// function test_canTradeWETHBuyingFromUniswapV3AndSellingToPancakeV3() public {

// vm.startPrank(owner); 
// address tokenToBuy = tokenToTrade;  
// optimusPrime.approveToken(address(tokenToBuy), uniswapRouterV3, type(uint256).max);
// optimusPrime.approveToken(address(tokenToBuy), pancakeRouterV3, type(uint256).max);
// vm.stopPrank();
// vm.startPrank(tradeExecutor); 

// address[] memory pancakePath = new address[](2); 
// pancakePath[0] = tokenToBuy; 
// pancakePath[1] = address(weth); 

// uint256 minAmountTokenOut = 0; 
// uint24 uniswapPoolFee = 100;  
// uint24 pancakePoolFee = 100;  
// uint256 expectedGas = 0; //In this Foundry test we keep them 0 

// IV3UniswapSwapRouter.ExactInputParams memory uniswapParams = IV3UniswapSwapRouter.ExactInputParams({
// path: abi.encodePacked(pancakePath[1], uniswapPoolFee, pancakePath[0]), 
// recipient: address(optimusPrime), 
// amountIn: optimusPrime.returnWETHbalance(), 
// amountOutMinimum: minAmountTokenOut
// });       

// optimusPrime.buyWithWETHFromUniswapV3AndSellToPancakeV3(uniswapParams, address(tokenToBuy), pancakePoolFee, expectedGas);
// assertGe(optimusPrime.returnWETHbalance(), 1e17); 
// }

// function test_canTradeWETHBuyingFromUniswapV3AndSellingToSushiswapV2() public {

// vm.startPrank(owner); 
// address tokenToBuy = tokenToTrade;  
// optimusPrime.approveToken(address(tokenToBuy), uniswapRouterV3, type(uint256).max);
// optimusPrime.approveToken(address(tokenToBuy), sushiswapRouterV2, type(uint256).max);
// vm.stopPrank();

// vm.startPrank(tradeExecutor);

// address[] memory uniswapPath = new address[](2); 
// uniswapPath[0] = address(weth); 
// uniswapPath[1] = tokenToBuy; 

// uint256 minAmountTokenOut = 0; 
// uint24 uniswapPoolFee = 100;   
// uint256 expectedGas = 0; //In this Foundry test we keep them 0 

// IV3UniswapSwapRouter.ExactInputParams memory uniswapParams = IV3UniswapSwapRouter.ExactInputParams({
// path: abi.encodePacked(uniswapPath[0], uniswapPoolFee, uniswapPath[1]), 
// recipient: address(optimusPrime), 
// amountIn: optimusPrime.returnWETHbalance(), 
// amountOutMinimum: minAmountTokenOut
// });     

// optimusPrime.buyWithWETHFromUniswapV3AndSellToSushiswapV2(uniswapParams, tokenToBuy, expectedGas);
// assertGe(optimusPrime.returnWETHbalance(), 1e17); 
// }

function test_canTradeWithWETHBuyingFromUniswapV3AndSellingToCamelotV3() public {
vm.startPrank(owner); 
address tokenToBuy = tokenToTrade;  
optimusPrime.approveToken(address(tokenToBuy), uniswapRouterV3, type(uint256).max);
optimusPrime.approveToken(address(tokenToBuy), camelotRouterV3, type(uint256).max);
vm.stopPrank();

vm.startPrank(tradeExecutor);

address[] memory uniswapPath = new address[](2); 
uniswapPath[0] = address(weth); 
uniswapPath[1] = tokenToBuy; 

uint24 uniswapPoolFee = 500;  
uint256 expectedGas = 0; 

IV3UniswapSwapRouter.ExactInputParams memory uniswapParams = IV3UniswapSwapRouter.ExactInputParams({
path: abi.encodePacked(uniswapPath[0], uniswapPoolFee, uniswapPath[1]), 
recipient: address(optimusPrime), 
amountIn: optimusPrime.returnWETHbalance(), 
amountOutMinimum: 0
});    
optimusPrime.buyWithWETHFromUniswapV3AndSellToCamelotV3(uniswapParams, tokenToBuy, expectedGas);
}





// //TRADE BUYING FROM SushiswapV2 AND SELLING TO OTHERS DEXES
// function test_canTradeWithWETHBuyingFromSushiswapV2AndSellingToUniswapV3() public {

// vm.startPrank(owner); 
// address tokenToBuy = tokenToTrade;  
// optimusPrime.approveToken(address(tokenToBuy), uniswapRouterV3, type(uint256).max);
// optimusPrime.approveToken(address(tokenToBuy), sushiswapRouterV2, type(uint256).max);
// vm.stopPrank();

// vm.startPrank(tradeExecutor);

// uint256 amountIn = optimusPrime.returnWETHbalance();
// uint24 uniswapPoolFee = 100;   
// uint256 expectedGas = 0; //In this Foundry test we keep them 0 

// optimusPrime.buyWithWETHFromSushiswapV2AndSellToUniswapV3(amountIn, tokenToBuy, uniswapPoolFee, expectedGas);
// assertGe(optimusPrime.returnWETHbalance(), 1e17); 
// }



// //TRADE BUYING FROM CamelotV3 AND SELLING TO OTHERS DEXES
function test_canTradeWithWETHBuyingFromCamelotV3AndSellingToUniswapV3() public {
vm.startPrank(owner); 
address tokenToBuy = tokenToTrade;  
optimusPrime.approveToken(address(tokenToBuy), uniswapRouterV3, type(uint256).max);
optimusPrime.approveToken(address(tokenToBuy), camelotRouterV3, type(uint256).max);
vm.stopPrank();

vm.startPrank(tradeExecutor);

uint24 uniswapPoolFee = 500;  
uint256 expectedGas = 0; 

IV3CamelotSwapRouter.ExactInputParams memory camelotParams = IV3CamelotSwapRouter.ExactInputParams({
path: abi.encodePacked(address(weth), tokenToBuy), 
recipient: address(optimusPrime), 
deadline: block.timestamp,
amountIn: optimusPrime.returnWETHbalance(), 
amountOutMinimum: 0
}); 
optimusPrime.buyWithWETHFromCamelotV3AndSellToUniswapV3(camelotParams, tokenToBuy, uniswapPoolFee, expectedGas);
}
}