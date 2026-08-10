# AGENTS.md: Tawf-Gov

> Sharia-compliant DAO for Zakat/Wakaf on Solana. 12 Anchor programs, 27 tests, React/Vite frontend.

## What This Project Is

Tawf-Gov is the governance and protocol layer for Islamic charitable giving on Solana. It provides soulbound identity (TawfPassport), tier-weighted voting (VotingNFT), proposal lifecycle management, campaign fundraising pools, zakat-compliant escrow with 30-day deadlines, wakaf endowment treasuries, and donation receipt tracking. A ShariaReviewManager with a pluggable verifier interface (ZK/Arcium) enables Sharia compliance verification.

## ⚡ Quick Reference

```bash
# Build
cd tawf-gov-solana && anchor build

# Test (requires local validator)
solana-test-validator &
solana airdrop 10
anchor deploy
ANCHOR_PROVIDER_URL=http://localhost:8899 ANCHOR_WALLET=~/.config/solana/id.json npx ts-mocha -p ./tsconfig.json -t 1000000 'tests/*.ts'

# Frontend
cd tawf-gov-frontend && npm run dev
```

## Program List (12 total)

| # | Program | Tests | Description |
|---|---------|-------|-------------|
| 1 | `tawf-passport` | 5 | Soulbound identity passport |
| 2 | `voting-nft` | 6 | Tier-weighted voting credentials |
| 3 | `proposal-manager` | 5 | Proposal creation, KYC, status |
| 4 | `voting-manager` | 2 | Cast vote, finalize vote |
| 5 | `milestone-manager` | 2 | Milestone voting and finalization |
| 6 | `pool-manager` | 1 | Campaign fundraising pools |
| 7 | `zakat-escrow` | 1 | Zakat escrow with 30-day deadline |
| 8 | `wakaf-treasury` | 2 | Endowment treasury + allocations |
| 9 | `donation-receipt-nft` | 1 | Donation receipt records |
| 10 | `idrx-mock` | 2 | Dev IDRX faucet (Token-2022) |
| 11 | `sharia-review-manager` | 0* | Pluggable ZK/Arcium verifier |
| 12 | `participation-tracker` | 3 | Privacy-safe participation metrics |

*Sharia-review-manager has no standalone tests yet, tested via integration.

## Toolchain

| Tool | Version | Notes |
|------|---------|-------|
| Anchor | **1.0.2** | Upgraded from 0.31.0 for Arcium CPI compatibility |
| Solana CLI | 3.1.12 | |
| Rust | 1.94.1 | |
| Node.js | v22.22.2 | |
| TypeScript | 5.x | |
| Test runner | ts-mocha | `@anchor-lang/core` (NOT `@coral-xyz/anchor`) |

## Architecture Rules

1. **All accounts are PDA-derived**: never use raw keypairs for state storage
2. **Token-2022** via `anchor_spl::token_interface`: NOT legacy SPL Token
3. **Program ID source of truth**: `target/deploy/*-keypair.json`: sync with `anchor keys sync`
4. **Anchor 1.0 changes from 0.31**:
   - `AccountInfo<'info>` → `UncheckedAccount<'info>` (deprecated in 1.0)
   - `CpiContext::new(program.to_account_info())` → `CpiContext::new(program.key())`
   - Every `#[derive(Accounts)]` struct needs at least one PDA with `bump`
   - Test imports: `@anchor-lang/core` (NOT `@coral-xyz/anchor`)
5. **Wallet path**: `~/.config/solana/id.json` (NOT `/tmp/chaos-wallet.json`)
6. **NO emojis in code, logs, or events** unless explicitly requested
7. **Bounded Vec sizes**: credentials max 8, milestones max 10, strings <10KB

## File Layout

```
tawf-gov/
├── tawf-gov-solana/          # Anchor workspace
│   ├── Anchor.toml           # wallet = "~/.config/solana/id.json"
│   ├── programs/             # 12 program directories
│   ├── tests/                # 10 test files (ts-mocha)
│   ├── tsconfig.json         # commonjs, es6, mocha+chai types
│   └── Cargo.toml            # workspace members = ["programs/*"]
├── tawf-gov-frontend/        # React 19 + Vite 6.2 + Tailwind v4
│   └── src/components/      # Layout, Landing, Manifesto, Donate, Governance
├── MIGRATION_PLAN.md         # Full Ethereum→Solana migration tracker
├── ROADMAP.md               # 5-phase timeline with status
└── ARCHITECTURE.md          # System design
```

## Key Decisions

- **Solana** over Ethereum, IDRX native, Superteam Indonesia, lower costs
- **No Next.js**: user rejected; React 19 + Vite 6.2 instead
- **Squads v4** for production multisig (do NOT build custom multisig)
- **ShariaReviewManager** is a shared standard, pluggable: `verifier: Option<Pubkey>`
  - `None` → simple on-chain vote/multisig
  - `Some(Pubkey)` → ZK/Arcium proof required
- **USDC supported** alongside IDRX from day 1
- **Git submodule** from tawf-gov for zkt-hackathon dependency

## Testing

```bash
# Full suite (27 tests)
cd tawf-gov-solana
solana-test-validator &  # Start fresh validator
anchor deploy
ANCHOR_PROVIDER_URL=http://localhost:8899 ANCHOR_WALLET=~/.config/solana/id.json npx ts-mocha -p ./tsconfig.json -t 1000000 'tests/*.ts'

# Single test file
npx ts-mocha -p ./tsconfig.json -t 1000000 'tests/proposal-manager.ts'
```

## Program IDs (localnet: will change per deploy)

| Program | Localnet ID |
|---------|------------|
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

## Gotchas

1. **Validator needs `--reset` on first start**: existing ledger may be from different genesis
2. **Wallet at `/tmp/` gets wiped**: always copy to `~/.config/solana/id.json` after keygen
3. **`anchor deploy` stale**: use `anchor program deploy` in Anchor 1.0+
4. **idl-build warnings** on SPL programs, harmless, from `anchor-spl` feature flag
5. **Box-wrapping** required for MXE/Cluster/CompDef accounts on queue path (Arcium only)
6. **`derive_mempool_pda!(mxe_account)` NO ErrorCode arg**: v0.10.x removed second arg

## Related Repos

- **zkt-hackathon** (`feat/solana-rewrite`), confidential zakat layer using Arcium MPC + zkt-core CPI facade
- **tawf-gov** Ethereum original (`main`), 16 Solidity contracts on Sepolia (reference only)
