# Tawf-Gov Architecture

## Project Structure
```
tawf-gov/
├── tawf-gov-solana/        # Anchor workspace (12 programs)
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
│   │   ├── sharia-review-manager/ # Sharia compliance (pluggable ZK/Arcium)
│   │   └── idrx-mock/        # Dev IDRX token faucet (Token-2022)
│   ├── tests/               # 27 integration tests
│   └── Anchor.toml          # localnet config
├── tawf-gov-frontend/       # React 19 + Vite 6.2 + Tailwind v4
│   └── src/components/      # Layout, Landing, Manifesto, Donate, Governance
└── MIGRATION_PLAN.md        # Full migration plan
```

## Key Decisions
- **Chain**: Solana (IDRX native, Superteam Indonesia)
- **Anchor**: 1.0.2 (upgraded from 0.31.0 for Arcium CPI compatibility)
- **Stablecoin**: IDRX SPL `idrxZcP8xiKkYk6XGD4uz1dxEYCWSgKDHqgjsBbwDur` + USDC
- **Token Standard**: Token-2022 (`anchor_spl::token_interface`)
- **Multisig**: Squads v4 (not custom)
- **Program ID source of truth**: `target/deploy/*-keypair.json`
- **Frontend**: React 19 + Vite 6.2 (NOT Next.js)
- **ZK/Privacy**: Arcium MPC for confidential computation (ShariaReviewManager pluggable interface)
- **Test package**: `@anchor-lang/core` (Anchor 1.0+)

## Development Commands
```bash
# Solana
cd tawf-gov-solana
solana-test-validator        # Start local validator
anchor build                 # Build all 12 programs
anchor deploy                # Deploy to localnet
ANCHOR_PROVIDER_URL=http://localhost:8899 ANCHOR_WALLET=~/.config/solana/id.json npx ts-mocha -p ./tsconfig.json -t 1000000 'tests/*.ts'

# Frontend
cd tawf-gov-frontend
npm run dev                  # Dev server
npm run build                # Production build
```

## Wallet Setup
```bash
solana-keygen new -o /tmp/chaos-wallet.json --no-bip39-passphrase --force
cp /tmp/chaos-wallet.json ~/.config/solana/id.json
solana config set --keypair ~/.config/solana/id.json --url localhost
solana airdrop 500
```

## Architecture
- 12 programs, all PDA-seeded accounts (no direct key ownership)
- Cross-program CPI via anchor_spl::token_interface
- IDRX as Token-2022 (forward-compatible with SPL Token)
- 1 passport/wallet, 1 voting-nft/wallet, bounded vecs for credentials
- Proposals store milestones inline (max 10, bounded sizes <10KB)
- ShariaReviewManager: pluggable verifier, `None` = simple vote, `Some(Pubkey)` = ZK proof required

## Program IDs (localnet)
| Program | ID |
|---------|----|
| tawf-passport | `6669YfjNt8YbQ1wrQw9jJXpQKzGhEvGjhpGepMPcsmNb` |
| voting-nft | `6viNr1fokMKD3zfp5Cv2E8Lij2K27pecYPd92F2hT5gZ` |
| proposal-manager | `45Wawfsz4Zqj7iP1PyVm6bA8NwpvYZUTDP79xdQgCXov` |
| voting-manager | `5vm34iLwi38MMXeLQwy7VmshMx3sc6pKLMhaEdTxcUQh` |
| milestone-manager | `8R8moNb35W4hwENApADrVjQbTTHeEekaeevWMU8MdpxU` |
| pool-manager | `GAT3Cc9Aw7wuyZmWvdE37fjnCsPUsjt969Ekwng1xhvZ` |
| zakat-escrow | `6ANXqsFLDfiPzuodehSvtYhc6T9JwU26B5X7zji1TRXF` |
| wakaf-treasury | `HaYfHVmSpTwrydoP4fX8yZDsEbkuiA1NW7aUvFmLG6gg` |
| donation-receipt-nft | `5EVbuidmVDXAWwn6RpXB9D3By8xB8Thbv8VfuiahD4Bb` |
| idrx-mock | `84qrLb5tLKCFUXJ1NDhKvp73dLLEi3e5LURZ9cDUEjom` |
| sharia-review-manager | `BHy4RmvgvEHG9Sw4gM9gYxn7qSTtcQ2CPqNPTH9obtUD` |
