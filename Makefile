-include .env

# .PHONY tells Makefile to reserve the following keywords
.PHONY: install all update fmt clean build test snapshot

install:
	forge install Cyfrin/foundry-devops@0.2.5 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 --no-commit && forge install foundry-rs/forge-std@v1.9.5 --no-commit && forge install transmissions11/solmate@v6 --no-commit

# remove all dependencies and update to the latest commits
all:
	clean remove install update build

# Update dependencies to the latest commit
update:
	forge update

fmt:
	forge fmt

clean:
	forge clean && rm -rf cache/ broadcast/ out/

build:
	forge build

test:
	forge test

# Snapshot of gas usage
snapshot:
	forge snapshot

# Test on local blockchain (Anvil) first before testing on Testnet
deploy:
	@forge script script/DeployRaffle.s.sol --rpc-url http://localhost:8545 --account SimpleStorage --password-file anvil.password --broadcast -vvvv

# Deploy to Sepolia Testnet and verify - @forge will not print output
deploy-sepolia:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_RPC_URL) --account SepoliaTestnet --password-file sepolia.password --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

