//SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.19; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./pancakeswap/IV3PancakeSwapRouter.sol"; //PancakeSwapV3 Router

import "./pancakeswap/IPancakeV3Pool.sol"; //PancakeV3 Pool

import "./uniswap/IV3UniswapSwapRouter.sol"; //UniswapV3 router

import "./uniswap/IUniswapV3Pool.sol"; //UniswapV3 Pool

import "./uniswap/IUniswapV3FlashCallback.sol"; 

contract FlashOptimusPrime is IUniswapV3FlashCallback{

error NotTheOwner(address sender); 

error NoProfit(uint256 finalBalance); 

address public immutable pancakeV3Router; 

address public immutable uniswapV3Router; 

address public immutable owner; 

uint256 public codePath; 

address public tokenBorrowed; 

address public borrowedByPool; 

uint256 public poolFeeTokenBorrowed; 

uint256 public amountBorrowed; 

address[] public path; 

uint24[] public poolFees; 

constructor(address _pancakeV3Router, address _uniswapV3Router) {
pancakeV3Router = _pancakeV3Router; 
uniswapV3Router = _uniswapV3Router; 
owner = msg.sender; 
}

modifier OnlyOwner() {
if(msg.sender != owner) {
revert NotTheOwner(msg.sender); 
}
_; 
}

function initFlash(uint256 _codePath, bool _isUniswpapPool, address _poolBorrowed, address _tokenBorrowed, uint256 _token0AmounBorrowed, uint256 _token1AmountBorrowed, uint256 _feePoolBorrowed, address[] memory _path, uint24[] memory _poolFees) public OnlyOwner(){
codePath = _codePath; 
tokenBorrowed = _tokenBorrowed;
borrowedByPool = _poolBorrowed; 
poolFeeTokenBorrowed = _feePoolBorrowed; 
path = _path; 
poolFees = _poolFees; 
if(_token0AmounBorrowed > 0){
amountBorrowed = _token0AmounBorrowed; 
} else {
amountBorrowed = _token1AmountBorrowed; 
}
if(_isUniswpapPool){
IUniswapV3Pool(_poolBorrowed).flash(address(this), _token0AmounBorrowed, _token1AmountBorrowed, "");
} else {
IPancakeV3Pool(_poolBorrowed).flash(address(this), _token0AmounBorrowed, _token1AmountBorrowed, "");
}
}

function uniswapV3FlashCallback( uint256 fee0, uint256 fee1, bytes memory data) external override{
if(codePath == 1){
tradeTriangularUniswapV3(); 
}
if(codePath == 2){
tradeTriangularPancakeV3(); 
}

uint256 finalBalance = IERC20(tokenBorrowed).balanceOf(address(this)); 
if(finalBalance < amountBorrowed + (amountBorrowed * poolFeeTokenBorrowed) / 1000000){
revert NoProfit(finalBalance); 
}
IERC20(tokenBorrowed).transfer(borrowedByPool, amountBorrowed + (amountBorrowed * poolFeeTokenBorrowed) / 1000000);
}

//Code path: 1
function tradeTriangularUniswapV3() public {
IV3UniswapSwapRouter.ExactInputParams memory params = IV3UniswapSwapRouter.ExactInputParams({
path: abi.encodePacked(tokenBorrowed, poolFees[0], path[0], poolFees[1], path[1], poolFees[2], tokenBorrowed),
recipient: address(this), 
amountIn: amountBorrowed, 
amountOutMinimum: 0
}); 
IV3UniswapSwapRouter(uniswapV3Router).exactInput(params);
}

//Code path: 2
function tradeTriangularPancakeV3() public {}


function approveToken(address token, address spender, uint256 value) public OnlyOwner(){
IERC20(token).approve(spender, value);
}
}