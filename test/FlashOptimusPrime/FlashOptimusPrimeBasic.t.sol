// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {FlashOptimusPrime} from "../../src/FlashOptimusPrime/FlashOptimusPrime.sol"; 

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

contract FlashOptimusPrimeBasicTest is Test {

address public constant pancakeRouterV3 = 0x1b81D678ffb9C0263b24A97847620C99d213eB14;

address public constant uniswapRouterV3 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45; 

IERC20 public constant usdt = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);  
IERC20 public constant usdc = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831); 
IERC20 public constant link = IERC20(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4); 

IERC20 public constant weth = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); 

address public bob = makeAddr("bob"); 
address public david = makeAddr("david"); 

FlashOptimusPrime public flashOptimusPrime; 

function setUp() public {
	vm.startPrank(david); 
	flashOptimusPrime = new FlashOptimusPrime(pancakeRouterV3, uniswapRouterV3); 
	vm.stopPrank();
}

//withraw tests
function test_canWithdraw_unit() public {
	vm.startPrank(david); 
	deal(address(usdt), address(flashOptimusPrime), 100e6); 
	flashOptimusPrime.withdraw(address(usdt), 100e6);
	assertEq(usdt.balanceOf(address(flashOptimusPrime)), 0); 
	assertEq(usdt.balanceOf(david), 100e6);
}

function test_canWithdraw_fuzz(uint256 amount) public {
	amount = bound(amount, 0, 100_000_000e6);
	vm.startPrank(david); 
	deal(address(usdt), address(flashOptimusPrime), amount); 
	flashOptimusPrime.withdraw(address(usdt), amount);
	assertEq(usdt.balanceOf(address(flashOptimusPrime)), 0); 
	assertEq(usdt.balanceOf(david), amount); 
}

function test_cantWithdraw_NotTheOwner() public {
	deal(address(usdt), address(flashOptimusPrime), 100e6); 
	vm.expectRevert(abi.encodeWithSelector(FlashOptimusPrime.NotTheOwner.selector, address(this))); 
	flashOptimusPrime.withdraw(address(usdt), 100e6);
}

//approveToken tests
function test_canApproveToken() public {
	vm.startPrank(david); 
	flashOptimusPrime.approveToken(address(usdt), address(uniswapRouterV3), 100e6); 
	vm.stopPrank(); 
}

function test_cantApproveToken_notTheOwner() public { 
	vm.expectRevert(abi.encodeWithSelector(FlashOptimusPrime.NotTheOwner.selector, address(this))); 
	flashOptimusPrime.approveToken(address(usdt), address(uniswapRouterV3), 100e6); 
}

//setTradeExecutor tests
function test_canSetTradeExecutor() public {
	vm.startPrank(david); 
	flashOptimusPrime.setTradeExecutor(address(bob)); 
	assertEq(flashOptimusPrime.tradeExecutor(), bob); 
}

function test_cantSetTradeExecutor_0Address() public {
	vm.startPrank(david); 
	vm.expectRevert( "Can't be a 0 address");
	flashOptimusPrime.setTradeExecutor(address(0)); 
}

function test_cantSetTradeExecutor_NotSelf() public {
	vm.startPrank(david); 
	vm.expectRevert( "Can't be this address"); 
	flashOptimusPrime.setTradeExecutor(address(flashOptimusPrime)); 
}

function test_cantSetTradeExecutor_NotTheOwner() public {
	vm.expectRevert(abi.encodeWithSelector(FlashOptimusPrime.NotTheOwner.selector, address(this))); 
	flashOptimusPrime.setTradeExecutor(address(123));

}



}
