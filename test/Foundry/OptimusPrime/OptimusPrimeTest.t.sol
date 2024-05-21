// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//run test --> sudo forge test --match-path test/Foundry/OptimusPrime/OptimusPrimeTest.t.sol -vvv --fork-url https://convincing-rough-vineyard.arbitrum-mainnet.quiknode.pro/fc6cefc5774214bf87fce9243adf40285dc3b96f/ --gas-report

import {Test, console} from "forge-std/Test.sol";

import {OptimusPrime} from "../../../contracts/OptimusPrime.sol"; 

import "../../../contracts/pancakeswap/IV3PancakeSwapRouter.sol"; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 
contract OptimusPrimeTest is Test {

address public constant pancakeRouterV3 = 0x1b81D678ffb9C0263b24A97847620C99d213eB14;

IERC20 public constant usdt = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);  
IERC20 public constant usdc = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831); 
IERC20 public constant link = IERC20(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4); 

IERC20 public constant weth = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); 

address public owner; 

address public tradeExecutor; 

OptimusPrime public optimusPrime; 

function setUp() public {
owner = address(this); 
optimusPrime = new OptimusPrime(pancakeRouterV3); 
vm.startPrank(owner);
//Approve USDT/USDC in order to deposit them to the contract
deal(address(usdt), owner, 1000e6);
deal(address(usdc), owner, 1000e6);
IERC20(usdt).approve(address(optimusPrime), 1000e6);
IERC20(usdc).approve(address(optimusPrime), 1000e6);

tradeExecutor = address(123);
optimusPrime.setTradeExecutor(tradeExecutor); 

optimusPrime.depositToken(address(usdt), 100e6); // 100 usdt
optimusPrime.depositToken(address(usdc), 100e6); // 100 usdc

optimusPrime.approveToken(address(weth), pancakeRouterV3, type(uint256).max);
optimusPrime.approveToken(address(usdt), pancakeRouterV3, type(uint256).max);
optimusPrime.approveToken(address(usdc), pancakeRouterV3, type(uint256).max);

vm.stopPrank();
}



//PANCAKE ROUTER V3
function test_correctPancakeRouterV3() public view {
bool isThePancakeV3RouterCorrect = optimusPrime.pancakeRouterV3() == IV3PancakeSwapRouter(pancakeRouterV3); 
assertEq(isThePancakeV3RouterCorrect, true); 
}

//WETH 
function test_correctWETHAddress() public view {
bool isWethTheCorrectAddress = optimusPrime.weth() == weth; 
assertEq(isWethTheCorrectAddress, true); 
}

//USDT 
function test_correctUSDTAddress() public view {
bool isUsdtTheCorrectAddress = optimusPrime.usdt() == usdt; 
assertEq(isUsdtTheCorrectAddress, true); 
}

//USDC
function test_correctUSDCAddress() public view {
bool isUsdcTheCorrectAddress = optimusPrime.usdc() == usdc; 
assertEq(isUsdcTheCorrectAddress, true); 
}

//RETURN TOKEN BALANCE
function test_returnCorrectContractBalance() public view {
assertEq(optimusPrime.returnTokenBalance(address(usdc)), 100e6); 
assertEq(optimusPrime.returnTokenBalance(address(usdt)), 100e6); 
assertEq(optimusPrime.returnTokenBalance(address(weth)), 0); 
}

//RETURN BLOCK TIMESTAMP 
function test_correctTimestampReturned() public view {
uint256 blockTimestamp1 = block.timestamp; 
uint256 blockTimestamp2 = optimusPrime.returnBlockTimestamp();
assertEq(blockTimestamp1, blockTimestamp2); 
}

//RETURN CORRECT PATH DATA
function test_correctPathDataReturnedUSDCtoUSDT() public view {
uint24 fee = 100; 
bytes memory dataEncoded1 = abi.encodePacked(address(usdc), fee, address(usdt));
bytes memory dataEncoded2 = optimusPrime.returnPathData(address(usdc), fee, address(usdt));
assertEq(dataEncoded1, dataEncoded2); 
}

