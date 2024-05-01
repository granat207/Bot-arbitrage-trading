//SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.19; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./pancakeswap/IV3PancakeSwapRouter.sol"; //PancakeSwapV3

import "./pancakeswap/IPancakeV3Pool.sol"; //PancakeV3 Pool

import "./chainlink/PriceAggregator.sol"; //Chainlink aggregator

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

IV3PancakeSwapRouter public immutable pancakeRouterV3; 

mapping(address => mapping(address => uint256)) private numberOfTokensApproved; 

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
if(token != address(usdt) && token != address(usdc)){
revert TokenNotAccepted(token); 
}
require(amount <= IERC20(token).balanceOf(address(this)), "Amount is higher than balance"); 
IERC20(token).transfer(msg.sender, amount);
}



//USDC --> WETH --> USDT
function trade1(IV3PancakeSwapRouter.ExactInputParams memory params, uint256 initialAmountIn) public OnlyTradeExecutor {
uint256 initialUsdtBalance = IERC20(usdt).balanceOf(address(this));

sellTokenForWETH_pancakeswapV3(params);
uint24 fee = 100; 
IV3PancakeSwapRouter.ExactInputParams memory wethToUsdtParams = IV3PancakeSwapRouter.ExactInputParams({
path: abi.encodePacked(address(weth), fee, address(usdt)),
recipient: address(this), 
deadline: block.timestamp, 
amountIn: IERC20(weth).balanceOf(address(this)), 
amountOutMinimum: 0
}); 
buyTokenWithWETH_pancakeswapV3(wethToUsdtParams);

uint256 finalUsdtBalance = IERC20(usdt).balanceOf(address(this));
if((finalUsdtBalance - initialUsdtBalance) > initialAmountIn){
emit Profit(finalUsdtBalance - initialUsdtBalance);
}else{
revert NoProfit(finalUsdtBalance  - initialUsdtBalance); 
}
}


//USDT --> WETH --> USDC 
function trade2(IV3PancakeSwapRouter.ExactInputParams memory params, uint256 initialAmountIn) public OnlyTradeExecutor(){
uint256 initialUsdcBalance = IERC20(usdc).balanceOf(address(this));

sellTokenForWETH_pancakeswapV3(params);
uint24 fee = 100; 
IV3PancakeSwapRouter.ExactInputParams memory wethToUsdcParams = IV3PancakeSwapRouter.ExactInputParams({
path: abi.encodePacked(address(weth), fee, address(usdc)),
recipient: address(this), 
deadline: block.timestamp, 
amountIn: IERC20(weth).balanceOf(address(this)), 
amountOutMinimum: 0
}); 
buyTokenWithWETH_pancakeswapV3(wethToUsdcParams);

uint256 finalUsdcBalance = IERC20(usdc).balanceOf(address(this));
if((finalUsdcBalance - initialUsdcBalance) > initialAmountIn){
emit Profit(finalUsdcBalance - initialUsdcBalance);
}else{
revert NoProfit(finalUsdcBalance - initialUsdcBalance); 
}
}

//USDC --> WETH --> USDT --> USDC
function trade3(IV3PancakeSwapRouter.ExactInputParams memory params) public OnlyTradeExecutor() {
uint256 initialUsdcBalance = IERC20(usdc).balanceOf(address(this));
uint256 initialUsdtBalance = IERC20(usdt).balanceOf(address(this));

sellTokenForWETH_pancakeswapV3(params);

uint24 fee = 100; 
IV3PancakeSwapRouter.ExactInputParams memory wethToUsdtParams = IV3PancakeSwapRouter.ExactInputParams({
path: abi.encodePacked(address(weth), fee, address(usdt)),
recipient: address(this), 
deadline: block.timestamp, 
amountIn: IERC20(weth).balanceOf(address(this)), 
amountOutMinimum: 0
}); 
buyTokenWithWETH_pancakeswapV3(wethToUsdtParams);

IV3PancakeSwapRouter.ExactInputParams memory usdtToUsdcParams = IV3PancakeSwapRouter.ExactInputParams({
path: abi.encodePacked(address(usdt), fee, address(usdc)),
recipient: address(this), 
deadline: block.timestamp, 
amountIn: IERC20(usdt).balanceOf(address(this)) - initialUsdtBalance, 
amountOutMinimum: 0
}); 
tradeUSDCandUSDT(usdtToUsdcParams);

uint256 finalUsdcBalance = IERC20(usdc).balanceOf(address(this));
if(finalUsdcBalance > initialUsdcBalance){
emit Profit(finalUsdcBalance);
}else{
revert NoProfit(finalUsdcBalance); 
}
}

