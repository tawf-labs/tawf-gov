# Tawf Governance System — Architecture

## Solana Architecture (V2 — Active Migration)

```
┌─────────────────────────────────────────────────────────────────┐
│                    TAWF-GOV SOLANA ARCHITECTURE                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    IDENTITY LAYER                         │   │
│  │  ┌─────────────────┐    ┌──────────────────────────┐    │   │
│  │  │ tawf-passport    │    │ voting-nft                │    │   │
│  │  │ (PDA account)    │◄───│ Tier-weighted soulbound   │    │   │
│  │  │ - PassportType   │    │ - 1 wallet = 1 NFT       │    │   │
│  │  │ - credentials[]  │    │ - Tiers 1/2/3            │    │   │
│  │  │ - isVerified     │    │ - Auto-upgrade by metrics │    │   │
│  │  └─────────────────┘    └──────────────────────────┘    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    GOVERNANCE LAYER                       │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐     │   │
│  │  │proposal-mgr   │ │voting-mgr    │ │milestone-mgr │     │   │
│  │  │ - Lifecycle   │ │ - Quorum     │ │ - Milestone  │     │   │
│  │  │ - KYC/Status  │ │ - Threshold  │ │ - Voting     │     │   │
│  │  │ - Milestones  │ │ - Weighted   │ │ - Finalize   │     │   │
│  │  └────────────────┘ └────────────────┘ └────────────────┘ │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    PROTOCOL LAYER                         │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐     │   │
│  │  │pool-mgr       │ │zakat-escrow   │ │wakaf-treasury│     │   │
│  │  │ - IDRX Token  │ │ - 30d limit  │ │ - Deposits   │     │   │
│  │  │ - Donations   │ │ - Extension  │ │ - Alloc      │     │   │
│  │  │ - Withdraw    │ │ - Fallback   │ │ - Execute    │     │   │
│  │  └───────┬───────┘ └──────┬───────┘ └──────┬───────┘     │   │
│  │          │                │                │               │   │
│  │          └────────────────┼────────────────┘               │   │
│  │                           ▼                                │   │
│  │              ┌─────────────────────┐                       │   │
│  │              │donation-receipt-nft  │                       │   │
│  │              │ (Receipt PDA)       │                       │   │
│  │              └─────────────────────┘                       │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    CROSS-CUTTING                          │   │
│  │  ┌──────────────────────────────────────────────────┐    │   │
│  │  │ IDRX SPL (Token-2022) — all programs use CPI     │    │   │
│  │  │ Squads v4 multisig (future integration)           │    │   │
│  │  │ All accounts PDA-derived — no direct key owners  │    │   │
│  │  └──────────────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Account Model

All state stored in PDA accounts (no EVM storage). Key accounts:

| Account | Seeds | Size | Notes |
|---------|-------|------|-------|
| Passport | `[b"passport", holder]` | ~500B | 1 per wallet |
| VotingNFT | `[b"voting-nft", holder]` | ~300B | 1 per wallet |
| Proposal | `[b"proposal", organizer]` | ~8KB | Max 10 milestones inline |
| Vote record | `[b"vote", proposal, voter]` | ~80B | 1 per voter per proposal |
| Campaign pool | `[b"pool", organizer]` | ~200B | 1 per organizer |
| Zakat pool | `[b"zakat", organizer]` | ~200B | 1 per organizer |
| Donor record | `[b"donor", pool, donor]` | ~80B | 1 per donor per pool |

### IDRX Integration

- Token standard: Token-2022 (`anchor_spl::token_interface`)
- All fund transfers use `transfer_checked` with 6 decimals
- PDAs sign via `invoke_signed` for pool vaults and treasury vaults
- Dev mock: IDRX mock program with PDA mint + authority

### Cross-Program Communication

All programs read each other's accounts directly (same Solana runtime). No complex CPI needed for reads. For token transfers, CPI to SPL Token-2022 program.

---

## Ethereum Architecture (V1 — Sepolia)

### System Components

1. **Community dApp** — Governance participation
2. **Vendor/Organizer Portal** — Campaign creation and management
3. **Sharia Council Interface** — Islamic compliance review
4. **Tawf Labs Admin Console** — System administration

### Flow Diagrams

#### Identity Registration

```
User → Wallet → KYC Service
KYC Service → Tawf Labs Multisig (approval)
Multisig → TawfPassport (issue soulbound NFT)
TawfPassport → IPFS (store metadata)
```

#### Proposal → Vote → Execute

```
Community Member → ProposalManager (create)
ProposalManager → VotingManager (vote)
Voting NFT → weighted vote (Tier 1-3)
VotingManager → finalize (quorum + threshold)
MilestoneManager → approve/reject milestones
PoolManager → withdraw funds
```

### Deployed Contracts (Sepolia)

| Contract | Address |
|----------|---------|
| TawfPassport | `0x68A39923A1b80F3d48B4bd60FBe4187Ff2B0a38e` |
| VotingNFT | `0xEb44b1409F34944cd137DD522e8FE9dD41533D33` |
| ProposalManager | `0x37f87a1913a8efAE70a39850f8c9e2C63AeC556B` |
| PoolManager | `0x10bE98A362c18d690BEd51069F8D0c847cf2092A` |
| ZakatEscrowManager | `0x3534105fD0338dAF5Faa0BC97c760Fe861bd052e` |
| *(Full list in README.md)* | |

### Security Mechanisms (Ethereum)

1. **RBAC** — Admin, Issuer, Executor, Council roles
2. **Multisig** — M-of-N for critical ops (2-of-N)
3. **Pausability** — Emergency pause
4. **Soulbound** — Non-transferable NFTs (ERC-5192)
5. **Time locks** — Voting delays, campaign durations
6. **ZK proofs** — Sharia council privacy (Groth16/UltraHONK)

---

## Testing Strategy

### Solana (Active)

| Level | Tool | Count | Status |
|-------|------|-------|--------|
| Integration (TS) | ts-mocha + Anchor | 27 | ✅ |
| Unit (Rust) | LiteSVM | Planned | ⬜ |

### Ethereum (V1)

```bash
forge test -vvv
```

---

## Key Differences: EVM → Solana

| Aspect | Ethereum | Solana |
|--------|----------|--------|
| State | Contract storage | PDA accounts |
| Auth | msg.sender | Signer checks |
| Tokens | ERC-20 MockIDRX | SPL Token-2022 IDRX |
| NFT | ERC-721 + ERC-5192 | PDA accounts with metadata |
| Multisig | Custom TawfLabsMultisig | Squads v4 |
| Compute | Gas (ETH) | CU (~$0.00025/tx) |
| Block time | 12s | 400ms |

---

## Environment

### Solana

```bash
solana config set --keypair /tmp/chaos-wallet.json --url localhost
export ANCHOR_PROVIDER_URL=http://localhost:8899
export ANCHOR_WALLET=/tmp/chaos-wallet.json
```

### Ethereum

```bash
export SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
export PRIVATE_KEY=your_key
export ETHERSCAN_API_KEY=your_key
```

---

## License

MIT
