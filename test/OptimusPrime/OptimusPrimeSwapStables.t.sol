// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {OptimusPrime} from "../../src/OptimusPrime/OptimusPrime.sol"; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
 
contract OptimusPrimeSwapStablesTest is Test {

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

//approveToken tests 
function test_canApproveToken() public {
	vm.startPrank(david); 
	optimusPrime.approveToken(address(usdt), uniswapRouterV3, type(uint256).max); 
}

function test_cantApproveToken_NotTheOwner() public {
	vm.expectRevert(abi.encodeWithSelector(OptimusPrime.NotTheOwner.selector, address(this))); 
	optimusPrime.approveToken(address(usdt), uniswapRouterV3, type(uint256).max); 
}

//swapStablesWithoutSlippage tests 
function test_canSwapStablesWithoutSlippage_unit() public {
	deal(address(usdt), david, 100e6); 
	vm.startPrank(david); 
	usdt.approve(address(optimusPrime), 100e6);
	optimusPrime.depositToken(address(usdt), 100e6);

	optimusPrime.approveToken(address(usdt), uniswapRouterV3, type(uint256).max); 
	
	assertEq(usdc.balanceOf(address(optimusPrime)), 0); 

	optimusPrime.swapStablesWithoutSlippage(address(usdt), address(usdc), 100e6, 100);

	assertEq(usdt.balanceOf(address(optimusPrime)), 0); 
	assertGt(usdc.balanceOf(address(optimusPrime)), 0);
}

function test_canSwapStablesWithoutSlippage_fuzz_fromUsdtToUsdc(uint256 amount) public {
	amount = bound(amount, 10, 100_000e6); 
	deal(address(usdt), david, amount); 
	vm.startPrank(david); 
	usdt.approve(address(optimusPrime), amount);
	optimusPrime.depositToken(address(usdt), amount);

	optimusPrime.approveToken(address(usdt), uniswapRouterV3, type(uint256).max); 
	
	assertEq(usdc.balanceOf(address(optimusPrime)), 0); 

	optimusPrime.swapStablesWithoutSlippage(address(usdt), address(usdc), amount, 100);

	assertEq(usdt.balanceOf(address(optimusPrime)), 0); 
	assertGt(usdc.balanceOf(address(optimusPrime)), 0);
}

function test_canSwapStablesWithoutSlippage_fuzz_fromUsdcToUsdt(uint256 amount) public {
	amount = bound(amount, 10, 100_000e6); 
	deal(address(usdc), david, amount); 
	vm.startPrank(david); 
	usdc.approve(address(optimusPrime), amount);
	optimusPrime.depositToken(address(usdc), amount);

	optimusPrime.approveToken(address(usdc), uniswapRouterV3, type(uint256).max); 
	
	assertEq(usdt.balanceOf(address(optimusPrime)), 0); 

	optimusPrime.swapStablesWithoutSlippage(address(usdc), address(usdt), amount, 100);

	assertEq(usdc.balanceOf(address(optimusPrime)), 0); 
	assertGt(usdt.balanceOf(address(optimusPrime)), 0);
}
 
function test_cantSwapStablesWithoutSlippage_notTheOwner() public {
	deal(address(usdt), david, 100e6); 
	vm.startPrank(david); 
	usdt.approve(address(optimusPrime), 100e6);
	optimusPrime.depositToken(address(usdt), 100e6);

	optimusPrime.approveToken(address(usdt), uniswapRouterV3, type(uint256).max); 
	
	assertEq(usdc.balanceOf(address(optimusPrime)), 0); 
    
	vm.startPrank(address(this));
	vm.expectRevert(abi.encodeWithSelector(OptimusPrime.NotTheOwner.selector, address(this))); 
	optimusPrime.swapStablesWithoutSlippage(address(usdt), address(usdc), 100e6, 100);
}

//swapStablesWithSlippage tests 
function test_canSwapStablesWithSlippage_unit() public {
	deal(address(usdt), david, 100e6); 
	vm.startPrank(david); 
	usdt.approve(address(optimusPrime), 100e6);
	optimusPrime.depositToken(address(usdt), 100e6);

	optimusPrime.approveToken(address(usdt), uniswapRouterV3, type(uint256).max); 
	
	assertEq(usdc.balanceOf(address(optimusPrime)), 0); 

	optimusPrime.swapStablesWithSlippage(address(usdt), address(usdc), 100e6, 100);

	assertEq(usdt.balanceOf(address(optimusPrime)), 0); 
	assertGt(usdc.balanceOf(address(optimusPrime)), (995 * 100e6) / 1000);
}

function test_canSwapStablesWithSlippage_fuzz_fromUsdtToUsdc(uint256 amount) public {
	amount = bound(amount, 1000, 100_000e6); 
	deal(address(usdt), david, amount); 
	vm.startPrank(david); 
	usdt.approve(address(optimusPrime), amount);
	optimusPrime.depositToken(address(usdt), amount);

	optimusPrime.approveToken(address(usdt), uniswapRouterV3, type(uint256).max); 
	
	assertEq(usdc.balanceOf(address(optimusPrime)), 0); 

	optimusPrime.swapStablesWithSlippage(address(usdt), address(usdc), amount, 100);

	assertEq(usdt.balanceOf(address(optimusPrime)), 0); 
	assertGt(usdc.balanceOf(address(optimusPrime)), (995 * amount) / 1000);
}

function test_canSwapStablesWithSlippage_fuzz_fromUsdcToUsdt(uint256 amount) public {
	amount = bound(amount, 1000, 100_000e6); 
	deal(address(usdc), david, amount); 
	vm.startPrank(david); 
	usdc.approve(address(optimusPrime), amount);
	optimusPrime.depositToken(address(usdc), amount);

	optimusPrime.approveToken(address(usdc), uniswapRouterV3, type(uint256).max); 
	
	assertEq(usdt.balanceOf(address(optimusPrime)), 0); 

	optimusPrime.swapStablesWithSlippage(address(usdc), address(usdt), amount, 100);

	assertEq(usdc.balanceOf(address(optimusPrime)), 0); 
	assertGt(usdt.balanceOf(address(optimusPrime)), (995 * amount) / 1000);
}

function test_cantSwapStablesWithSlippage_notTheOwner() public {
	deal(address(usdt), david, 100e6); 
	vm.startPrank(david); 
	usdt.approve(address(optimusPrime), 100e6);
	optimusPrime.depositToken(address(usdt), 100e6);

	optimusPrime.approveToken(address(usdt), uniswapRouterV3, type(uint256).max); 
	
	assertEq(usdc.balanceOf(address(optimusPrime)), 0); 

	vm.startPrank(address(this));
	vm.expectRevert(abi.encodeWithSelector(OptimusPrime.NotTheOwner.selector, address(this))); 
	optimusPrime.swapStablesWithSlippage(address(usdt), address(usdc), 100e6, 100);
}




}