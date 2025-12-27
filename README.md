# Tawf Governance System

A comprehensive blockchain-based governance system implementing Islamic principles with zero-knowledge proofs for Sharia compliance verification.

## Architecture Overview

The Tawf system consists of four main layers:

### 1. Identity Layer
- **TawfDID**: Soulbound NFT-based decentralized identity system
- **TawfReputation**: On-chain reputation tracking for community participation

### 2. Governance Layer
- **CommunityDAO**: Community-driven proposal and voting system
- **ProposalRegistry**: Batching and lifecycle management for proposals
- **ZKShariaDAO**: Private Sharia compliance verification using zero-knowledge proofs

### 3. Protocol Layer
- **WakafTreasury**: Endowment fund management with transparent allocations
- **CampaignManager**: Fundraising campaign creation and contribution tracking
- **VendorRegistry**: Verified vendor and organizer management
- **NFTReceiptIssuer**: Contribution receipt NFTs for transparency

### 4. Safety & Admin Layer
- **ProtocolAdmin**: Emergency pause and admin controls
- **TawfLabsMultisig**: Multi-signature wallet for critical operations

## Contract Addresses

After deployment, contract addresses will be listed here.

## Features

### Identity & Reputation
- Non-transferable (soulbound) identity tokens
- IPFS-based metadata storage
- Reputation scoring based on community participation
- KYC verification integration

### Governance
- Reputation-weighted voting
- Configurable voting parameters (threshold, delay, period, quorum)
- Proposal batching for efficient execution
- Private Sharia council review with ZK proofs
- Emergency veto capabilities

### Fundraising
- Vendor verification system
- Campaign creation with customizable goals and durations
- Automatic NFT receipt issuance for contributions
- Transparent fund tracking
- Campaign verification by admins

### Safety
- Pausable contracts
- Multi-signature controls for critical operations
- Role-based access control
- Emergency action mechanisms

## Installation

```bash
# Clone the repository
git clone <repository-url>
cd tawf-gov/gov

# Install dependencies
forge install

# Build contracts
forge build
```

## Testing

```bash
# Run all tests
forge test

# Run tests with gas reporting
forge test --gas-report

# Run specific test file
forge test --match-path test/TawfDID.t.sol

# Run tests with verbosity
forge test -vvv
```

## Deployment

### Local Deployment (Anvil)

```bash
# Start local node
anvil

# Deploy (in another terminal)
forge script script/DeployTawfSystem.s.sol:DeployTawfSystem \
  --rpc-url http://localhost:8545 \
  --private-key <PRIVATE_KEY> \
  --broadcast
```

### Testnet Deployment

```bash
# Set environment variables
export PRIVATE_KEY=<your-private-key>
export RPC_URL=<testnet-rpc-url>

# Deploy
forge script script/DeployTawfSystem.s.sol:DeployTawfSystem \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

### Setup Test Data

```bash
# After deployment, set contract addresses
export DID_CONTRACT=<did-contract-address>
export REPUTATION_CONTRACT=<reputation-contract-address>
export VENDOR_REGISTRY=<vendor-registry-address>

# Run setup script
forge script script/SetupTestData.s.sol:SetupTestData \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

## Usage Examples

### Issuing a DID

```solidity
// As an issuer
didContract.issueDID(userAddress, "ipfs://QmMetadata...");
didContract.setVerified(userAddress, true);
```

### Creating a Proposal

```solidity
// User must have DID and minimum reputation
communityDAO.propose(
    "Proposal Title",
    "Detailed description",
    encodedCallData
);
```

### Voting on a Proposal

```solidity
// 0 = Against, 1 = For, 2 = Abstain
communityDAO.castVote(proposalId, 1);
```

### Creating a Campaign

```solidity
// Vendor must be verified
campaignManager.createCampaign(
    "Campaign Title",
    "ipfs://QmCampaignDetails...",
    10 ether, // goal
    30 days   // duration
);
```

### Contributing to a Campaign

```solidity
// Anyone can contribute
campaignManager.contribute{value: 1 ether}(campaignId);
// Receipt NFT is automatically issued
```

## Contract Interfaces

All contract interfaces are defined in `src/interfaces/`:

- `ITawfDID.sol`
- `ITawfReputation.sol`
- `ICommunityDAO.sol`
- `IProposalRegistry.sol`
- `IZKShariaDAO.sol`
- `IWakafTreasury.sol`
- `ICampaignManager.sol`
- `IVendorRegistry.sol`
- `INFTReceiptIssuer.sol`
- `IProtocolAdmin.sol`

## Security Considerations

1. **Access Control**: All contracts use OpenZeppelin's AccessControl for role-based permissions
2. **Reentrancy Protection**: Critical functions are protected with ReentrancyGuard
3. **Pausability**: Key contracts can be paused in emergencies
4. **Multi-signature**: Critical operations require multi-sig approval
5. **Soulbound Tokens**: DIDs are non-transferable to prevent identity trading

## Governance Parameters

Default values (can be updated by admin):

- **Proposal Threshold**: 100 reputation points
- **Voting Delay**: 1 block
- **Voting Period**: 50,400 blocks (~7 days)
- **Quorum**: 1,000 votes
- **Multisig Threshold**: 2-of-N signatures

## Development

### Project Structure

```
gov/
├── src/
│   ├── identity/       # DID and Reputation contracts
│   ├── governance/     # DAO and proposal contracts
│   ├── protocol/       # Treasury, Campaign, Vendor contracts
│   ├── admin/          # Admin and multisig contracts
│   └── interfaces/     # Contract interfaces
├── script/             # Deployment and setup scripts
├── test/              # Test files
└── foundry.toml       # Foundry configuration
```

### Adding New Contracts

1. Create contract in appropriate `src/` subdirectory
2. Create interface in `src/interfaces/`
3. Add to deployment script
4. Write comprehensive tests
5. Update documentation

## Roadmap

- [ ] ZK proof verification integration
- [ ] Subgraph for indexing and querying
- [ ] Frontend dApp interfaces
- [ ] Multi-chain deployment
- [ ] Governance token (if needed)
- [ ] Advanced reputation algorithms
- [ ] Integration with external KYC providers

## Contributing

Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- OpenZeppelin for secure contract implementations
- Foundry for development framework
- Community contributors

## Contact

For questions and support:
- GitHub Issues: [Create an issue]
- Discord: [Join our Discord]
- Email: contact@tawf.labs

---

Built with ❤️ by Tawf Labs
