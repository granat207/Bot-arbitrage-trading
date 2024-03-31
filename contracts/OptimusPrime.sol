//SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.19; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./uniswap/IV3UniswapSwapRouter.sol"; //UniswapV3
import "./pancakeswap/IV3PancakeSwapRouter.sol"; //PancakeSwapV3
import "./camelot/v3/IV3CamelotSwapRouter.sol"; //CamelotV3
import "./camelot/v2/IV2CamelotSwapRouter.sol"; //CamelotV2
import "./sushiswap/IV2SushiswapRouter.sol"; //SushiswapV2

import "./chainlink/PriceAggregator.sol"; 

contract OptimusPrime {

error NotTheOwner(address sender); 

error NotTheTradeExecutor(address sender); 

error NoProfit(uint256 finalBalance); 

event Profit(uint256 _finalBalance); 

address private immutable owner; 

address public tradeExecutor; 

IERC20 public constant weth = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); 

IV3UniswapSwapRouter public immutable uniswapRouterV3; 

IV3PancakeSwapRouter public immutable pancakeRouterV3; 

IV3CamelotSwapRouter public immutable camelotRouterV3; 

IV2CamelotSwapRouter public immutable camelotRouterV2; 

IV2SushiswapSwapRouter public immutable sushiswapRouterV2; 

mapping(address => mapping(address => uint256)) private numberOfTokensApproved; 

