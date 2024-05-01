EXPLANATION

OptimusPrime Bot is divided by two parts: The hardhat server and the smart contract.

The main purpose is to build an automated bot that is able to trade 24/7.

The step are the following:

The owner send a stablecoin to the contract with the 'depositToken' function.

The server must constantly watch for differents pairs on the ARB network (like WETH/USDT or WETH/SHIB) and when there is a good moment to trade, the server will call the 'trade' function in the OptimusPrime smart contract.

The smart contract will buy from a dex x and sell in the same dex (in the same tx using flash loans). 

OptimusPrime contract will lend money to the sender only if the balance after buying and selling that token is >= than the balance borrowed.

The owner of the contract will be able to withdraw the Token in the contract with the 'withdrawToken' function and when he wants.

NOTE: The smart contracts will contains the fund necessary (stable coins) to trade the token and it will lend them to the sender, so the owner must send money (stable coins) to the smart contract in order to use them to trade.

If all the steps work and the smart contract is well structured, there won't be losses, expect those for gas (in the arb they're really cheap) and the quicknode arb url (depending on the plan).

Stablecoin used = USDT / USDC


-----------------------------------------------------------------------------------------------------------------

BEST SWAPS RECORD UNTIL NOW:

USDC --> WETH --> USDT --> + 0,2 % (pancake pools fees = 100) calling "trade1"

USDC --> WETH --> USDT --> USDC --> + 0,065 % (pancake pools fees = 100) calling "trade3"




