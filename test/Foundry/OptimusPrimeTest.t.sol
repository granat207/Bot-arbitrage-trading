// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//run test --> sudo forge test --match-path test/Foundry/OptimusPrimeTest.t.sol -vvvvv --fork-url https://convincing-rough-vineyard.arbitrum-mainnet.quiknode.pro/fc6cefc5774214bf87fce9243adf40285dc3b96f/ --gas-report

import {Test, console} from "forge-std/Test.sol";

import {OptimusPrime} from "../../contracts/OptimusPrime.sol"; 

import "../../contracts/pancakeswap/IV3PancakeSwapRouter.sol"; 

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
deal(address(usdt), owner, 100e18);
deal(address(usdc), owner, 100e18);
IERC20(usdt).approve(address(optimusPrime), 100e18);
IERC20(usdc).approve(address(optimusPrime), 100e18);

tradeExecutor = address(123);
optimusPrime.setTradeExecutor(tradeExecutor); 

optimusPrime.depositToken(address(usdt), 50e18); // 50 usdt

optimusPrime.approveToken(address(weth), pancakeRouterV3, type(uint256).max);
optimusPrime.approveToken(address(usdt), pancakeRouterV3, type(uint256).max);
optimusPrime.approveToken(address(usdc), pancakeRouterV3, type(uint256).max);

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

function test_cantSetTradeExecutor__addressZero() public {
vm.startPrank(owner);

vm.expectRevert("Can't be a 0 address"); 
optimusPrime.setTradeExecutor(address(0));
}

function test_cantvSetTradeExecutor__addressOptimusPrime() public {
vm.startPrank(owner);

vm.expectRevert("Can't be this address"); 
optimusPrime.setTradeExecutor(address(optimusPrime));
}

}