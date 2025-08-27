// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {OptimusPrime} from "../../src/OptimusPrime/OptimusPrime.sol"; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
 
contract OptimusPrimeBasicTest is Test {

address public constant uniswapRouterV3 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45; 
address public constant pancakeRouterV3 = 0x1b81D678ffb9C0263b24A97847620C99d213eB14;

IERC20 public constant usdt = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);  
IERC20 public constant usdc = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831); 
IERC20 public constant link = IERC20(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4); 

IERC20 public constant weth = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); 

address public david = makeAddr("david"); 
address public bob = makeAddr("bob"); 

address public tradeExecutor; 

OptimusPrime public optimusPrime; 

function setUp() public {
vm.startPrank(david); 
optimusPrime = new OptimusPrime(pancakeRouterV3, uniswapRouterV3, address(usdt), address(usdc)); 
vm.stopPrank(); 
}

//depositToken tests
function test_CanDepositToken_unit() public {
	deal(address(usdt), david, 100e6); 
	vm.startPrank(david); 
	usdt.approve(address(optimusPrime), 100e6);
	optimusPrime.depositToken(address(usdt), 100e6);
	assertEq(IERC20(usdt).balanceOf(david), 0); 
	assertEq(IERC20(usdt).balanceOf(address(optimusPrime)), 100e6); 
}

function test_CanDepositToken_fuzz(uint256 amount) public {
	amount = bound(amount, 1, 100_000_000e6);
	deal(address(usdt), david, amount); 
	vm.startPrank(david); 
	usdt.approve(address(optimusPrime), amount);
	optimusPrime.depositToken(address(usdt), amount);
	assertEq(IERC20(usdt).balanceOf(david), 0); 
	assertEq(IERC20(usdt).balanceOf(address(optimusPrime)), amount); 
}

function test_cantDepositToken_TokenNotAccepted() public {
	deal(address(link), david, 100e18); 
	vm.startPrank(david); 
	vm.expectRevert(abi.encodeWithSelector(OptimusPrime.TokenNotAccepted.selector, address(link))); 
	optimusPrime.depositToken(address(link), 100e18);
}

function test_cantDepositToken_AmountIs0() public {
	deal(address(usdt), david, 100e6); 
	vm.startPrank(david); 
	vm.expectRevert("Amount can't be 0"); 
	optimusPrime.depositToken(address(usdt), 0);
}

//withdrawToken tests 
function test_canWithdrawToken_unit() public {
	deal(address(usdt), david, 100e6); 
	vm.startPrank(david); 
	usdt.approve(address(optimusPrime), 100e6);
	optimusPrime.depositToken(address(usdt), 100e6);
	assertEq(IERC20(usdt).balanceOf(david), 0); 
	assertEq(IERC20(usdt).balanceOf(address(optimusPrime)), 100e6); 

	optimusPrime.withdrawToken(address(usdt), 100e6);
	assertEq(IERC20(usdt).balanceOf(david), 100e6); 
	assertEq(IERC20(usdt).balanceOf(address(optimusPrime)), 0); 
}

function test_WithdrawToken_fuzz(uint256 amount) public {
	amount = bound(amount, 1, 100_000_000e6);
	deal(address(usdt), david, amount); 
	vm.startPrank(david); 
	usdt.approve(address(optimusPrime), amount);
	optimusPrime.depositToken(address(usdt), amount);
	assertEq(IERC20(usdt).balanceOf(david), 0); 
	assertEq(IERC20(usdt).balanceOf(address(optimusPrime)), amount); 

	optimusPrime.withdrawToken(address(usdt), amount);
	assertEq(IERC20(usdt).balanceOf(david), amount); 
	assertEq(IERC20(usdt).balanceOf(address(optimusPrime)), 0); 
}

//setTradeExecutor tests
function test_canSetTradeExecutor() public {
	vm.startPrank(david); 
	optimusPrime.setTradeExecutor(address(bob)); 
	assertEq(optimusPrime.tradeExecutor(), bob); 
}

function test_cantSetTradeExecutor_0Address() public {
	vm.startPrank(david); 
	vm.expectRevert( "Can't be a 0 address");
	optimusPrime.setTradeExecutor(address(0)); 
}

function test_cantSetTradeExecutor_NotSelf() public {
	vm.startPrank(david); 
	vm.expectRevert( "Can't be this address"); 
	optimusPrime.setTradeExecutor(address(optimusPrime)); 
}

function test_cantSetTradeExecutor_NotTheOwner() public {
	vm.expectRevert(abi.encodeWithSelector(OptimusPrime.NotTheOwner.selector, address(this))); 
	optimusPrime.setTradeExecutor(address(123));

}




}