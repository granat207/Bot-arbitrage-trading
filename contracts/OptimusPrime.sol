//SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.19; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./pancakeswap/IV3PancakeSwapRouter.sol"; //PancakeSwapV3 Router

import "./pancakeswap/IPancakeV3Pool.sol"; //PancakeV3 Pool

contract OptimusPrime {

error NotTheOwner(address sender); 

error NotTheTradeExecutor(address sender); 

error NoProfit(uint256 finalBalance); 

error TokenNotAccepted(address token); 

event Profit(uint256 _finalBalance); 

address private immutable owner; 

address public tradeExecutor; 

IERC20 public constant weth = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); 

IERC20 public constant usdt = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9); 

IERC20 public constant usdc = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831); 

bool public isLocked; 

IV3PancakeSwapRouter public immutable pancakeRouterV3; 

constructor(address _pancakeswapRouterV3) {
pancakeRouterV3 = IV3PancakeSwapRouter(_pancakeswapRouterV3); 
owner = msg.sender; 
}


modifier OnlyOwner() {
if(msg.sender != owner){
   revert NotTheOwner(msg.sender); 
  }
_; 
}

modifier OnlyTradeExecutor() {
if(msg.sender != tradeExecutor){
   revert NotTheTradeExecutor(msg.sender); 
  }
_; 
}

//LOCK 
function lock() public OnlyOwner(){
require(isLocked == false, "Already locked"); 
isLocked = true; 
}

//UNLOCK 
function unlock() public OnlyOwner(){
require(isLocked == true, "Not locked"); 
isLocked = false; 
}

//DEPOSIT
function depositToken(address token, uint256 amount) public OnlyOwner(){
if(token != address(usdt) && token != address(usdc)){
revert TokenNotAccepted(token); 
}
require(amount > 0, "Amount can't be 0"); 
IERC20(token).transferFrom(msg.sender, address(this), amount);
}

//WITHDRAW
function withdrawToken(address token, uint256 amount) public OnlyOwner(){
require(amount <= IERC20(token).balanceOf(address(this)), "Amount is higher than balance"); 
IERC20(token).transfer(msg.sender, amount);
}



function trade1(IV3PancakeSwapRouter.ExactInputParams memory params, uint256 initialAmountIn) public OnlyTradeExecutor {
uint256 initialUsdtBalance = IERC20(usdt).balanceOf(address(this));

IV3PancakeSwapRouter(pancakeRouterV3).exactInput(params);

uint256 finalUsdtBalance = IERC20(usdt).balanceOf(address(this));
if((finalUsdtBalance - initialUsdtBalance) > initialAmountIn){
emit Profit(finalUsdtBalance - initialUsdtBalance);
}else{
revert NoProfit(finalUsdtBalance  - initialUsdtBalance); 
}
}


function trade2(IV3PancakeSwapRouter.ExactInputParams memory params, uint256 initialAmountIn) public OnlyTradeExecutor(){
uint256 initialUsdcBalance = IERC20(usdc).balanceOf(address(this));

IV3PancakeSwapRouter(pancakeRouterV3).exactInput(params);

uint256 finalUsdcBalance = IERC20(usdc).balanceOf(address(this));
if((finalUsdcBalance - initialUsdcBalance) > initialAmountIn){
emit Profit(finalUsdcBalance - initialUsdcBalance);
}else{
revert NoProfit(finalUsdcBalance - initialUsdcBalance); 
}
}



//USDT --> USDC, no slippage
function swapUSDTforUSDCnoSlippage() public OnlyOwner(){
uint24 fee = 100; 
uint256 amountIn = IERC20(usdt).balanceOf(address(this)); 
IV3PancakeSwapRouter.ExactInputParams memory params = IV3PancakeSwapRouter.ExactInputParams({
path: abi.encodePacked(address(usdt), fee, address(usdc)),
recipient: address(this), 
deadline: block.timestamp, 
amountIn: amountIn, 
amountOutMinimum: 0
}); 
IV3PancakeSwapRouter(pancakeRouterV3).exactInput(params);
}

//USDC --> USDT, no slippage
function swapUSDCforUSDTnoSlippage() public OnlyOwner(){
uint24 fee = 100; 
uint256 amountIn = IERC20(usdc).balanceOf(address(this)); 
IV3PancakeSwapRouter.ExactInputParams memory params = IV3PancakeSwapRouter.ExactInputParams({
path: abi.encodePacked(address(usdc), fee, address(usdt)),
recipient: address(this), 
deadline: block.timestamp, 
amountIn: amountIn, 
amountOutMinimum:  0
}); 
IV3PancakeSwapRouter(pancakeRouterV3).exactInput(params);
}



//APPROVE TOKENS
function approveToken(address tokenToApprove, address spender, uint256 amount) public OnlyOwner(){
IERC20(tokenToApprove).approve(spender, amount);
}

//SET TRADE EXECUTOR
function setTradeExecutor(address _tradeExecutor) public OnlyOwner(){
require(_tradeExecutor != (address(0)), "Can't be a 0 address"); 
require(_tradeExecutor != address(this), "Can't be this address");
tradeExecutor = _tradeExecutor; 
}



//RETURN DATA, VIEW
function returnBlockTimestamp() public view returns(uint256){
return block.timestamp; 
}

function returnTokenBalance(address token) public view returns(uint256) {
return IERC20(token).balanceOf(address(this));
}

function returnPathData(address tokenA, uint24 poolFee, address tokenB) public pure returns (bytes memory){
return abi.encodePacked(tokenA, poolFee, tokenB);
}

} 