# Optimus Prime Arbitrage Bots

This repository contains two smart contracts designed to execute **cross-DEX arbitrage strategies** between **Uniswap V3** and **PancakeSwap V3** on EVM chains (tested on Arbitrum).  

- **OptimusPrime** → arbitrage without flash loans (requires pre-funded tokens).  
- **FlashOptimusPrime** → arbitrage with Uniswap V3 flash loans (capital efficient).  

Both contracts implement role-restricted access (owner, trade executor), profit checks, and event emissions.  

---

## Contracts

### 🔹 OptimusPrime
- Arbitrage between Uniswap V3 and PancakeSwap V3 using **pre-deposited liquidity**.  
- Owner can:
  - Deposit/withdraw tokens (USDT, USDC).
  - Set `tradeExecutor`.
  - Swap stables with or without slippage protection.  
- Trade executor can:
  - Run arbitrage in either direction (Uniswap→Pancake or Pancake→Uniswap).  
- Emits `Profit` event when a profitable cycle is completed.

### 🔹 FlashOptimusPrime
- Extends OptimusPrime with **flash loan capability**.  
- Borrows liquidity from a Uniswap V3 pool and executes arbitrage between Uniswap V3 and PancakeSwap V3.  
- Implements `IUniswapV3FlashCallback` to handle loan repayment.  
- Safety checks:
  - Only one token can be borrowed per flash loan.  
  - Ensures repayment + fees + profit.  
- Emits `Profit` event on success.  

## Development

### Requirements
- [Foundry](https://book.getfoundry.sh/) (`forge`, `cast`)
- Node.js
- Use an Arbitrum RPC URL

### Workflow
```bash
git clone https://github.com/granat207/Bot-arbitrage-trading.git
cd Bot-arbitrage-trading
forge install

### Build
make build

### Test
make fop-op-test

### Coverage 
make coverage


