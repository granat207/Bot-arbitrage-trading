//SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.19; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../protocols/interfaces/pancakeswap/IV3PancakeSwapRouter.sol"; 

import "../protocols/interfaces/uniswap/IV3UniswapSwapRouter.sol"; 

import "../protocols/interfaces/pancakeswap/IPancakeV3Pool.sol"; 

/// @title OptimusPrime - Arbitrage executor between PancakeV3 and UniswapV3
/// @notice Executes atomic arbitrage / swap sequences between configured V3 routers (PancakeV3 and UniswapV3).
/// @dev
/// - This contract holds stable and wrapped tokens and executes multi-hop swaps via the provided router interfaces.
/// - All functions that perform swaps expect the contract to hold the `amountIn` tokens.
/// - Profit is checked by comparing token balance before/after the swap sequence to avoid leg risk.
/// - Caller roles:
///   - `owner` can deposit/withdraw tokens, set the `tradeExecutor`, and perform stable swaps.
///   - `tradeExecutor` is allowed to run arbitrage trades.

contract OptimusPrime {

/// -----------------------------------------------------------------------
/// Errors
/// -----------------------------------------------------------------------

/// @notice Reverted when a non-owner calls an owner-only function.
/// @param sender The address that attempted the call.
error NotTheOwner(address sender); 

/// @notice Reverted when a caller that's not the configured trade executor attempts to run trades.
/// @param sender The address that attempted the call.
error NotTheTradeExecutor(address sender); 

/// @notice Reverted when an unsupported token is provided for deposit or other owner-only ops.
/// @param token The token address that is not accepted.
error TokenNotAccepted(address token); 

/// @notice Reverted when a trade sequence produced no profit.
/// @param amountIn Input amount used for trade.
/// @param amountOut The output amount achieved by the swap sequence.
error NoProfit(uint256 amountIn, uint256 amountOut); 

/// -----------------------------------------------------------------------
/// Events
/// -----------------------------------------------------------------------

/// @notice Emitted when a profitable arbitrage/trade cycle is completed.
/// @param finalBalance The profit amount denominated in the initial token (difference final - initial).
event Profit(uint256 finalBalance); 

address private immutable owner; 

address public tradeExecutor; 

IERC20 public immutable USDT; 

IERC20 public immutable USDC; 

IV3PancakeSwapRouter public immutable pancakeRouterV3; 

IV3UniswapSwapRouter public immutable uniswapRouterV3; 


/// -----------------------------------------------------------------------
/// Constructor
/// -----------------------------------------------------------------------

/// @notice Constructs the OptimusPrime contract.
/// @dev Provide correct router addresses for the target chain. `owner` is set to `msg.sender`.
/// @param _pancakeswapRouterV3 Address of the Pancake V3 router contract.
/// @param _uniswapRouterV3 Address of the Uniswap V3 router contract.
constructor(address _pancakeswapRouterV3, address _uniswapRouterV3, address _USDT, address _USDC) {
pancakeRouterV3 = IV3PancakeSwapRouter(_pancakeswapRouterV3); 
uniswapRouterV3 = IV3UniswapSwapRouter(_uniswapRouterV3);
USDT = IERC20(_USDT); 
USDC = IERC20(_USDC); 
owner = msg.sender; 
}


/// -----------------------------------------------------------------------
/// Modifiers
/// -----------------------------------------------------------------------

/// @notice Restricts function to only be callable by the `owner`.
/// @dev Reverts with `NotTheOwner` when caller is not `owner`.
modifier OnlyOwner() {
    if(msg.sender != owner){
      revert NotTheOwner(msg.sender); 
    }
_; 
}


/// @notice Restricts function to only be callable by the configured `tradeExecutor`.
/// @dev Reverts with `NotTheTradeExecutor` when caller is not `tradeExecutor`.
modifier OnlyTradeExecutor() {
    if(msg.sender != tradeExecutor){
      revert NotTheTradeExecutor(msg.sender); 
    }
_; 
}


/// -----------------------------------------------------------------------
/// Owner-only: deposit / withdraw 
/// -----------------------------------------------------------------------

// @notice Deposit stable tokens (USDT or USDC) into the contract.
/// @dev Caller (owner) must `approve` this contract for `amount` before calling.
/// @param token Address of the token to deposit (must be USDT or USDC).
/// @param amount Amount of tokens to transfer from owner to this contract.
function depositToken(address token, uint256 amount) public OnlyOwner(){
    if(token != address(USDT) && token != address(USDC)){
      revert TokenNotAccepted(token); 
    }
    require(amount > 0, "Amount can't be 0"); 
    IERC20(token).transferFrom(msg.sender, address(this), amount);
}


/// @notice Withdraw ERC20 tokens from the contract to the owner.
/// @dev Only callable by owner.
/// @param token Address of the token to withdraw.
/// @param amount Amount to transfer to the owner.
function withdrawToken(address token, uint256 amount) public OnlyOwner(){
    IERC20(token).transfer(msg.sender, amount);
}


/// -----------------------------------------------------------------------
/// Trade functions (OnlyTradeExecutor)
/// -----------------------------------------------------------------------

/// @notice Execute an exact-input multi-hop trade on Pancake V3 and return to the contract.
/// @dev
/// - `path` is constructed as `initialToken -> tokenToTrade -> initialToken` using provided fees.
/// - Caller must ensure this contract holds `amountIn` of `initialToken` before calling.
/// - Uses `amountOutMinimum = 0`; caller accepts the slippage risk. Consider passing a minimum or validating off-chain.
/// - Emits `Profit` if final balance > initial balance; otherwise reverts with `NoProfit`.
/// @param initialToken The token that will be spent and that profit is measured against.
/// @param tokenToTrade The intermediate token used in the arbitrage.
/// @param amountIn Amount of `initialToken` to spend.
/// @param feeX Fee tier to use for first hop (packed into path).
/// @param feeY Fee tier to use for second hop (packed into path).
function tradeOnPancakeV3(address initialToken, address tokenToTrade, uint256 amountIn, uint24 feeX, uint24 feeY) public OnlyTradeExecutor {
    uint256 initialTokenBalance = IERC20(initialToken).balanceOf(address(this));

    IV3PancakeSwapRouter.ExactInputParams memory params = IV3PancakeSwapRouter.ExactInputParams({
    path: abi.encodePacked(initialToken, feeX, tokenToTrade, feeY, initialToken),
    recipient: address(this), 
    deadline: block.timestamp, 
    amountIn: amountIn, 
    amountOutMinimum: 0
    }); 
    uint256 amountOut = IV3PancakeSwapRouter(pancakeRouterV3).exactInput(params);

    uint256 finalTokenBalance = IERC20(initialToken).balanceOf(address(this));
    if(finalTokenBalance > initialTokenBalance){
      emit Profit(finalTokenBalance - initialTokenBalance);
    } else {
      revert NoProfit(amountIn, amountOut); 
    }
}


/// @notice Execute an exact-input multi-hop trade on Uniswap V3 and return to the contract.
/// @dev See `tradeOnPancakeV3` notes — this uses the Uniswap router instead.
/// @param initialToken The token that will be spent and that profit is measured against.
/// @param tokenToTrade The intermediate token used in the arbitrage.
/// @param amountIn Amount of `initialToken` to spend.
/// @param feeX Fee tier to use for first hop (packed into path).
/// @param feeY Fee tier to use for second hop (packed into path).
function tradeOnUniswapV3(address initialToken, address tokenToTrade, uint256 amountIn, uint24 feeX, uint24 feeY) public OnlyTradeExecutor(){
    uint256 initialTokenBalance = IERC20(initialToken).balanceOf(address(this));

    IV3UniswapSwapRouter.ExactInputParams memory params = IV3UniswapSwapRouter.ExactInputParams({
    path: abi.encodePacked(initialToken, feeX, tokenToTrade, feeY, initialToken),
    recipient: address(this),  
    amountIn: amountIn, 
    amountOutMinimum: 0
    }); 
    uint256 amountOut = IV3UniswapSwapRouter(uniswapRouterV3).exactInput(params);

    uint256 finalTokenBalance = IERC20(initialToken).balanceOf(address(this));
   if(finalTokenBalance > initialTokenBalance){
      emit Profit(finalTokenBalance - initialTokenBalance);
    } else {
      revert NoProfit(amountIn, amountOut); 
    }
}


/// @notice Execute a two-step arbitrage: UniswapV3 then PancakeV3, returning final tokens to this contract.
/// @dev `amountOutUniswap` from the first router is used as `amountIn` for the second router.
/// - Emits `Profit` or reverts with `NoProfit`.
/// @param initialToken Token to start and end with (profit measured in this token).
/// @param tokenToTrade Intermediate token used in the cross-router swap.
/// @param amountIn Amount of `initialToken` to spend initially.
/// @param feeX Fee tier for Uniswap first hop.
/// @param feeY Fee tier for Pancake second hop.
function tradeOnUniswapV3AndPancakeV3(address initialToken, address tokenToTrade, uint256 amountIn, uint24 feeX, uint24 feeY) public OnlyTradeExecutor(){
    uint256 initialTokenBalance = IERC20(initialToken).balanceOf(address(this));    

    IV3UniswapSwapRouter.ExactInputParams memory uniswapParams = IV3UniswapSwapRouter.ExactInputParams({
    path: abi.encodePacked(initialToken, feeX, tokenToTrade),
    recipient: address(this),  
    amountIn: amountIn, 
    amountOutMinimum: 0
    }); 
    uint256 amountOutUniswap = IV3UniswapSwapRouter(uniswapRouterV3).exactInput(uniswapParams);

    IV3PancakeSwapRouter.ExactInputParams memory pancakeParams = IV3PancakeSwapRouter.ExactInputParams({
    path: abi.encodePacked(tokenToTrade, feeY, initialToken),
    recipient: address(this), 
    deadline: block.timestamp, 
    amountIn: amountOutUniswap, 
    amountOutMinimum: 0
    }); 
    uint256 amountOutPancake = IV3PancakeSwapRouter(pancakeRouterV3).exactInput(pancakeParams);

    uint256 finalTokenBalance = IERC20(initialToken).balanceOf(address(this));
    if(finalTokenBalance > initialTokenBalance) {
      emit Profit(finalTokenBalance - initialTokenBalance);
    } else {
      revert NoProfit(amountIn, amountOutPancake); 
    }
}


/// @notice Execute a two-step arbitrage: PancakeV3 then UniswapV3, returning final tokens to this contract.
/// @dev Same as the inverse order of `tradeOnUniswapV3AndPancakeV3`.
/// @param initialToken Token to start and end with (profit measured in this token).
/// @param tokenToTrade Intermediate token used in the cross-router swap.
/// @param amountIn Amount of `initialToken` to spend initially.
/// @param feeX Fee tier for Pancake first hop.
/// @param feeY Fee tier for Uniswap second hop.
function tradeOnPancakeV3AndUniswapV3(address initialToken, address tokenToTrade, uint256 amountIn, uint24 feeX, uint24 feeY) public OnlyTradeExecutor(){
    uint256 initialTokenBalance = IERC20(initialToken).balanceOf(address(this));    

    IV3PancakeSwapRouter.ExactInputParams memory pancakeParams = IV3PancakeSwapRouter.ExactInputParams({
    path: abi.encodePacked(initialToken, feeX, tokenToTrade),
    recipient: address(this), 
    deadline: block.timestamp, 
    amountIn: amountIn, 
    amountOutMinimum: 0
    }); 
    uint256 amountOutPancake = IV3PancakeSwapRouter(pancakeRouterV3).exactInput(pancakeParams);

    IV3UniswapSwapRouter.ExactInputParams memory uniswapParams = IV3UniswapSwapRouter.ExactInputParams({
    path: abi.encodePacked(tokenToTrade, feeY, initialToken),
    recipient: address(this), 
    amountIn: amountOutPancake, 
    amountOutMinimum: 0
    }); 
    uint256 amountOutUniswap = IV3UniswapSwapRouter(uniswapRouterV3).exactInput(uniswapParams);

    uint256 finalTokenBalance = IERC20(initialToken).balanceOf(address(this));
    if(finalTokenBalance > initialTokenBalance) {
     emit Profit(finalTokenBalance - initialTokenBalance);
    } else {
      revert NoProfit(amountIn, amountOutUniswap); 
    }
}


/// -----------------------------------------------------------------------
/// Owner-only stable swaps
/// -----------------------------------------------------------------------

/// @notice Swap between USDT and USDC (or vice-versa) with `amountOutMinimum` = 0 (no slippage protection).
/// @dev Only callable by owner. Uses UniswapV3 router interface for stable swap path.
/// @param initialToken Token to swap from (should be USDT or USDC).
/// @param finalToken Token to swap to (should be USDT or USDC).
/// @param amount Amount of `initialToken` to swap.
/// @param pancakePoolFee Fee tier used in the path encoding.
function swapStablesWithoutSlippage(address initialToken, address finalToken, uint256 amount, uint24 pancakePoolFee) public OnlyOwner(){
    IV3UniswapSwapRouter.ExactInputParams memory params = IV3UniswapSwapRouter.ExactInputParams({
    path: abi.encodePacked(initialToken, pancakePoolFee, finalToken),
    recipient: address(this), 
    amountIn: amount, 
    amountOutMinimum: 0
    }); 
    IV3UniswapSwapRouter(uniswapRouterV3).exactInput(params);
}


/// @notice Swap between USDT and USDC (or vice-versa) with a 0.5% minimum out.
/// @dev Only callable by owner. `amountOutMinimum` computed as 99.5% of `amount`.
/// @param initialToken Token to swap from (should be USDT or USDC).
/// @param finalToken Token to swap to (should be USDT or USDC).
/// @param amount Amount of `initialToken` to swap.
/// @param pancakePoolFee Fee tier used in the path encoding.
function swapStablesWithSlippage(address initialToken, address finalToken, uint256 amount, uint24 pancakePoolFee) public OnlyOwner(){
    IV3UniswapSwapRouter.ExactInputParams memory params = IV3UniswapSwapRouter.ExactInputParams({
    path: abi.encodePacked(initialToken, pancakePoolFee, finalToken),
    recipient: address(this), 
    amountIn: amount, 
    amountOutMinimum: (amount * 995) / 1000
    }); 
    IV3UniswapSwapRouter(uniswapRouterV3).exactInput(params);
}


/// -----------------------------------------------------------------------
/// Approvals / Admin setters
/// -----------------------------------------------------------------------

/// @notice Approve `spender` to spend `amount` of `tokenToApprove` from this contract.
/// @dev Only owner can call. Useful to set allowances for routers or vaults.
/// @param tokenToApprove ERC20 token address to approve.
/// @param spender Address to be approved.
/// @param amount Allowance amount to set.
function approveToken(address tokenToApprove, address spender, uint256 amount) public OnlyOwner(){
    IERC20(tokenToApprove).approve(spender, amount);
}


/// @notice Configure the address that is allowed to execute trades.
/// @dev Only owner can set. `_tradeExecutor` cannot be zero address or this contract.
/// @param _tradeExecutor Address of the trade executor.
function setTradeExecutor(address _tradeExecutor) public OnlyOwner(){
    require(_tradeExecutor != (address(0)), "Can't be a 0 address"); 
    require(_tradeExecutor != address(this), "Can't be this address");
    tradeExecutor = _tradeExecutor; 
}

} 