// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {FlashOptimusPrime} from "../../src/FlashOptimusPrime/FlashOptimusPrime.sol"; 

contract FlashOptimusPrimeBasicTest is Test {

address public constant pancakeRouterV3 = 0x1b81D678ffb9C0263b24A97847620C99d213eB14;

address public constant uniswapRouterV3 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45; 

address public bob = makeAddr("bob"); 
address public david = makeAddr("david"); 

FlashOptimusPrime public flashOptimusPrime; 

function setUp() public {
flashOptimusPrime = new FlashOptimusPrime(pancakeRouterV3, uniswapRouterV3); 
}



}
