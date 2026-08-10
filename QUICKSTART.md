# Tawf Governance System: Quick Start Guide

## Solana Migration (Active)

> **Branch**: `feat/solana-migration`

### Prerequisites

```bash
# Solana toolchain
solana --version    # ≥ 1.18 (v3.1.12)
anchor --version    # ≥ 0.31.0
rustc --version     # ≥ 1.79

# Node.js
node --version      # ≥ 18 (v22.22.2)
```

### Setup

```bash
git checkout feat/solana-migration
cd tawf-gov-solana
npm install
```

### Start Local Validator

```bash
solana-test-validator --reset --quiet &
```

### Create & Fund Deployer Wallet

```bash
solana-keygen new -o /tmp/chaos-wallet.json --no-bip39-passphrase --force
solana config set --keypair /tmp/chaos-wallet.json --url localhost
solana airdrop 500
```

### Build & Deploy All 11 Programs

```bash
anchor build
anchor deploy
```

### Run Integration Tests (27 tests)

```bash
ANCHOR_PROVIDER_URL=http://localhost:8899 ANCHOR_WALLET=/tmp/chaos-wallet.json \
  npx ts-mocha -p ./tsconfig.json -t 1000000 'tests/*.ts'
```

### Start Frontend

```bash
cd ../tawf-gov-frontend
npm install
npm run dev
```

---

## Ethereum Version (V1: Sepolia)

### Prerequisites

- Foundry installed (`curl -L https://foundry.paradigm.xyz | bash && foundryup`)
- A wallet with testnet ETH

### Build

```bash
cd gov
forge build
```

### Test

```bash
forge test -vvv
```

### Deploy Locally

```bash
# Terminal 1
anvil

# Terminal 2
forge script script/DeployTawfSystem.s.sol:DeployTawfSystem \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```

---

## Key Commands Reference

### Solana (Anchor)

| Command | Description |
|---------|-------------|
| `anchor build` | Build all 11 programs |
| `anchor deploy` | Deploy to configured cluster |
| `anchor test` | Build + deploy + run mocha tests |
| `solana-test-validator --reset` | Start fresh local validator |

### Ethereum (Foundry)

| Command | Description |
|---------|-------------|
| `forge build` | Compile contracts |
| `forge test -vvv` | Run tests verbose |
| `forge test --gas-report` | Show gas usage |
| `forge clean` | Clean build artifacts |

---

## Contract Interactions

### Solana: Cast via Anchor TS SDK

```typescript
// Issue passport
await program.methods
  .issuePassport({ individual: {} }, "ipfs://meta")
  .accountsStrict({ issuer: wallet, holder: addr, passport: pda })
  .rpc()

// Create proposal
await program.methods
  .createProposal(organizer, title, desc, goal, ...)
  .accountsStrict({ signer: wallet, proposal: pda })
  .rpc()

// Cast vote
await program.methods
  .castVote({ support: {} }, 2)  // Tier 2 weight
  .accountsStrict({ voter: wallet, proposal, vote: pda })
  .signers([wallet])
  .rpc()
```

### Ethereum: Cast via `cast`

See [ARCHITECTURE.md](ARCHITECTURE.md) for full `cast` command reference.

---

## Troubleshooting

### Solana

```bash
# Validator not responding
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}'

# Insufficient balance
solana airdrop 500

# Program deploy authority mismatch
# Check Anchor.toml wallet matches solana config
```

### Ethereum

```bash
# Clean + rebuild
forge clean && forge build

# RPC connection
cast block-number --rpc-url $RPC_URL

# Balance check
cast balance $ADDRESS --rpc-url $RPC_URL
```

---

## Resources

- [ROADMAP.md](ROADMAP.md): Phase timeline
- [ARCHITECTURE.md](ARCHITECTURE.md): System architecture
- [MIGRATION_PLAN.md](MIGRATION_PLAN.md): EVM → Solana migration plan
- [Anchor Book](https://book.anchor-lang.com/)
- [Foundry Book](https://book.getfoundry.sh/)
