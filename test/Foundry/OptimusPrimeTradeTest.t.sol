// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//run test --> sudo forge test --match-path test/Foundry/OptimusPrimeTradeTest.t.sol -vvvvv --fork-url https://convincing-rough-vineyard.arbitrum-mainnet.quiknode.pro/fc6cefc5774214bf87fce9243adf40285dc3b96f/ --gas-report

import {Test, console} from "forge-std/Test.sol";

import {OptimusPrime} from "../../contracts/OptimusPrime.sol"; 

import "../../contracts/pancakeswap/IV3PancakeSwapRouter.sol"; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 
contract OptimusPrimeTest is Test {

address public constant pancakeRouterV3 = 0x1b81D678ffb9C0263b24A97847620C99d213eB14;

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
optimusPrime = new OptimusPrime(pancakeRouterV3); 
vm.startPrank(owner);
//Approve USDT/USDC in order to deposit them to the contract
deal(address(usdt), owner, 100e6);
deal(address(usdc), owner, 100e6);
IERC20(usdt).approve(address(optimusPrime), 100e6);
IERC20(usdc).approve(address(optimusPrime), 100e6);

tradeExecutor = address(123);
optimusPrime.setTradeExecutor(tradeExecutor); 

optimusPrime.depositToken(address(usdt), 100e6); // 100 usdt
optimusPrime.depositToken(address(usdc), 100e6); // 100 usdt

optimusPrime.approveToken(address(weth), pancakeRouterV3, type(uint256).max);
optimusPrime.approveToken(address(usdt), pancakeRouterV3, type(uint256).max);
optimusPrime.approveToken(address(usdc), pancakeRouterV3, type(uint256).max);

vm.stopPrank();
}

address public tokenToTrade = address(weth); 

//USDC --> WETH --> USDT
function test_canTrade1() public {
vm.startPrank(tradeExecutor); 

address[] memory pancakePath = new address[](2); 
pancakePath[0] = address(usdc); 
pancakePath[1] = address(tokenToTrade); 

uint256 minAmountTokenOut = 0; 
uint24 pancakePoolFee = 100; 

IV3PancakeSwapRouter.ExactInputParams memory pancakeParams = IV3PancakeSwapRouter.ExactInputParams({
path: abi.encodePacked(pancakePath[0], pancakePoolFee, pancakePath[1]), 
recipient: address(optimusPrime), 
deadline: block.timestamp, 
amountIn: optimusPrime.returnTokenBalance(address(usdc)), 
amountOutMinimum: minAmountTokenOut
}); 
optimusPrime.trade1(pancakeParams, optimusPrime.returnTokenBalance(address(usdc)));
}


//USDT --> WETH --> USDC 
function test_canTrade2() public {
vm.startPrank(tradeExecutor); 

address[] memory pancakePath = new address[](2); 
pancakePath[0] = address(usdt); 
pancakePath[1] = address(tokenToTrade); 

uint256 minAmountTokenOut = 0; 
uint24 pancakePoolFee = 100;  

IV3PancakeSwapRouter.ExactInputParams memory pancakeParams = IV3PancakeSwapRouter.ExactInputParams({
path: abi.encodePacked(pancakePath[0], pancakePoolFee, pancakePath[1]), 
recipient: address(optimusPrime), 
deadline: block.timestamp, 
amountIn: optimusPrime.returnTokenBalance(address(usdt)), 
amountOutMinimum: minAmountTokenOut
}); 
optimusPrime.trade2(pancakeParams, optimusPrime.returnTokenBalance(address(usdt)));
}

//USDC --> WETH --> USDT --> USDC
function test_canTrade3() public {
vm.startPrank(tradeExecutor); 

address[] memory pancakePath = new address[](2); 
pancakePath[0] = address(usdc); 
pancakePath[1] = address(tokenToTrade); 

uint256 minAmountTokenOut = 0; 
uint24 pancakePoolFee = 100; 

IV3PancakeSwapRouter.ExactInputParams memory pancakeParams = IV3PancakeSwapRouter.ExactInputParams({
path: abi.encodePacked(pancakePath[0], pancakePoolFee, pancakePath[1]), 
recipient: address(optimusPrime), 
deadline: block.timestamp, 
amountIn: optimusPrime.returnTokenBalance(address(usdc)), 
amountOutMinimum: minAmountTokenOut
}); 
optimusPrime.trade3(pancakeParams);
}

//USDT --> WETH --> USDC --> USDT
function test_canTrade4() public {
vm.startPrank(tradeExecutor); 

address[] memory pancakePath = new address[](2); 
pancakePath[0] = address(usdt); 
pancakePath[1] = address(tokenToTrade); 

uint256 minAmountTokenOut = 0; 
uint24 pancakePoolFee = 100;  

IV3PancakeSwapRouter.ExactInputParams memory pancakeParams = IV3PancakeSwapRouter.ExactInputParams({
path: abi.encodePacked(pancakePath[0], pancakePoolFee, pancakePath[1]), 
recipient: address(optimusPrime), 
deadline: block.timestamp, 
amountIn: optimusPrime.returnTokenBalance(address(usdt)), 
amountOutMinimum: minAmountTokenOut
}); 
optimusPrime.trade4(pancakeParams);
}
}

