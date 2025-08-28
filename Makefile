build: 
	sudo forge build

op-test-basic: 
	sudo forge test --match-path test/OptimusPrime/OptimusPrimeBasic.t.sol -vvv --fork-url $(ARBITRUM_RPC_URL)

op-test-SwapStables: 
	sudo forge test --match-path test/OptimusPrime/OptimusPrimeSwapStables.t.sol -vvv --fork-url $(ARBITRUM_RPC_URL)

op-test-trading: 
	sudo forge test --match-path test/OptimusPrime/OptimusPrimeTrading.t.sol -vvv --fork-url $(ARBITRUM_RPC_URL)

op-test: 
	sudo forge test --match-path test/OptimusPrime/OptimusPrimeBasic.t.sol -vvv --fork-url $(ARBITRUM_RPC_URL) 
	sudo forge test --match-path test/OptimusPrime/OptimusPrimeSwapStables.t.sol -vvv --fork-url $(ARBITRUM_RPC_URL)
	sudo forge test --match-path test/OptimusPrime/OptimusPrimeTrading.t.sol -vvv --fork-url $(ARBITRUM_RPC_URL)


fop-test-basic: 
	sudo forge test --match-path test/FlashOptimusPrime/FlashOptimusPrimeBasic.t.sol -vvv --fork-url $(ARBITRUM_RPC_URL)

fop-test-trading: 
	sudo forge test --match-path test/FlashOptimusPrime/FlashOptimusPrimeTrading.t.sol -vvv --fork-url $(ARBITRUM_RPC_URL)

fop-test: 
	sudo forge test --match-path test/FlashOptimusPrime/FlashOptimusPrimeBasic.t.sol -vvv --fork-url $(ARBITRUM_RPC_URL)
	sudo forge test --match-path test/FlashOptimusPrime/FlashOptimusPrimeTrading.t.sol -vvv --fork-url $(ARBITRUM_RPC_URL)


fop-op-test: 
	sudo forge test --match-path test/OptimusPrime/OptimusPrimeBasic.t.sol -vvv --fork-url $(ARBITRUM_RPC_URL) 
	sudo forge test --match-path test/OptimusPrime/OptimusPrimeSwapStables.t.sol -vvv --fork-url $(ARBITRUM_RPC_URL)
	sudo forge test --match-path test/OptimusPrime/OptimusPrimeTrading.t.sol -vvv --fork-url $(ARBITRUM_RPC_URL)
	sudo forge test --match-path test/FlashOptimusPrime/FlashOptimusPrimeBasic.t.sol -vvv --fork-url $(ARBITRUM_RPC_URL)
	sudo forge test --match-path test/FlashOptimusPrime/FlashOptimusPrimeTrading.t.sol -vvv --fork-url $(ARBITRUM_RPC_URL)


coverage: 
	sudo forge coverage --fork-url $(ARBITRUM_RPC_URL)