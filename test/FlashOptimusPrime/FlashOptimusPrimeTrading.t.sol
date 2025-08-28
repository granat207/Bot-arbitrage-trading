// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {FlashOptimusPrime} from "../../src/FlashOptimusPrime/FlashOptimusPrime.sol"; 

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

contract FlashOptimusPrimeTradingTest is Test {

address public constant pancakeRouterV3 = 0x1b81D678ffb9C0263b24A97847620C99d213eB14;

address public constant uniswapRouterV3 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45; 

IERC20 public constant usdt = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);  
IERC20 public constant usdc = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831); 
IERC20 public constant link = IERC20(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4); 

IERC20 public constant weth = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); 

address public constant usdcUsdt100 = 0xbE3aD6a5669Dc0B8b12FeBC03608860C31E2eef6; 

address public bob = makeAddr("bob"); 
address public david = makeAddr("david"); 
address public tradeExecutor = makeAddr("tradeExecutor"); 

FlashOptimusPrime public flashOptimusPrime; 

function setUp() public {
	vm.startPrank(david); 
	flashOptimusPrime = new FlashOptimusPrime(pancakeRouterV3, uniswapRouterV3); 

	flashOptimusPrime.approveToken(address(usdt), address(uniswapRouterV3), type(uint256).max); 
	flashOptimusPrime.approveToken(address(weth), address(uniswapRouterV3), type(uint256).max); 
	flashOptimusPrime.approveToken(address(usdt), address(pancakeRouterV3), type(uint256).max); 
	flashOptimusPrime.approveToken(address(weth), address(pancakeRouterV3), type(uint256).max); 
	flashOptimusPrime.setTradeExecutor(tradeExecutor); 
	vm.stopPrank();
}

//tradeOnUniswapV3AndPancakeV3 tests
function test_canTradeOnUniswapV3AndPancakeV3_unit() public {
	vm.startPrank(tradeExecutor); 

	uint24[] memory poolFees = new uint24[](2); 
	poolFees[0] = 500; 
	poolFees[1] = 100; 
	(bool success, ) = address(flashOptimusPrime).call{value: 0}(
		abi.encodeWithSelector(FlashOptimusPrime.initFlash.selector, FlashOptimusPrime.CodePath.UniswapV3AndPancakeV3, usdcUsdt100, address(usdt), address(weth), 0, 10_000e6, poolFees));
	
	if(success) {
		assertEq(flashOptimusPrime.isFlashLoaning(), false); 
		assertEq(flashOptimusPrime.tokenBorrowed(), address(usdt)); 
		assertEq(flashOptimusPrime.tokenToTrade(), address(weth)); 
		assertEq(flashOptimusPrime.borrowedByPool(), usdcUsdt100); 
		assertEq(flashOptimusPrime.amountBorrowed(), 10_000e6); 
		assertEq(flashOptimusPrime.poolFees(0), poolFees[0]); 
		assertEq(flashOptimusPrime.poolFees(1), poolFees[1]); 
		assertEq(flashOptimusPrime.isFeeZero(), false); 
		assertEq(flashOptimusPrime.initialBalance(), 0); 
		console.log("Able to profit, USDT balance is ", usdt.balanceOf(address(flashOptimusPrime)));
	} else {
		console.log("Unable to profit"); 
	}

	vm.stopPrank(); 
}

function test_cantTradeOnUniswapV3AndPancakeV3_notTheTradeExecutor() public {
	uint24[] memory poolFees = new uint24[](2); 
	poolFees[0] = 500; 
	poolFees[1] = 100; 
	vm.expectRevert(abi.encodeWithSelector(FlashOptimusPrime.NotTheTradeExecutor.selector, address(this))); 
	address(flashOptimusPrime).call{value: 0}(
		abi.encodeWithSelector(FlashOptimusPrime.initFlash.selector, FlashOptimusPrime.CodePath.UniswapV3AndPancakeV3, usdcUsdt100, address(usdt), address(weth), 0, 10_000e6, poolFees));
}

