// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {OptimusPrime} from "../../src/OptimusPrime/OptimusPrime.sol"; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
 
contract OptimusPrimeTradingTest is Test {

address public constant uniswapRouterV3 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45; 
address public constant pancakeRouterV3 = 0x1b81D678ffb9C0263b24A97847620C99d213eB14;

IERC20 public constant usdt = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);  
IERC20 public constant usdc = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831); 
IERC20 public constant link = IERC20(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4); 

IERC20 public constant weth = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); 

address public david = makeAddr("david"); 
address public bob = makeAddr("bob"); 

address public tradeExecutor = makeAddr("tradeExecutor"); 

OptimusPrime public optimusPrime; 

function setUp() public {
vm.startPrank(david); 
optimusPrime = new OptimusPrime(pancakeRouterV3, uniswapRouterV3, address(usdt), address(usdc)); 
vm.stopPrank(); 
}

//tradeOnUniswapV3AndPancakeV3 tests 
function test_canTradeOnUniswapV3AndPancakeV3_unit() public {
	deal(address(usdt), david, 100e6); 
	vm.startPrank(david); 
	usdt.approve(address(optimusPrime), 100e6);
	optimusPrime.depositToken(address(usdt), 100e6);
	optimusPrime.setTradeExecutor(tradeExecutor);
	optimusPrime.approveToken(address(usdt), uniswapRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(usdt), pancakeRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(weth), pancakeRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(weth), uniswapRouterV3, type(uint256).max); 
	vm.stopPrank(); 

	vm.startPrank(tradeExecutor); 

	(bool success,) = address(optimusPrime).call(abi.encodeWithSelector(optimusPrime.tradeOnUniswapV3AndPancakeV3.selector,address(usdt), address(weth), 100e6, 500, 100));
		if(!success) {
			console.log("Unable to profit, USDT balance is: ", ERC20(address(usdt)).balanceOf(address(optimusPrime))); 
		} else {
			console.log("Able to profit, USDT balance is: ", ERC20(address(usdt)).balanceOf(address(optimusPrime)));
		}
	vm.stopPrank(); 
}

function test_canTradeOnUniswapV3AndPancakeV3_fuzz(uint256 amount) public {
	amount = bound(amount, 100e6, 100_000e6); 
	deal(address(usdt), david, amount); 
	vm.startPrank(david); 
	usdt.approve(address(optimusPrime), amount);
	optimusPrime.depositToken(address(usdt), amount);
	optimusPrime.setTradeExecutor(tradeExecutor);
	optimusPrime.approveToken(address(usdt), uniswapRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(usdt), pancakeRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(weth), pancakeRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(weth), uniswapRouterV3, type(uint256).max); 
	vm.stopPrank(); 

	vm.startPrank(tradeExecutor); 

	(bool success,) = address(optimusPrime).call(abi.encodeWithSelector(optimusPrime.tradeOnUniswapV3AndPancakeV3.selector,address(usdt), address(weth), amount, 500, 100));
		if(!success) {
			console.log("Unable to profit, USDT balance is: ", ERC20(address(usdt)).balanceOf(address(optimusPrime))); 
		} else {
			console.log("Able to profit, USDT balance is: ", ERC20(address(usdt)).balanceOf(address(optimusPrime)));
		} 
	vm.stopPrank(); 
}

function test_cantTradeOnUniswapV3AndPancakeV3_notTheTradeExecutor() public {
	deal(address(usdt), david, 100e6); 
	vm.startPrank(david); 
	usdt.approve(address(optimusPrime), 100e6);
	optimusPrime.depositToken(address(usdt), 100e6);
	optimusPrime.setTradeExecutor(tradeExecutor);
	optimusPrime.approveToken(address(usdt), uniswapRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(usdt), pancakeRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(weth), pancakeRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(weth), uniswapRouterV3, type(uint256).max); 
 
	vm.expectRevert(abi.encodeWithSelector(OptimusPrime.NotTheTradeExecutor.selector, david)); 
	optimusPrime.tradeOnUniswapV3AndPancakeV3(address(usdt), address(weth), 100e6, 500, 100); 
	vm.stopPrank(); 
}

//tradeOnPancakeV3AndUniswapV3 tests 
function test_cantTradeOnPancakeV3AndUniswapV3_unit() public {
	deal(address(usdt), david, 100e6); 
	vm.startPrank(david); 
	usdt.approve(address(optimusPrime), 100e6);
	optimusPrime.depositToken(address(usdt), 100e6);
	optimusPrime.setTradeExecutor(tradeExecutor);
	optimusPrime.approveToken(address(usdt), uniswapRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(usdt), pancakeRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(weth), pancakeRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(weth), uniswapRouterV3, type(uint256).max); 
	vm.stopPrank(); 

	vm.startPrank(tradeExecutor); 

	(bool success,) = address(optimusPrime).call(abi.encodeWithSelector(optimusPrime.tradeOnPancakeV3AndUniswapV3.selector,address(usdt), address(weth), 100e6, 100, 500));
		if(!success) {
			console.log("Unable to profit, USDT balance is: ", ERC20(address(usdt)).balanceOf(address(optimusPrime))); 
		} else {
			console.log("Able to profit, USDT balance is: ", ERC20(address(usdt)).balanceOf(address(optimusPrime)));
		}
	vm.stopPrank(); 
}

function test_cantTradeOnPancakeV3AndUniswapV3_fuzz(uint256 amount) public {
	amount = bound(amount, 100e6, 100_000e6); 
	deal(address(usdt), david, amount); 
	vm.startPrank(david); 
	usdt.approve(address(optimusPrime), amount);
	optimusPrime.depositToken(address(usdt), amount);
	optimusPrime.setTradeExecutor(tradeExecutor);
	optimusPrime.approveToken(address(usdt), uniswapRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(usdt), pancakeRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(weth), pancakeRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(weth), uniswapRouterV3, type(uint256).max); 
	vm.stopPrank(); 

	vm.startPrank(tradeExecutor); 

	(bool success,) = address(optimusPrime).call(abi.encodeWithSelector(optimusPrime.tradeOnPancakeV3AndUniswapV3.selector,address(usdt), address(weth), amount, 100, 500));
		if(!success) {
			console.log("Unable to profit, USDT balance is: ", ERC20(address(usdt)).balanceOf(address(optimusPrime))); 
		} else {
			console.log("Able to profit, USDT balance is: ", ERC20(address(usdt)).balanceOf(address(optimusPrime)));
		} 
	vm.stopPrank(); 
}

function test_cantTradeOnPancakeV3AndUniswapV3_notTheTradeExecutor() public {
	deal(address(usdt), david, 100e6); 
	vm.startPrank(david); 
	usdt.approve(address(optimusPrime), 100e6);
	optimusPrime.depositToken(address(usdt), 100e6);
	optimusPrime.setTradeExecutor(tradeExecutor);
	optimusPrime.approveToken(address(usdt), uniswapRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(usdt), pancakeRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(weth), pancakeRouterV3, type(uint256).max); 
	optimusPrime.approveToken(address(weth), uniswapRouterV3, type(uint256).max); 
 
	vm.expectRevert(abi.encodeWithSelector(OptimusPrime.NotTheTradeExecutor.selector, david)); 
	optimusPrime.tradeOnPancakeV3AndUniswapV3(address(usdt), address(weth), 100e6, 100, 500); 
	vm.stopPrank(); 
}



}