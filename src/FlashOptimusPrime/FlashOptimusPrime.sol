//SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.19; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../protocols/interfaces/pancakeswap/IV3PancakeSwapRouter.sol"; 

import "../protocols/interfaces/uniswap/IV3UniswapSwapRouter.sol"; 

import "../protocols/interfaces/uniswap/IUniswapV3Pool.sol"; 

import "../protocols/interfaces/uniswap/IUniswapV3FlashCallback.sol"; 

/// @title FlashOptimusPrime
/// @notice A contract that performs flash loans on Uniswap V3 pools and executes arbitrage between Uniswap V3 and PancakeSwap V3.
/// @dev Implements the IUniswapV3FlashCallback interface to handle flash loan callbacks.
contract FlashOptimusPrime is IUniswapV3FlashCallback {

/// @notice Reverts when a non-owner tries to call restricted functions.
/// @param sender The address of the unauthorized caller.
error NotTheOwner(address sender); 

/// @notice Reverts when a non-borrowed pool calls the flash loan callback.
/// @param sender The address of the unauthorized caller.
error NotTheFlashLoanPool(address sender); 

/// @notice Reverts if both token0 and token1 are borrowed simultaneously (only one token allowed).
/// @param token0AmounBorrowed Amount of token0 attempted to borrow.
/// @param token1AmountBorrowed Amount of token1 attempted to borrow.
error CanFlashLoanOnlyOneToken(uint256 token0AmounBorrowed, uint256 token1AmountBorrowed); 

/// @notice Reverts when the flash loan callback is triggered but no active flash loan is ongoing.
error NotFlashLoaning();

/// @notice Reverts if no profit was made after executing arbitrage.
/// @param amountBorrowed The borrowed token amount.
/// @param finalBalance The ending balance after trades.
error NoProfit(uint256 amountBorrowed, uint256 finalBalance); 

/// @notice Emitted when a profitable arbitrage is completed.
/// @param amountBorrowed The borrowed token amount.
/// @param finalBalance The ending balance after trades.
event Profit(uint256 amountBorrowed, uint256 finalBalance); 

address public immutable pancakeRouterV3; 

address public immutable uniswapRouterV3; 

address public immutable owner; 

enum CodePath {
	UniswapV3AndPancakeV3, 
	PancakeV3AndUniswapV3
} 

bool public isFlashLoaning; 

CodePath public codePath; 

address public tokenBorrowed; 

address public tokenToTrade; 

address public borrowedByPool; 

uint256 public amountBorrowed; 

address[] public path; 

uint24[] public poolFees; 

bool public isFeeZero; 

uint256 public initialBalance; 


/// @notice Sets immutable router addresses and assigns the contract owner.
/// @param _pancakeRouterV3 Address of PancakeSwap V3 router.
/// @param _uniswapRouterV3 Address of Uniswap V3 router.
constructor(address _pancakeRouterV3, address _uniswapRouterV3) {
pancakeRouterV3 = _pancakeRouterV3; 
uniswapRouterV3 = _uniswapRouterV3; 
owner = msg.sender; 
}


/// @notice Restricts function access to only the contract owner.
modifier OnlyOwner() {
    if(msg.sender != owner) {
        revert NotTheOwner(msg.sender); 
    }
    _; 
}


/// @notice Restricts function access to only the pool that initiated the flash loan.
modifier OnlyFlashLoanPool() {
	if(msg.sender != borrowedByPool) {
		revert NotTheFlashLoanPool(msg.sender); 
	}
    if(!isFlashLoaning) {
        revert NotFlashLoaning(); 
    }
	_;
}


/// @notice Allows the owner to withdraw ERC20 tokens from the contract.
/// @param token The address of the ERC20 token.
/// @param amount The amount of tokens to withdraw.
function withdraw(address token, uint256 amount) public OnlyOwner {
	IERC20(token).transfer(msg.sender, amount);
}


/// @notice Initializes a flash loan and sets the arbitrage parameters.
/// @dev Ensures only one token can be borrowed at a time.
/// @param _codePath The arbitrage strategy to execute (Uniswap-->Pancake or Pancake-->Uniswap).
/// @param _poolBorrowed The address of the Uniswap V3 pool to borrow from.
/// @param _tokenBorrowed The token being borrowed.
/// @param _tokenToTrade The token to trade against.
/// @param _token0AmounBorrowed The amount of token0 to borrow.
/// @param _token1AmountBorrowed The amount of token1 to borrow.
/// @param _path The swap path for trades.
/// @param _poolFees The fee tiers for each swap.
function initFlash(CodePath _codePath, address _poolBorrowed, address _tokenBorrowed, address _tokenToTrade, uint256 _token0AmounBorrowed, uint256 _token1AmountBorrowed, address[] memory _path, uint24[] memory _poolFees) public OnlyOwner(){
    isFlashLoaning = true; 

    if(_token0AmounBorrowed > 0 && _token1AmountBorrowed > 0) {
	    revert CanFlashLoanOnlyOneToken(_token0AmounBorrowed, _token1AmountBorrowed); 
    }

    codePath = _codePath; 
    tokenBorrowed = _tokenBorrowed;
    tokenToTrade = _tokenToTrade; 
    borrowedByPool = _poolBorrowed; 
    path = _path; 
    poolFees = _poolFees; 

    if(_token0AmounBorrowed > 0){
        amountBorrowed = _token0AmounBorrowed; 
        isFeeZero = true; 
    } else {
        amountBorrowed = _token1AmountBorrowed; 
        isFeeZero = false; 
    }

    initialBalance = IERC20(_tokenBorrowed).balanceOf(address(this)); 

    IUniswapV3Pool(_poolBorrowed).flash(address(this), _token0AmounBorrowed, _token1AmountBorrowed, "");
}


/// @notice Callback function triggered by Uniswap V3 pool after a flash loan is executed.
/// @dev Must repay borrowed tokens plus fees and performs arbitrage depending on the chosen strategy.
/// @param fee0 The fee amount for token0.
/// @param fee1 The fee amount for token1.
/// @param data Arbitrary callback data.
function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes memory data) external override OnlyFlashLoanPool() {
    isFlashLoaning = false; 

    if(codePath == CodePath.UniswapV3AndPancakeV3){
        tradeOnUniswapV3AndPancakeV3(); 
    }

    if(codePath == CodePath.PancakeV3AndUniswapV3){
        tradeOnPancakeV3AndUniswapV3(); 
    }

    uint256 finalBalance = IERC20(tokenBorrowed).balanceOf(address(this)); 

    if(isFeeZero) {
	    if(finalBalance < amountBorrowed + initialBalance + fee0){
 		    revert NoProfit(amountBorrowed, finalBalance); 
	    } else {
		    emit Profit(amountBorrowed, finalBalance); 
		    IERC20(tokenBorrowed).transfer(borrowedByPool, amountBorrowed + fee0);
	    }
    } else {
	    if(finalBalance < amountBorrowed + initialBalance + fee1){
		    revert NoProfit(amountBorrowed, finalBalance); 
	    } else {
		    emit Profit(amountBorrowed, finalBalance);
		    IERC20(tokenBorrowed).transfer(borrowedByPool, amountBorrowed + fee1);
	    }
    }
}


