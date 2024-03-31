require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config(); 

const arbUrl = process.env.ARBITRUM_ENDPOINT; 

const privateKey = process.env.OWNER_PRIVATE_KEY; 

const arbiscan = process.env.ARBISCAN; 

const tradeExecutorPrivateKey = process.env.TRADE_EXECUTOR_PRIVATE_KEY; 

module.exports = {
  solidity: "0.8.20",

  networks: {
  arbMainnet: {
  url: arbUrl, 
  accounts: [privateKey]
  }
  }, 
  etherscan: {
  apiKey:{
  arbitrumOne: arbiscan
  }
  }
};
