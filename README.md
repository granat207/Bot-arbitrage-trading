EXPLANATION

OptimusPrime Bot is divided by two parts: The hardhat server and the smart contract.

The main purpose is to build an automated bot that is able to trade 24/7.

The step are the following:

The owner send WETH to the contract with the 'depositWETH' function.

The server must constantly watch for differents pairs on the ARB network (like WETH/USDT or WETH/SHIB) and when there is a good moment to trade, the server will call the 'trade' function in the OptimusPrime smart contract.

The smart contract will buy (from a dex A) and sell (to a sell B) in the same tx (using flash loans) the token desidered, but OptimusPrime contract will lend money to the sender only if the balance after buying and selling that token is >= than the balance borrowed + the amount of fees.

The owner of the contract will be able to withdraw the WETH in the contract with the 'withdraw' function and when he wants.

NOTE: The smart contracts will contains the fund necessary (WETH) to trade the token and it will lend them to the sender, so the owner must send money (WETH) to the smart contract in order to use them to trade.

If all the steps work and the smart contract is well structured, there won't be losses, expect those for gas (in the arb they're really cheap) and the quicknode arb url (depending on the plan).


-----------------------------------------------------------------------------------------------------------------

BEST SWAPS RECORD UNTIL NOW:

WETH / USDC --> uniswapV3, pancakeV3 --> - 0,032 % (pancake pool fee = 100, uniswap pool fee = 500)

WETH / WBTC --> uniswapV3, camelotV3 --> - 0,048 % (uniswap pool fee = 500, camelot pool fee = 0,0612 %)

WETH / WBTC --> uniswapV3, pancakeV3 --> 0,076 % (pancake pool fee = 500, uniswap pool fe = 500)

WETH / ARB --> pancakeV3, uniswapV3 --> - 0,086 % (pancake pool fee = 500, uniswap pool fee = 500)

WETH / ARB --> camelotV3, uniswapV3 --> - 0,09 % (uniswap pool fee = 500, camelot pool fee = 0,0857 %)

WETH / USDT --> pancakeV3, uniswapV3 --> - 0,235 % (pancake pool fee = 100, uniswap pool fee = 100)

WETH / WBTC --> uniswapV3, sushiswapV2 --> - 0,396 % (uniswap pool fee = 500)

WETH / USDT --> sushiswapV2, uniswapV3 --> - 0,532 % (uniswap pool fee = 100)

WETH / ARB --> sushiswapV2, uniswapV3 --> -0,644 % (uniswap pool fee = 500)

WETH / LINK --> sushiswapV2, uniswapV3 --> -1,379 % (uniswap pool fee = 3000)

WETH / PENDLE --> sushiswapV2, uniswapV3 --> really bad (uniswap pool fee = 3000)