/// @notice Executes arbitrage by swapping borrowed tokens on Uniswap V3 first, then PancakeSwap V3.
function tradeOnUniswapV3AndPancakeV3() internal {  
    IV3UniswapSwapRouter.ExactInputParams memory uniswapParams = IV3UniswapSwapRouter.ExactInputParams({
    path: abi.encodePacked(tokenBorrowed, poolFees[0], tokenToTrade),
    recipient: address(this),  
    amountIn: amountBorrowed, 
    amountOutMinimum: 0
    }); 
    uint256 amountOutUniswap = IV3UniswapSwapRouter(uniswapRouterV3).exactInput(uniswapParams);

    IV3PancakeSwapRouter.ExactInputParams memory pancakeParams = IV3PancakeSwapRouter.ExactInputParams({
    path: abi.encodePacked(tokenToTrade, poolFees[1], tokenBorrowed),
    recipient: address(this), 
    deadline: block.timestamp, 
    amountIn: amountOutUniswap, 
    amountOutMinimum: 0
    }); 
    IV3PancakeSwapRouter(pancakeRouterV3).exactInput(pancakeParams);
}


/// @notice Executes arbitrage by swapping borrowed tokens on PancakeSwap V3 first, then Uniswap V3.
function tradeOnPancakeV3AndUniswapV3() internal {  
    IV3PancakeSwapRouter.ExactInputParams memory pancakeParams = IV3PancakeSwapRouter.ExactInputParams({
    path: abi.encodePacked(tokenBorrowed, poolFees[0], tokenToTrade),
    recipient: address(this), 
    deadline: block.timestamp, 
    amountIn: amountBorrowed, 
    amountOutMinimum: 0
    }); 
    uint256 amountOutPancake = IV3PancakeSwapRouter(pancakeRouterV3).exactInput(pancakeParams);

    IV3UniswapSwapRouter.ExactInputParams memory uniswapParams = IV3UniswapSwapRouter.ExactInputParams({
    path: abi.encodePacked(tokenToTrade, poolFees[1], tokenBorrowed),
    recipient: address(this), 
    amountIn: amountOutPancake, 
    amountOutMinimum: 0
    }); 
    IV3UniswapSwapRouter(uniswapRouterV3).exactInput(uniswapParams);
}


/// @notice Approves a spender to use a specified amount of an ERC20 token.
/// @param token The address of the ERC20 token.
/// @param spender The address that will spend the tokens.
/// @param value The amount of tokens to approve.
function approveToken(address token, address spender, uint256 value) public OnlyOwner(){
    IERC20(token).approve(spender, value);
}
}