//USDT --> WETH --> USDC --> USDT
function trade4(IV3PancakeSwapRouter.ExactInputParams memory params) public OnlyTradeExecutor() {
uint256 initialUsdcBalance = IERC20(usdc).balanceOf(address(this));
uint256 initialUsdtBalance = IERC20(usdt).balanceOf(address(this));

sellTokenForWETH_pancakeswapV3(params);

uint24 fee = 100; 
IV3PancakeSwapRouter.ExactInputParams memory wethToUsdcParams = IV3PancakeSwapRouter.ExactInputParams({
path: abi.encodePacked(address(weth), fee, address(usdc)),
recipient: address(this), 
deadline: block.timestamp, 
amountIn: IERC20(weth).balanceOf(address(this)), 
amountOutMinimum: 0
}); 
buyTokenWithWETH_pancakeswapV3(wethToUsdcParams);

IV3PancakeSwapRouter.ExactInputParams memory usdcToUsdtParams = IV3PancakeSwapRouter.ExactInputParams({
path: abi.encodePacked(address(usdc), fee, address(usdt)),
recipient: address(this), 
deadline: block.timestamp, 
amountIn: IERC20(usdc).balanceOf(address(this)) - initialUsdcBalance, 
amountOutMinimum: 0
}); 
tradeUSDCandUSDT(usdcToUsdtParams);

uint256 finalUsdtBalance = IERC20(usdt).balanceOf(address(this));
if(finalUsdtBalance > initialUsdtBalance){
emit Profit(finalUsdtBalance);
}else{
revert NoProfit(finalUsdtBalance); 
}
}


//BUY / SELL TOKENS --> PancakeswapV3
function buyTokenWithWETH_pancakeswapV3(IV3PancakeSwapRouter.ExactInputParams memory params) internal {
IV3PancakeSwapRouter(pancakeRouterV3).exactInput(params);
}

function sellTokenForWETH_pancakeswapV3(IV3PancakeSwapRouter.ExactInputParams memory params) internal {
IV3PancakeSwapRouter(pancakeRouterV3).exactInput(params);
}

function tradeUSDCandUSDT(IV3PancakeSwapRouter.ExactInputParams memory params) internal {
IV3PancakeSwapRouter(pancakeRouterV3).exactInput(params);
}


//APPROVE TOKENS
function approveToken(address tokenToApprove, address spender, uint256 amount) public OnlyOwner(){
numberOfTokensApproved[tokenToApprove][spender] = amount; 
IERC20(tokenToApprove).approve(spender, amount);
}

//SET TRADE EXECUTOR
function setTradeExecutor(address _tradeExecutor) public OnlyOwner(){
require(_tradeExecutor != (address(0)), "Can't be a 0 address"); 
require(_tradeExecutor != address(this), "Can't be this address");
tradeExecutor = _tradeExecutor; 
}



//RETURN DATA, VIEW
function returnETHPrice() public view returns(int){
(/* uint80 roundID */, int answer,/*uint startedAt*/, /*uint timeStamp*/, /*uint80 answeredInRound*/) = 
PriceAggregator(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612).latestRoundData(); 
return answer;
}

function returnBlockTimestamp() public view returns(uint256){
return block.timestamp; 
}

function returnPancakePoolV3Price(address pool) public view returns(uint160){
(uint160 sqrtPriceX96 , , , , , , ) = IPancakeV3Pool(pool).slot0();
return sqrtPriceX96; 
}

function returnOwner() public view returns(address) {
return owner; 
}

function returnTokenApproved(address token, address spender)public view returns(uint256){
return numberOfTokensApproved[token][spender]; 
}

function returnTokenBalance(address token) public view returns(uint256) {
return IERC20(token).balanceOf(address(this));
}

function returnPathData(address tokenA, uint24 poolFee, address tokenB) public pure returns (bytes memory){
return abi.encodePacked(tokenA, poolFee, tokenB);
}

} 