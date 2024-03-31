// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//run test --> sudo forge test --match-path test/Foundry/OptimusPrimeTest.t.sol -vvvvv --fork-url https://convincing-rough-vineyard.arbitrum-mainnet.quiknode.pro/fc6cefc5774214bf87fce9243adf40285dc3b96f/ --gas-report

import {Test, console} from "forge-std/Test.sol";

import {OptimusPrime} from "../../contracts/OptimusPrime.sol"; 

import "../../contracts/uniswap/IV3UniswapSwapRouter.sol"; 

import "../../contracts/pancakeswap/IV3PancakeSwapRouter.sol"; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../contracts/camelot/v3/IV3CamelotSwapRouter.sol"; //CamelotV3

import "../../contracts/camelot/v2/IV2CamelotSwapRouter.sol"; //CamelotV2

import "../../contracts/sushiswap/IV2SushiswapRouter.sol"; //SushiswapV2
 
contract OptimusPrimeTest is Test {

address public constant uniswapRouterV3 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45; 

address public constant pancakeRouterV3 = 0x1b81D678ffb9C0263b24A97847620C99d213eB14;

address public constant camelotRouterV2 = 0xc873fEcbd354f5A56E00E710B90EF4201db2448d; 

address public constant camelotRouterV3 = 0x1F721E2E82F6676FCE4eA07A5958cF098D339e18; 

address public constant sushiswapRouterV2 = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; 

IERC20 public constant usdt = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);  

IERC20 public constant weth = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); 

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

optimusPrime.depositWETH(1e18);

optimusPrime.approveToken(address(weth), uniswapRouterV3, type(uint256).max);
optimusPrime.approveToken(address(weth), pancakeRouterV3, type(uint256).max);
optimusPrime.approveToken(address(weth), camelotRouterV3, type(uint256).max);
optimusPrime.approveToken(address(weth), camelotRouterV2, type(uint256).max);
optimusPrime.approveToken(address(weth), sushiswapRouterV2, type(uint256).max);

vm.stopPrank();
}


//OWNER
function test_correctOwner() public view{
bool isTheOwnerCorrect = optimusPrime.returnOwner() == address(this); 
assertEq(isTheOwnerCorrect, true); 
}



//TRADE EXECUTOR
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

function test_cantvSetTradeExecutor__addressZero() public {
vm.startPrank(owner);

vm.expectRevert("Can't be a 0 address"); 
optimusPrime.setTradeExecutor(address(0));
}

function test_cantvSetTradeExecutor__addressOptimusPrime() public {
vm.startPrank(owner);

vm.expectRevert("Can't be this address"); 
optimusPrime.setTradeExecutor(address(optimusPrime));
}



//VARIABLES / INVARIANTS 
//USDT
function test_correctUsdtAddress() public view {
IERC20 getToken = optimusPrime.weth(); 
assertEq(address(getToken), address(weth)); 
}



//UNISWAP ROUTER
function test_correctUniswapRouter() public view {
IV3UniswapSwapRouter router = optimusPrime.uniswapRouterV3(); 
assertEq(address(router), uniswapRouterV3); 
}



//PANCAKE SWAP ROUTER
function test_correctPancakeSwapRouter() public view {
assertEq(address(optimusPrime.pancakeRouterV3()), pancakeRouterV3); 
}



// //ETH PRICE
function test_correctBNBPrice() public view {
int answer = optimusPrime.returnETHPrice();
console.log("Eth price is currently", uint256(answer) / 1e8, "dollars"); 
}



//DEPOSIT
function test_canCorrectlyDeposit__correctInitialAmount() public view {
assertEq(optimusPrime.returnWETHbalance(), 1e18); 
assertEq(IERC20(weth).balanceOf(owner), 9e18); 
}

function test_canCorrectlyDeposit__fuzzing__multiplesDeposits(uint256 amount) public {
vm.startPrank(owner);

IERC20(weth).approve(address(optimusPrime), 9e18);

amount = bound(amount, 1e18, 3e18); 

optimusPrime.depositWETH(amount);

optimusPrime.depositWETH(amount);

optimusPrime.depositWETH(amount);

assertEq(optimusPrime.returnWETHbalance(), 1e18 + (amount * 3)); 
assertEq(IERC20(weth).balanceOf(owner), 9e18 - (amount * 3)); 
}

function test_cantDepositIfNotTheOwner(uint256 amount) public {
address randomAddress = address(123); 
vm.startPrank(randomAddress);

deal(address(weth), randomAddress, 10e18);
IERC20(weth).approve(address(optimusPrime), type(uint256).max);
amount = bound(amount, 1e18, 10e18); 

vm.expectRevert();
optimusPrime.depositWETH(amount);
}



