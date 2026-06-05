# Tawf Governance System

Decentralized Sharia-compliant DAO for Zakat, Wakaf, and charitable giving.

> **Ethereum (V1)**: Live on Sepolia — wired to ZKTCore from [zkt-hackathon](https://github.com/tawf-labs/zkt-hackathon)
> **Solana (V2)**: Active migration — [branch `feat/solana-migration`](https://github.com/tawf-labs/tawf-gov/tree/feat/solana-migration)

---

## Solana Migration (Active)

All 11 Anchor programs built, deployed to localnet, and integration-tested (27/27 passing).

| Layer | Programs | Status |
|-------|----------|--------|
| Identity | `tawf-passport`, `voting-nft` | ✅ 11 tests |
| Governance | `proposal-manager`, `voting-manager`, `milestone-manager` | ✅ 9 tests |
| Protocol | `pool-manager`, `zakat-escrow`, `wakaf-treasury`, `donation-receipt-nft` | ✅ 7 tests |
| Dev | `idrx-mock` | ✅ 2 tests |

**Frontend**: React 19 + Vite 6.2 + Tailwind CSS v4 + Solana wallet adapter

**Stablecoin**: IDRX SPL (`idrxZcP8xiKkYk6XGD4uz1dxEYCWSgKDHqgjsBbwDur`) — Token-2022

**[View full roadmap →](ROADMAP.md)**

### Quick Start (Solana)

```bash
git checkout feat/solana-migration
cd tawf-gov-solana

# Start local validator
solana-test-validator --reset --quiet

# Deploy all 11 programs
anchor deploy

# Run 27 integration tests
ANCHOR_PROVIDER_URL=http://localhost:8899 ANCHOR_WALLET=/tmp/chaos-wallet.json \
  npx ts-mocha -p ./tsconfig.json -t 1000000 'tests/*.ts'

# Start frontend
cd ../tawf-gov-frontend && npm run dev
```

---

## Ethereum Version (V1 — Sepolia)

### Deployed Contracts

| Contract | Address |
|----------|---------|
| TawfPassport | `0x68A39923A1b80F3d48B4bd60FBe4187Ff2B0a38e` |
| TawfReputation | `0xEBc9637933575Aa3b047Dc19C4dE3706F03DC32c` |
| VotingNFT | `0xEb44b1409F34944cd137DD522e8FE9dD41533D33` |
| DonationReceiptNFT | `0x536a7249113E2f2c06a6E85acDa9B54dc79F5e58` |
| ProposalManager | `0x37f87a1913a8efAE70a39850f8c9e2C63AeC556B` |
| VotingManager | `0x4B6600f35592A83770A610a038c012186471143a` |
| MilestoneManager | `0xb0Fa6d4a2038ed85c9d16664BeeD169858D5f183` |
| ParticipationTracker | `0xA2313195cB23cC0AeB28E94f43DFBE0Fdc3d2e37` |
| PoolManager | `0x10bE98A362c18d690BEd51069F8D0c847cf2092A` |
| ZakatEscrowManager | `0x3534105fD0338dAF5Faa0BC97c760Fe861bd052e` |
| MockIDRX | `0x23A48A17ea36627ACF4Ce349C14d17c7e7F90BCE` |

**Deploy script:** `script/DeployTawfSystem.s.sol` · Gas used: ~28.3M

### Architecture (Ethereum)

```
src/
├── identity/
│   ├── TawfPassport.sol       ERC-5192 soulbound
│   ├── TawfReputation.sol     Points-based reputation
│   └── ERC5192.sol            Minimal Soulbound NFT (Final)
├── governance/
│   ├── ProposalManager.sol    Proposal lifecycle, KYC, milestones
│   ├── VotingManager.sol      Tiered NFT voting
│   ├── MilestoneManager.sol   Sequential fund release
│   └── ParticipationTracker.sol  Activity counts
├── protocol/
│   ├── PoolManager.sol        Campaign pools, fundraising
│   ├── ZakatEscrowManager.sol Shafi'i-compliant Zakat escrow
│   ├── WakafTreasury.sol      Endowment fund management
│   └── DonationReceiptNFT.sol Soulbound ERC-721 receipt
├── tokens/
│   ├── MockIDRX.sol           Testnet ERC-20 stablecoin
│   └── VotingNFT.sol          Soulbound voting power
├── admin/
│   ├── ProtocolAdmin.sol      Pause + admin controls
│   └── TawfLabsMultisig.sol   2-of-N multisig
└── interfaces/
```

### Governance Parameters

| Parameter | Default | Settable via |
|-----------|---------|-------------|
| Voting period | 7 days | `ZKTCore.setVotingPeriod()` |
| Quorum | 10% of VotingNFT supply | `VotingManager.setQuorumPercentage()` |
| Pass threshold | 51% | `VotingManager.setPassThreshold()` |
| Sharia quorum | 3 reviewers | `ShariaReviewManager.setShariaQuorum()` |
| Zakat deadline | 30 days | Hardcoded in ZakatEscrowManager |

### Integration with zkt-hackathon

```solidity
import "@tawf-gov/governance/ProposalManager.sol";
import "@tawf-gov/protocol/PoolManager.sol";
```

ZKTCore acts as orchestration layer — Groth16/UltraHONK ZK proofs + nullifier double-spend prevention.

---

## Repository Structure

```
tawf-gov/
├── gov/                    # Ethereum Solidity contracts (V1 — Sepolia)
├── tawf-gov-solana/        # Solana Anchor programs (V2 — migration branch)
├── tawf-gov-frontend/      # React 19 + Vite 6.2 frontend
├── MIGRATION_PLAN.md       # Full migration plan (EVM → Solana)
├── ROADMAP.md              # 5-phase timeline with status
└── ARCHITECTURE.md         # System architecture docs
```

## License

Apache 2.0 — see LICENSE.