function test_correctPathDataReturnedUSDTtoUSDC() public view {
uint24 fee = 100; 
bytes memory dataEncoded1 = abi.encodePacked(address(usdt), fee, address(usdc));
bytes memory dataEncoded2 = optimusPrime.returnPathData(address(usdt), fee, address(usdc));
assertEq(dataEncoded1, dataEncoded2); 
}

function test_incorrectPathDataReturned1() public view {
uint24 fee = 100; 
bytes memory dataEncoded1 = abi.encodePacked(address(usdt), fee, address(usdc));
bytes memory dataEncoded2 = optimusPrime.returnPathData(address(usdc), fee, address(usdt));
assertNotEq(dataEncoded1, dataEncoded2); 
}

//IS LOCKED / LOCK / UNLOCK
function test_isLockAtStart() public view {
bool notLockedAtStart = optimusPrime.isLocked() == false; 
assertEq(notLockedAtStart, true); 
}

function test_cantLockIfNotTheOwner() public {
vm.startPrank(address(1224)); 
vm.expectRevert();
optimusPrime.lock();
vm.stopPrank();
}

function test_cantUnlockIfNotTheOwner() public {
vm.startPrank(address(owner)); 
optimusPrime.lock(); 
vm.stopPrank(); 

vm.startPrank(address(8312)); 
vm.expectRevert(); 
optimusPrime.unlock();
vm.stopPrank(); 
}

function test_canLockAndUnlock() public {
vm.startPrank(address(owner));
optimusPrime.lock();
assertEq(optimusPrime.isLocked(), true); 
optimusPrime.unlock();
assertEq(optimusPrime.isLocked(), false); 
}


//TRADE EXECUTOR / SET TRADE EXECUTOR
function test_correctTradeExecutor() public view {
bool isTheCorrectTradeExecutor = optimusPrime.tradeExecutor() == tradeExecutor; 
assertEq(isTheCorrectTradeExecutor, true); 
}

function test_canSetTradeExecutor__NotTheOwner() public {
address randomAddress = address(4176); 
vm.startPrank(randomAddress); 

vm.expectRevert();
optimusPrime.setTradeExecutor(address(2326714));
}

function test_cantSetTradeExecutor__addressZero() public {
vm.startPrank(owner);

vm.expectRevert("Can't be a 0 address"); 
optimusPrime.setTradeExecutor(address(0));
}

function test_cantSetTradeExecutor__addressOptimusPrime() public {
vm.startPrank(owner);

vm.expectRevert("Can't be this address"); 
optimusPrime.setTradeExecutor(address(optimusPrime));
}

//DEPOSIT
function test_cantDeposit_notTheCorrectToken(uint256 amount) public {
vm.startPrank(owner); 
deal(address(weth), owner, 1e18);
amount = bound(amount, 1, 1e18);
vm.expectRevert(); 
optimusPrime.depositToken(address(weth), 1e18);
}

function test_cantDeposit_0amount() public {
vm.startPrank(owner); 
vm.expectRevert("Amount can't be 0");
optimusPrime.depositToken(address(usdc), 0);
}

function test_cantDeposit_notTheOwner() public {
address casualAddress = address(132); 
deal(address(usdt), casualAddress, 100e6); 
vm.startPrank(casualAddress);
vm.expectRevert();
optimusPrime.depositToken(address(usdt), 100e6);
}

function test_canDepositToken(uint256 amountUsdt, uint256 amountUsdc) public {
vm.startPrank(owner); 

uint256 usdcBalanceBefore = optimusPrime.returnTokenBalance(address(usdc));
uint256 usdtBalanceBefore = optimusPrime.returnTokenBalance(address(usdt));

amountUsdc = bound(amountUsdc, 1, 900e6); 
amountUsdt = bound(amountUsdt, 1, 900e6); 

optimusPrime.depositToken(address(usdc), amountUsdc);
optimusPrime.depositToken(address(usdt), amountUsdt);

uint256 usdcBalanceAfter = optimusPrime.returnTokenBalance(address(usdc));
uint256 usdtBalanceAfter = optimusPrime.returnTokenBalance(address(usdt));
assertEq(usdcBalanceAfter, usdcBalanceBefore + amountUsdc); 
assertEq(usdtBalanceAfter, usdtBalanceBefore + amountUsdt); 
}