function test_cantTradeOnUniswapV3AndPancakeV3_botAmountAreGt0() public {
	vm.startPrank(tradeExecutor); 

	uint24[] memory poolFees = new uint24[](2); 
	poolFees[0] = 500; 
	poolFees[1] = 100; 
	vm.expectRevert(abi.encodeWithSelector(FlashOptimusPrime.NotTheTradeExecutor.selector, 100e6, 10_000e6)); 
	address(flashOptimusPrime).call{value: 0}(
		abi.encodeWithSelector(FlashOptimusPrime.initFlash.selector, FlashOptimusPrime.CodePath.UniswapV3AndPancakeV3, usdcUsdt100, address(usdt), address(weth), 100e6, 10_000e6, poolFees));
}


//tradeOnPancakeV3AndUniswapV3 tests
function test_canTradeOnPancakeV3AndUniswapV3_unit() public {
	vm.startPrank(tradeExecutor); 

	uint24[] memory poolFees = new uint24[](2); 
	poolFees[0] = 100; 
	poolFees[1] = 500; 
	(bool success, ) = address(flashOptimusPrime).call{value: 0}(
		abi.encodeWithSelector(FlashOptimusPrime.initFlash.selector, FlashOptimusPrime.CodePath.PancakeV3AndUniswapV3, usdcUsdt100, address(usdt), address(weth), 0, 10_000e6, poolFees));
	
	if(success) {
		assertEq(flashOptimusPrime.isFlashLoaning(), false); 
		assertEq(flashOptimusPrime.tokenBorrowed(), address(usdt)); 
		assertEq(flashOptimusPrime.tokenToTrade(), address(weth)); 
		assertEq(flashOptimusPrime.borrowedByPool(), usdcUsdt100); 
		assertEq(flashOptimusPrime.amountBorrowed(), 10_000e6); 
		assertEq(flashOptimusPrime.poolFees(0), poolFees[0]); 
		assertEq(flashOptimusPrime.poolFees(1), poolFees[1]); 
		assertEq(flashOptimusPrime.isFeeZero(), false); 
		assertEq(flashOptimusPrime.initialBalance(), 0); 
		console.log("Able to profit, USDT balance is ", usdt.balanceOf(address(flashOptimusPrime)));
	} else {
		console.log("Unable to profit"); 
	}

	vm.stopPrank(); 
}

function test_cantTradeOnPancakeV3AndUniswapV3_notTheTradeExecutor() public {
	uint24[] memory poolFees = new uint24[](2); 
	poolFees[0] = 100; 
	poolFees[1] = 500; 
	vm.expectRevert(abi.encodeWithSelector(FlashOptimusPrime.NotTheTradeExecutor.selector, address(this))); 
	address(flashOptimusPrime).call{value: 0}(
		abi.encodeWithSelector(FlashOptimusPrime.initFlash.selector, FlashOptimusPrime.CodePath.PancakeV3AndUniswapV3, usdcUsdt100, address(usdt), address(weth), 0, 10_000e6, poolFees));
}

function test_cantTradeOnPancakeV3AndUniswapV3_botAmountAreGt0() public {
	vm.startPrank(tradeExecutor); 

	uint24[] memory poolFees = new uint24[](2); 
	poolFees[0] = 100; 
	poolFees[1] = 500; 
	vm.expectRevert(abi.encodeWithSelector(FlashOptimusPrime.NotTheTradeExecutor.selector, 100e6, 10_000e6)); 
	address(flashOptimusPrime).call{value: 0}(
		abi.encodeWithSelector(FlashOptimusPrime.initFlash.selector, FlashOptimusPrime.CodePath.PancakeV3AndUniswapV3, usdcUsdt100, address(usdt), address(weth), 100e6, 10_000e6, poolFees));
}

//uniswapV3FlashCallback tests 
function test_cantuniswapV3FlashCallback_notTheFlashLoanPool() public {
	vm.expectRevert(abi.encodeWithSelector(FlashOptimusPrime.NotTheFlashLoanPool.selector, address(this))); 
	flashOptimusPrime.uniswapV3FlashCallback(100, 100, "");
}



}