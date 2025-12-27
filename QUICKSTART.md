# Tawf Governance System - Quick Start Guide

## Prerequisites

- Foundry installed (`curl -L https://foundry.paradigm.xyz | bash && foundryup`)
- Git
- A wallet with some testnet ETH

## Quick Setup

### 1. Build the Project

```bash
cd gov
forge build
```

### 2. Run Tests

```bash
forge test
```

### 3. Deploy Locally

```bash
# Terminal 1: Start local node
anvil

# Terminal 2: Deploy
forge script script/DeployTawfSystem.s.sol:DeployTawfSystem \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```

## Key Commands

### Building
```bash
forge build                 # Compile contracts
forge build --force         # Force recompile
forge clean                 # Clean build artifacts
```

### Testing
```bash
forge test                  # Run all tests
forge test -vvv            # Verbose output
forge test --match-test testName  # Run specific test
forge test --gas-report    # Show gas usage
```

### Deployment
```bash
# Local (Anvil)
forge script script/DeployTawfSystem.s.sol:DeployTawfSystem \
  --rpc-url http://localhost:8545 \
  --private-key <KEY> \
  --broadcast

# Testnet (e.g., Sepolia)
forge script script/DeployTawfSystem.s.sol:DeployTawfSystem \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

## Contract Interactions

### Using Cast (Foundry CLI)

#### Read Operations

```bash
# Check if address has DID
cast call <DID_CONTRACT> "hasDID(address)(bool)" <USER_ADDRESS>

# Get reputation
cast call <REPUTATION_CONTRACT> "getReputation(address)(uint256)" <USER_ADDRESS>

# Get campaign details
cast call <CAMPAIGN_MANAGER> "getCampaign(uint256)" <CAMPAIGN_ID>

# Get proposal state
cast call <COMMUNITY_DAO> "state(uint256)(uint8)" <PROPOSAL_ID>
```

#### Write Operations

```bash
# Issue DID (as issuer)
cast send <DID_CONTRACT> \
  "issueDID(address,string)(uint256)" \
  <USER_ADDRESS> "ipfs://QmMetadata..." \
  --private-key <ISSUER_PRIVATE_KEY>

# Create proposal
cast send <COMMUNITY_DAO> \
  "propose(string,string,bytes)(uint256)" \
  "Title" "Description" "0x" \
  --private-key <USER_PRIVATE_KEY>

# Vote on proposal
cast send <COMMUNITY_DAO> \
  "castVote(uint256,uint8)" \
  <PROPOSAL_ID> 1 \
  --private-key <USER_PRIVATE_KEY>

# Create campaign
cast send <CAMPAIGN_MANAGER> \
  "createCampaign(string,string,uint256,uint256)(uint256)" \
  "Title" "ipfs://..." 1000000000000000000 2592000 \
  --private-key <VENDOR_PRIVATE_KEY>

# Contribute to campaign
cast send <CAMPAIGN_MANAGER> \
  "contribute(uint256)" <CAMPAIGN_ID> \
  --value 1ether \
  --private-key <CONTRIBUTOR_PRIVATE_KEY>
```

## Common Workflows

### 1. Onboard New User

```bash
# 1. Issue DID
cast send $DID_CONTRACT "issueDID(address,string)" $USER "ipfs://metadata" --pk $ADMIN_KEY

# 2. Verify user
cast send $DID_CONTRACT "setVerified(address,bool)" $USER true --pk $ADMIN_KEY

# 3. Grant initial reputation
cast send $REPUTATION_CONTRACT "increaseReputation(address,uint256,string)" \
  $USER 100 "Welcome bonus" --pk $ADMIN_KEY
```

### 2. Create and Execute Proposal

```bash
# 1. Create proposal
PROPOSAL_ID=$(cast send $DAO "propose(string,string,bytes)" \
  "Title" "Description" "0x" --pk $USER_KEY)