//WITHDRAW
function test_cantWithdraw_badMinimumAmount(uint256 amountUsdt, uint256 amountUsdc) public {
vm.startPrank(owner); 

amountUsdc = bound(amountUsdc, 1, 900e6); 
amountUsdt = bound(amountUsdt, 1, 900e6); 

optimusPrime.depositToken(address(usdc), amountUsdc);
optimusPrime.depositToken(address(usdt), amountUsdt);

vm.expectRevert("Amount is higher than balance");
optimusPrime.withdrawToken(address(usdc), 1001e6);
}

function test_cantWithdraw_badMinimumAmount2(uint256 amountUsdt, uint256 amountUsdc) public {
vm.startPrank(owner); 

amountUsdc = bound(amountUsdc, 1, 900e6); 
amountUsdt = bound(amountUsdt, 1, 900e6); 

optimusPrime.depositToken(address(usdc), amountUsdc);
optimusPrime.depositToken(address(usdt), amountUsdt);

vm.expectRevert();
optimusPrime.withdrawToken(address(weth), 1e18);
}

function test_cantWithdraw_notTheOwner(uint256 amountUsdt, uint256 amountUsdc) public {
vm.startPrank(owner); 

amountUsdc = bound(amountUsdc, 1, 900e6); 
amountUsdt = bound(amountUsdt, 1, 900e6); 

optimusPrime.depositToken(address(usdc), amountUsdc);
optimusPrime.depositToken(address(usdt), amountUsdt);
vm.stopPrank(); 

address casualAddr = address(123); 
vm.startPrank(casualAddr);
vm.expectRevert();
optimusPrime.withdrawToken(address(usdc), 1e6);
}

function test_canCorrectlyWithdraw(uint256 withdrawAmount) public {
vm.startPrank(owner); 

optimusPrime.depositToken(address(usdc), 900e6);
optimusPrime.depositToken(address(usdt), 900e6);

uint256 usdcBalanceAfterDeposit = optimusPrime.returnTokenBalance(address(usdc));
uint256 usdtBalanceAfterDeposit = optimusPrime.returnTokenBalance(address(usdt));

withdrawAmount = bound(withdrawAmount, 1, 1000e6); 

optimusPrime.withdrawToken(address(usdt), withdrawAmount);
optimusPrime.withdrawToken(address(usdc), withdrawAmount);

uint256 usdcBalanceAfterWithdraw = optimusPrime.returnTokenBalance(address(usdc));
uint256 usdtBalanceAfterWithdraw = optimusPrime.returnTokenBalance(address(usdt));
uint256 ownerUsdcBalanceAfterWithdraw = IERC20(usdc).balanceOf(owner);
uint256 ownerUsdtBalanceAfterWithdraw = IERC20(usdt).balanceOf(owner);
assertEq(usdcBalanceAfterWithdraw, usdcBalanceAfterDeposit - withdrawAmount); 
assertEq(usdtBalanceAfterWithdraw, usdtBalanceAfterDeposit - withdrawAmount); 
assertEq(ownerUsdcBalanceAfterWithdraw, withdrawAmount); 
assertEq(ownerUsdtBalanceAfterWithdraw, withdrawAmount); 
}

//APPROVE TOKEN
function test_allowanceWorksCorrect() public view {
assertEq(IERC20(weth).allowance(address(optimusPrime), pancakeRouterV3), type(uint256).max); 
assertEq(IERC20(usdt).allowance(address(optimusPrime), pancakeRouterV3), type(uint256).max); 
assertEq(IERC20(usdc).allowance(address(optimusPrime), pancakeRouterV3), type(uint256).max); 
}

function test_onlyOwnerCanApproveToken() public {
address casualAddress = address(12139); 
vm.startPrank(casualAddress);

vm.expectRevert();
optimusPrime.approveToken(address(link), pancakeRouterV3, type(uint256).max);
}
}