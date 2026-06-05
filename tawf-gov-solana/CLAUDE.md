# Tawf-Gov Architecture

## Project Structure
```
tawf-gov/
├── tawf-gov-solana/        # Anchor workspace (11 programs)
│   ├── programs/
│   │   ├── tawf-passport/   # Identity/soulbound passport
│   │   ├── voting-nft/      # Tier-weighted voting credentials
│   │   ├── proposal-manager/ # Proposal lifecycle
│   │   ├── voting-manager/   # Governance voting
│   │   ├── milestone-manager/ # Milestone approval voting
│   │   ├── pool-manager/     # Campaign fundraising (IDRX)
│   │   ├── zakat-escrow/     # Zakat-compliant escrow (30d deadline)
│   │   ├── wakaf-treasury/   # Endowment treasury with allocations
│   │   ├── donation-receipt-nft/ # Donation receipt accounts
│   │   └── idrx-mock/        # Dev IDRX token faucet (Token-2022)
│   ├── tests/               # 27 integration tests
│   └── Anchor.toml          # localnet config
├── tawf-gov-frontend/       # React 19 + Vite 6.2 + Tailwind v4
│   └── src/components/      # Layout, Landing, Manifesto, Donate, Governance
└── MIGRATION_PLAN.md        # Full migration plan (997 lines)
```

## Key Decisions
- **Chain**: Solana (IDRX native, Superteam Indonesia)
- **Stablecoin**: IDRX SPL `idrxZcP8xiKkYk6XGD4uz1dxEYCWSgKDHqgjsBbwDur`
- **Token Standard**: Token-2022 (`anchor_spl::token_interface`)
- **Multisig**: Squads v4 (not custom)
- **Program ID source of truth**: `target/deploy/*-keypair.json`
- **Frontend**: React 19 + Vite 6.2 (NOT Next.js)

## Development Commands
```bash
# Solana
cd tawf-gov-solana
solana-test-validator --reset --quiet  # Start local validator
anchor build                           # Build all 11 programs
anchor deploy                          # Deploy to localnet
ANCHOR_PROVIDER_URL=http://localhost:8899 ANCHOR_WALLET=/tmp/chaos-wallet.json npx ts-mocha -p ./tsconfig.json -t 1000000 'tests/*.ts'

# Frontend
cd tawf-gov-frontend
npm run dev   # Dev server
npm run build # Production build
```

## Wallet Setup
```bash
solana-keygen new -o /tmp/chaos-wallet.json --no-bip39-passphrase
solana config set --keypair /tmp/chaos-wallet.json --url localhost
solana airdrop 500
```

## Architecture
- All programs use PDA-seeded accounts (no direct key ownership)
- Cross-program CPI via anchor_spl::token_interface
- IDRX as Token-2022 (forward-compatible with SPL Token)
- 1 passport/wallet, 1 voting-nft/wallet, bounded vecs for credentials
- Proposals store milestones inline (max 10, bounded sizes <10KB)