# 2. Wait for voting delay
sleep 15  # or more based on blocks

# 3. Vote
cast send $DAO "castVote(uint256,uint8)" $PROPOSAL_ID 1 --pk $USER1_KEY
cast send $DAO "castVote(uint256,uint8)" $PROPOSAL_ID 1 --pk $USER2_KEY

# 4. Wait for voting period to end
# ...

# 5. Register in proposal registry
cast send $REGISTRY "registerProposal(uint256,bytes)" $PROPOSAL_ID "0x" --pk $ADMIN_KEY

# 6. Sharia review
cast send $ZK_DAO "submitReview(uint256,uint8,bytes32,string)" \
  $PROPOSAL_ID 1 $PROOF_HASH "ipfs://justification" --pk $COUNCIL_KEY

# 7. Create batch
cast send $REGISTRY "createBatch(uint256[])" "[$PROPOSAL_ID]" --pk $ADMIN_KEY

# 8. Execute via multisig
# Submit transaction to multisig
# Confirm with threshold signers
# Execute
```

### 3. Run a Campaign

```bash
# 1. Register as vendor
cast send $VENDOR_REGISTRY "registerVendor(string,string)" \
  "My Org" "ipfs://metadata" --pk $VENDOR_KEY

# 2. Get verified
cast send $VENDOR_REGISTRY "verifyVendor(address)" $VENDOR --pk $ADMIN_KEY

# 3. Create campaign
CAMPAIGN_ID=$(cast send $CAMPAIGN_MANAGER \
  "createCampaign(string,string,uint256,uint256)" \
  "Title" "ipfs://desc" 10000000000000000000 2592000 --pk $VENDOR_KEY)

# 4. Contributors donate
cast send $CAMPAIGN_MANAGER "contribute(uint256)" $CAMPAIGN_ID \
  --value 1ether --pk $CONTRIBUTOR_KEY

# 5. Withdraw when complete
cast send $CAMPAIGN_MANAGER "withdrawFunds(uint256)" $CAMPAIGN_ID --pk $VENDOR_KEY
```

## Environment Variables

Create a `.env` file:

```bash
# Network
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY

# Keys (NEVER commit these!)
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_key

# Contract Addresses (after deployment)
DID_CONTRACT=0x...
REPUTATION_CONTRACT=0x...
COMMUNITY_DAO=0x...
PROPOSAL_REGISTRY=0x...
ZK_SHARIA_DAO=0x...
WAKAF_TREASURY=0x...
CAMPAIGN_MANAGER=0x...
VENDOR_REGISTRY=0x...
NFT_RECEIPT_ISSUER=0x...
PROTOCOL_ADMIN=0x...
MULTISIG=0x...
```

Load environment variables:
```bash
source .env
```

## Troubleshooting

### Build Errors

```bash
# Clean and rebuild
forge clean
forge build

# Update dependencies
forge update
```

### Test Failures

```bash
# Run with verbose output
forge test -vvvv

# Run specific test
forge test --match-test testName -vvv
```

### Gas Issues

```bash
# Check gas usage
forge test --gas-report

# Optimize
# Add optimizer settings to foundry.toml
```

### Deployment Issues

```bash
# Verify RPC connection
cast block-number --rpc-url $RPC_URL

# Check balance
cast balance $YOUR_ADDRESS --rpc-url $RPC_URL

# Estimate gas
cast estimate <CONTRACT> <FUNCTION> <ARGS> --rpc-url $RPC_URL
```

## Useful Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## Next Steps

1. ✅ Deploy contracts to testnet
2. ✅ Verify contracts on Etherscan
3. ✅ Set up frontend interfaces
4. ✅ Integrate with IPFS
5. ✅ Implement ZK proof verification
6. ✅ Deploy indexer/subgraph
7. ✅ Conduct security audit
8. ✅ Deploy to mainnet

---

For detailed documentation, see TAWF_README.md and ARCHITECTURE.md
