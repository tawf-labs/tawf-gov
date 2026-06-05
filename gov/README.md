# Tawf Governance — Ethereum Contracts (V1)

This directory contains the original Ethereum Solidity contracts for the Tawf Governance System, deployed on Sepolia testnet.

> **Note**: Active development has moved to Solana. See [`tawf-gov-solana/`](../tawf-gov-solana) for the current Anchor programs.
> See [`feat/solana-migration`](https://github.com/tawf-labs/tawf-gov/tree/feat/solana-migration) branch.

## Contracts

```
src/
├── identity/        TawfPassport (ERC-5192), TawfReputation
├── governance/      ProposalManager, VotingManager, MilestoneManager, ParticipationTracker
├── protocol/        PoolManager, ZakatEscrowManager, WakafTreasury, DonationReceiptNFT
├── tokens/          MockIDRX, VotingNFT
├── admin/           ProtocolAdmin, TawfLabsMultisig
└── interfaces/      ITawfPassport, IProposalManager, etc.
```

## Build & Test

```bash
forge build
forge test -vvv
```

## Deploy

```bash
forge script script/DeployTawfSystem.s.sol \
  --rpc-url sepolia --account <name> --broadcast
```

## Sepolia Addresses

See [README.md](../README.md#ethereum-version-v1--sepolia) for full contract list.

## License

Apache 2.0
