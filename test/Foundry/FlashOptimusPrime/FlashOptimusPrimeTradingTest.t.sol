// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//run test --> sudo forge test --match-path test/Foundry/FlashOptimusPrime/FlashOptimusPrimeTradingTest.t.sol -vvv --fork-url https://convincing-rough-vineyard.arbitrum-mainnet.quiknode.pro/fc6cefc5774214bf87fce9243adf40285dc3b96f/ --gas-report

import {Test, console} from "forge-std/Test.sol";

import {FlashOptimusPrime} from "../../../contracts/FlashOptimusPrime.sol"; 

contract FlashOptimusPrimeTradingTest is Test {

address public constant pancakeRouterV3 = 0x1b81D678ffb9C0263b24A97847620C99d213eB14;

address public constant uniswapRouterV3 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45; 

address public owner; 

address wbtcWethUniswap500 = 0x2f5e87C9312fa29aed5c179E456625D79015299c; 
address wethUsdcUniswap500 = 0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443; 
address wethUsdtUniswap500 = 0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443; 
address usdcUsdtUniswap100 = 0xbE3aD6a5669Dc0B8b12FeBC03608860C31E2eef6; 
address wbtcUsdcUniswap500 = 0xac70bD92F89e6739B3a08Db9B6081a923912f73D; 
address daiUsdtUniswap100 = 0x7f580f8A02b759C350E6b8340e7c2d4b8162b6a9;
address knsWethUniswap100 = 0x68C685Fd52A56f04665b491D491355a624540e85; 

address public constant wbtc = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f; 
address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; 
address public constant usdt = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;  
address public constant usdc = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831; 
address public constant pendle = 0x0c880f6761F1af8d9Aa9C466984b80DAb9a8c9e8; 

FlashOptimusPrime public flashOptimusPrime; 

function setUp() public {
owner = address(this); 
flashOptimusPrime = new FlashOptimusPrime(pancakeRouterV3, uniswapRouterV3); 

vm.startPrank(owner);
flashOptimusPrime.approveToken(wbtc, uniswapRouterV3, type(uint256).max);
flashOptimusPrime.approveToken(weth, uniswapRouterV3, type(uint256).max);
flashOptimusPrime.approveToken(usdc, uniswapRouterV3, type(uint256).max);
flashOptimusPrime.approveToken(usdt, uniswapRouterV3, type(uint256).max);
}

function test_flash__triangularUniswap_1() public {
vm.startPrank(address(owner));

address[] memory path = new address[](2); 
path[0] = weth; 
path[1] = usdt; 

uint24[] memory poolFees = new uint24[](3); 
poolFees[0] = 500; 
poolFees[1] = 500; 
poolFees[2] = 500; 
flashOptimusPrime.initFlash(1, true, wbtcUsdcUniswap500, wbtc, 1e6, 0, 500, path, poolFees);
}

function test_flash__triangularUniswap_2() public {
vm.startPrank(address(owner));

address[] memory path = new address[](2); 
path[0] = weth; 
path[1] = wbtc; 

uint24[] memory poolFees = new uint24[](3); 
poolFees[0] = 500; 
poolFees[1] = 500; 
poolFees[2] = 500; 
flashOptimusPrime.initFlash(1, true, usdcUsdtUniswap100, usdc, 1000e6, 0, 100, path, poolFees);
}

function test_flash__triangularUniswap_3() public {
vm.startPrank(address(owner));

address[] memory path = new address[](2); 
path[0] = weth; 
path[1] = usdc; 

uint24[] memory poolFees = new uint24[](3); 
poolFees[0] = 500; 
poolFees[1] = 500; 
poolFees[2] = 100; 
flashOptimusPrime.initFlash(1, true, daiUsdtUniswap100, usdt, 0, 1000e6, 100, path, poolFees);
}

}