//WITHDRAW
function test_canCorrectlyWithdraw(uint256 withdrawAmount) public {
vm.startPrank(owner); 

IERC20(weth).approve(address(optimusPrime), 9e18);

uint256 depositAmount = 9e18; 

optimusPrime.depositWETH(depositAmount);

assertEq(optimusPrime.returnWETHbalance(), 10e18);

withdrawAmount = bound(withdrawAmount, 1e18, 10e18); 

optimusPrime.withdrawWETH(withdrawAmount);

assertEq(optimusPrime.returnWETHbalance(), 10e18 - withdrawAmount); 
assertEq(IERC20(weth).balanceOf(owner), withdrawAmount); 
}

function test_cantWithdrawIfNotTheOwner(uint256 withdrawAmount) public {
address randomAddress = address(123); 
vm.startPrank(randomAddress); 

withdrawAmount = bound(withdrawAmount, 1e18, 10e18); 

vm.expectRevert();
optimusPrime.withdrawWETH(withdrawAmount);
}

function test_cantWithdrawIfAmountIIsHigherThanTheContractBalance() public {
vm.startPrank(owner); 
vm.expectRevert("Amount is higher than balance");
optimusPrime.withdrawWETH(2e18);
}

function test_cantTransferTokensFromTheContract__NotTheOwner(uint256 withdrawAmount) public {
address randomAddress = address(123); 
vm.startPrank(randomAddress); 

withdrawAmount = bound(withdrawAmount, 1e17, 1e18);
vm.expectRevert();
IERC20(weth).transferFrom(address(optimusPrime), randomAddress, withdrawAmount);
}



//APPROVE TOKEN / RETURN TOKEN APPROVED
function test_returnTokenApprovedWorks() public {
vm.startPrank(owner);

uint256 pancakeRouterWethApproved = optimusPrime.returnTokenApproved(address(weth), pancakeRouterV3);
uint256 uniswapRouterWethApproved = optimusPrime.returnTokenApproved(address(weth), uniswapRouterV3);

assertEq(pancakeRouterWethApproved, type(uint256).max); 
assertEq(uniswapRouterWethApproved, type(uint256).max); 

assertEq(optimusPrime.returnTokenApproved(address(weth), uniswapRouterV3), type(uint256).max); 
assertEq(IERC20(weth).allowance(address(optimusPrime), uniswapRouterV3), type(uint256).max); 

IERC20(weth).approve(address(optimusPrime), 1e18);

optimusPrime.depositWETH(1e18);
assertEq(IERC20(weth).allowance(owner, address(optimusPrime)), 0); 
}




// function test_cantTrade__NotTheExecutor1() public {
// vm.startPrank(address(321)); 

// address[] memory pancakePath = new address[](2); 
// pancakePath[0] = address(usdt); 
// pancakePath[1] = address(wbnb); 

// uint256 minAmountBnbOut = 0; //It is better to add a more specifc value, obtaining the USDT/WBNB ratio - the % of slippage
// uint24 bnbUniswapPoolFee = 100;  //The uniswap USDT/WBNB fee
// uint24 bnbPancakePoolFee = 100; 
// uint256 expectedGas = 0; //In this Foundry test we keep them 0 

// IV3PancakeSwapRouter.ExactInputParams memory pancakeParams = IV3PancakeSwapRouter.ExactInputParams({
// path: abi.encodePacked(pancakePath[0], bnbPancakePoolFee, pancakePath[1]), 
// recipient: address(optimusPrime), 
// amountIn: optimusPrime.returnUSDTbalance(), 
// amountOutMinimum: minAmountBnbOut
// }); 

// vm.expectRevert();                                                         
// optimusPrime.buyWithUSDTFromPancakeV3AndSellToUniswapV3(pancakeParams, address(wbnb), bnbUniswapPoolFee, expectedGas);
// assertGe(optimusPrime.returnUSDTbalance(), 500e18); 
// }



// //BUY from UNISWAP and sell to PANCAKE
// function test_canTrade__NotTheExecutor2() public {
// vm.startPrank(address(321)); 

// address[] memory pancakePath = new address[](2); 
// pancakePath[0] = address(wbnb); 
// pancakePath[1] = address(usdt); 

// uint256 minAmountBnbOut = 0; //It is better to add a more specifc value, obtaining the USDT/WBNB ratio - the % of slippage
// uint24 bnbUniswapPoolFee = 100;  //The uniswap USDT/WBNB fee
// uint24 bnbPancakePoolFee = 100;  //The pancake USDT/WBNB fee
// uint256 expectedGas = 0; //In this Foundry test we keep them 0 

// IV3SwapRouter.ExactInputParams memory uniswapParams = IV3SwapRouter.ExactInputParams({
// path: abi.encodePacked(pancakePath[1], bnbUniswapPoolFee, pancakePath[0]), 
// recipient: address(optimusPrime), 
// amountIn: optimusPrime.returnUSDTbalance(), 
// amountOutMinimum: minAmountBnbOut
// });       

// vm.expectRevert(); 
// optimusPrime.buyWithUSDTFromUniswapV3AndSellToPancakeV3(uniswapParams, address(wbnb), bnbPancakePoolFee, expectedGas);
// assertGe(optimusPrime.returnUSDTbalance(), 500e18); 
// }
}