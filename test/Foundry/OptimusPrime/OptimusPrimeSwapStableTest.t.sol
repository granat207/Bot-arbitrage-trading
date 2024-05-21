// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//run test --> sudo forge test --match-path test/Foundry/OptimusPrime/OptimusPrimeSwapStableTest.t.sol -vvv --fork-url https://convincing-rough-vineyard.arbitrum-mainnet.quiknode.pro/fc6cefc5774214bf87fce9243adf40285dc3b96f/ --gas-report

import {Test, console} from "forge-std/Test.sol";

import {OptimusPrime} from "../../../contracts/OptimusPrime.sol"; 

import "../../../contracts/pancakeswap/IV3PancakeSwapRouter.sol"; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 
contract OptimusPrimeTest is Test {

address public constant pancakeRouterV3 = 0x1b81D678ffb9C0263b24A97847620C99d213eB14;


IERC20 public constant usdt = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);  
IERC20 public constant usdc = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831); 

IERC20 public constant weth = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); 

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
optimusPrime.depositToken(address(usdc), 100e6); // 100 usdc

optimusPrime.approveToken(address(weth), pancakeRouterV3, type(uint256).max);
optimusPrime.approveToken(address(usdt), pancakeRouterV3, type(uint256).max);
optimusPrime.approveToken(address(usdc), pancakeRouterV3, type(uint256).max);

vm.stopPrank();
}

//SWAP USDT FOR USDC no slippage
function test_canCorrectlySwapUSDTforUSDC() public {
vm.startPrank(owner); 
uint256 usdcBalanceBeforeSwap = IERC20(usdc).balanceOf(address(optimusPrime));

optimusPrime.swapUSDTforUSDCnoSlippage();

uint256 usdcBalanceAfterSwap = IERC20(usdc).balanceOf(address(optimusPrime));
uint256 usdtBalanceAfterSwap = IERC20(usdt).balanceOf(address(optimusPrime));
assertGt(usdcBalanceAfterSwap, usdcBalanceBeforeSwap);
assertEq(usdtBalanceAfterSwap, 0); 
}

function test_cantCorrectlySwapUSDTforUSDC_notTheOwner() public {
address casualAddr = address(13476); 
vm.startPrank(casualAddr); 
vm.expectRevert();
optimusPrime.swapUSDTforUSDCnoSlippage();
}

function test_cantSwapUSDTforUSDC_noUSDTamountInTheContract() public {
vm.startPrank(owner);
optimusPrime.withdrawToken(address(usdt), 100e6);

vm.expectRevert();
optimusPrime.swapUSDTforUSDCnoSlippage();
vm.stopPrank(); 
}

//SWAP USDC FOR USDT no slippage
function test_canCorrectlySwapUSDCforUSDT() public {
vm.startPrank(owner); 
uint256 usdtBalanceBeforeSwap = IERC20(usdt).balanceOf(address(optimusPrime));

optimusPrime.swapUSDCforUSDTnoSlippage();

uint256 usdcBalanceAfterSwap = IERC20(usdc).balanceOf(address(optimusPrime));
uint256 usdtBalanceAfterSwap = IERC20(usdt).balanceOf(address(optimusPrime));
assertGt(usdtBalanceAfterSwap, usdtBalanceBeforeSwap);
assertEq(usdcBalanceAfterSwap, 0); 
}

function test_cantCorrectlySwapUSDCforUSDT_notTheOwner() public {
address casualAddr = address(13476); 
vm.startPrank(casualAddr); 
vm.expectRevert();
optimusPrime.swapUSDCforUSDTnoSlippage();
}

function test_cantSwapUSDCforUSDT_noUSDCamountInTheContract() public {
vm.startPrank(owner);
optimusPrime.withdrawToken(address(usdc), 100e6);

vm.expectRevert();
optimusPrime.swapUSDCforUSDTnoSlippage();
vm.stopPrank(); 
}
}