constructor(address _uniswapRouterV3, address _pancakeswapRouterV3, address _camelotRouterV3, address _camelotRouterV2, address _sushiswapRouterV2) {
uniswapRouterV3 = IV3UniswapSwapRouter(_uniswapRouterV3);
pancakeRouterV3 = IV3PancakeSwapRouter(_pancakeswapRouterV3); 
camelotRouterV3 = IV3CamelotSwapRouter(_camelotRouterV3); 
camelotRouterV2 = IV2CamelotSwapRouter(_camelotRouterV2); 
sushiswapRouterV2 = IV2SushiswapSwapRouter(_sushiswapRouterV2); 
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
function depositWETH(uint256 amount) public OnlyOwner(){
require(amount > 0, "Amount can't be 0"); 
IERC20(weth).transferFrom(msg.sender, address(this), amount);
}

//WITHDRAW
function withdrawWETH(uint256 amount) public OnlyOwner(){
require(amount <= returnWETHbalance(), "Amount is higher than balance"); 
IERC20(weth).transfer(msg.sender, amount);
}



//BUY A TOKEN FROM PancakeswapV3 AND SELL TO OTHERS DEXES
function buyWithWETHFromPancakeV3AndSellToUniswapV3(IV3PancakeSwapRouter.ExactInputParams memory pancakeParams, address tokenToBuy, uint24 uniswapPoolFee, uint256 estimatedGas) public OnlyTradeExecutor(){
uint256 initialBalance = IERC20(weth).balanceOf(address(this));

buyTokenWithWETH_pancakeswapV3(pancakeParams);

IV3UniswapSwapRouter.ExactInputParams memory uniswapParams = IV3UniswapSwapRouter.ExactInputParams({
path: abi.encodePacked(tokenToBuy, uniswapPoolFee , weth), 
recipient: address(this), 
amountIn: IERC20(tokenToBuy).balanceOf(address(this)), 
amountOutMinimum: 0
}); 
sellTokenForWETH_uniswapV3(uniswapParams);

uint256 finalBalance = IERC20(weth).balanceOf(address(this)); 
if(finalBalance < (initialBalance + estimatedGas)){
 revert NoProfit(finalBalance); 
}else{
  emit Profit(finalBalance);
}
}


//BUY A TOKEN FROM UniswapV3 AND SELL TO OTHERS DEXES
function buyWithWETHFromUniswapV3AndSellToPancakeV3(IV3UniswapSwapRouter.ExactInputParams memory uniswapParams, address tokenToBuy, uint24 pancakePoolFee, uint256 estimatedGas) public OnlyTradeExecutor(){
uint256 initialBalance = IERC20(weth).balanceOf(address(this));

buyTokenWithWETH_uniswapV3(uniswapParams);
IV3PancakeSwapRouter.ExactInputParams memory pancakeParams = IV3PancakeSwapRouter.ExactInputParams({
path: abi.encodePacked(tokenToBuy, pancakePoolFee, weth), 
recipient: address(this), 
deadline: block.timestamp,
amountIn: IERC20(tokenToBuy).balanceOf(address(this)), 
amountOutMinimum: 0
}); 
sellTokenForWETH_pancakeswapV3(pancakeParams);

uint256 finalBalance = IERC20(weth).balanceOf(address(this)); 
if(finalBalance < (initialBalance + estimatedGas)){
 revert NoProfit(finalBalance); 
}else{
 emit Profit(finalBalance);
}
}

function buyWithWETHFromUniswapV3AndSellToSushiswapV2(IV3UniswapSwapRouter.ExactInputParams memory uniswapParams, address tokenToBuy, uint256 estimatedGas) public OnlyTradeExecutor() {
uint256 initialBalance = IERC20(weth).balanceOf(address(this));

buyTokenWithWETH_uniswapV3(uniswapParams);
address[] memory sushiswapPath = new address[](2); 
sushiswapPath[0] = tokenToBuy; 
sushiswapPath[1] = address(weth);
sellTokenForWETH_sushiswapV2(IERC20(tokenToBuy).balanceOf(address(this)), 0, sushiswapPath, address(this), block.timestamp);

uint256 finalBalance = IERC20(weth).balanceOf(address(this)); 
if(finalBalance < (initialBalance + estimatedGas)){
 revert NoProfit(finalBalance); 
}else{
 emit Profit(finalBalance);
}
}

function buyWithWETHFromUniswapV3AndSellToCamelotV3(IV3UniswapSwapRouter.ExactInputParams memory uniswapParams, address tokenToBuy, uint256 estimatedGas) public OnlyTradeExecutor() {
uint256 initialBalance = IERC20(weth).balanceOf(address(this));

buyTokenWithWETH_uniswapV3(uniswapParams);
IV3CamelotSwapRouter.ExactInputParams memory camelotParams = IV3CamelotSwapRouter.ExactInputParams({
path: abi.encodePacked(tokenToBuy, weth), 
recipient: address(this), 
deadline: block.timestamp,
amountIn: IERC20(tokenToBuy).balanceOf(address(this)), 
amountOutMinimum: 0
}); 
sellTokenForWETH_camelotV3(camelotParams);

uint256 finalBalance = IERC20(weth).balanceOf(address(this)); 
if(finalBalance < (initialBalance + estimatedGas)){
 revert NoProfit(finalBalance); 
}else{
 emit Profit(finalBalance);
}
}


//BUY A TOKEN FROM SushiswapV2 AND SELL TO OTHERS DEXES
function buyWithWETHFromSushiswapV2AndSellToUniswapV3(uint256 amountIn, address tokenToBuy, uint24 uniswapPoolFee, uint256 estimatedGas) public OnlyTradeExecutor(){
uint256 initialBalance = IERC20(weth).balanceOf(address(this));

address[] memory sushiswapPath = new address[](2); 
sushiswapPath[0] = address(weth); 
sushiswapPath[1] = tokenToBuy;
buyTokenWithWETH_sushiswapV2(amountIn, 0, sushiswapPath, address(this), block.timestamp);
IV3UniswapSwapRouter.ExactInputParams memory uniswapParams = IV3UniswapSwapRouter.ExactInputParams({
path: abi.encodePacked(tokenToBuy, uniswapPoolFee , weth), 
recipient: address(this), 
amountIn: IERC20(tokenToBuy).balanceOf(address(this)), 
amountOutMinimum: 0
}); 
sellTokenForWETH_uniswapV3(uniswapParams);

uint256 finalBalance = IERC20(weth).balanceOf(address(this)); 
if(finalBalance < (initialBalance + estimatedGas)){
 revert NoProfit(finalBalance); 
}else{
 emit Profit(finalBalance);
}
}


//BUY A TOKEN FROM CamelotV3 AND SELL TO OTHERS DEXES
function buyWithWETHFromCamelotV3AndSellToUniswapV3(IV3CamelotSwapRouter.ExactInputParams memory camelotParams, address tokenToBuy, uint24 uniswapPoolFee, uint256 estimatedGas) public  OnlyTradeExecutor() {
uint256 initialBalance = IERC20(weth).balanceOf(address(this));

buyTokenWithWETH_camelotV3(camelotParams);
IV3UniswapSwapRouter.ExactInputParams memory uniswapParams = IV3UniswapSwapRouter.ExactInputParams({
path: abi.encodePacked(tokenToBuy, uniswapPoolFee , weth), 
recipient: address(this), 
amountIn: IERC20(tokenToBuy).balanceOf(address(this)), 
amountOutMinimum: 0
}); 
sellTokenForWETH_uniswapV3(uniswapParams);

uint256 finalBalance = IERC20(weth).balanceOf(address(this)); 
if(finalBalance < (initialBalance + estimatedGas)){
 revert NoProfit(finalBalance); 
}else{
 emit Profit(finalBalance);
}
}




//BUY / SELL TOKENS --> UniswapV3
function buyTokenWithWETH_uniswapV3(IV3UniswapSwapRouter.ExactInputParams memory params) internal {
IV3UniswapSwapRouter(uniswapRouterV3).exactInput(params);
}

function sellTokenForWETH_uniswapV3(IV3UniswapSwapRouter.ExactInputParams memory params) internal {
IV3UniswapSwapRouter(uniswapRouterV3).exactInput(params);
}


//BUY / SELL TOKENS --> PancakeswapV3
function buyTokenWithWETH_pancakeswapV3(IV3PancakeSwapRouter.ExactInputParams memory params) internal {
IV3PancakeSwapRouter(pancakeRouterV3).exactInput(params);
}

function sellTokenForWETH_pancakeswapV3(IV3PancakeSwapRouter.ExactInputParams memory params) internal {
IV3PancakeSwapRouter(pancakeRouterV3).exactInput(params);
}


//BUY / SELL TOKENS --> SushiswapV2
function buyTokenWithWETH_sushiswapV2(uint256 amountIn, uint256 amountOutMin, address[] memory path, address to, uint256 deadline) internal {
IV2SushiswapSwapRouter(sushiswapRouterV2).swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
}

function sellTokenForWETH_sushiswapV2(uint256 amountIn, uint256 amountOutMin, address[] memory path, address to, uint256 deadline) internal {
IV2SushiswapSwapRouter(sushiswapRouterV2).swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
}


//BUY / SELL TOKENS --> CamelotV2
function buyTokenWithWETH_camelotV2(uint256 amountIn, uint256 amountOutMin, address[] memory path, address to, address referrer, uint256 deadline) internal {
IV2CamelotSwapRouter(camelotRouterV2).swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, referrer, deadline);
}

function sellTokenForWETH_camelotV2(uint256 amountIn, uint256 amountOutMin, address[] memory path, address to, address referrer, uint256 deadline) internal {
IV2CamelotSwapRouter(camelotRouterV2).swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, referrer, deadline);
}


//BUY / SELL TOKENS --> CamelotV3
function buyTokenWithWETH_camelotV3(IV3CamelotSwapRouter.ExactInputParams memory params) internal {
IV3CamelotSwapRouter(camelotRouterV3).exactInput(params);
}

function sellTokenForWETH_camelotV3(IV3CamelotSwapRouter.ExactInputParams memory params) internal {
IV3CamelotSwapRouter(camelotRouterV3).exactInput(params);
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

function returnOwner() public view returns(address) {
return owner; 
}

function returnTokenApproved(address token, address spender)public view returns(uint256){
return numberOfTokensApproved[token][spender]; 
}

function returnWETHbalance() public view returns(uint256) {
return IERC20(weth).balanceOf(address(this));
}

function returnPathData(address tokenA, uint24 poolFee, address tokenB) public pure returns (bytes memory){
return abi.encodePacked(tokenA, poolFee, tokenB);
}

} 