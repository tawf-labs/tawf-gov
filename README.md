# Tawf Governance System

Decentralized Sharia-compliant DAO for Zakat, Wakaf, and charitable giving.

> **Status**: Live on Sepolia (Ethereum), wired to ZKTCore from [zkt-hackathon](https://github.com/tawf-labs/zkt-hackathon). The core is targeting an Arbitrum mainnet deployment after a security audit.

---

## Ethereum Core (Active)

The DAO is built on the Ethereum VM. Identity, voting, and treasury contracts are
deployed on Sepolia and move to Arbitrum next.

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

**Deploy script**: `gov/script/DeployTawfSystem.s.sol`

### Architecture (Ethereum)

```
gov/src/
├── identity/
│   ├── TawfPassport.sol       ERC-5192 soulbound
│   ├── TawfReputation.sol     Points-based reputation
│   └── ERC5192.sol            Minimal Soulbound NFT
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

ZKTCore acts as the orchestration layer with Groth16/UltraHONK ZK proofs and
nullifier double-spend prevention.

---

## Solana (Deprecated)

A Solana port lived on branch `feat/solana-migration` with 12 Anchor programs. It
is stubbed in favor of the EVM core. See `tawf-gov-solana/DEPRECATED.md`.

Any future multichain work is application-level only and does not replace the
Ethereum core.

---

## Repository Structure

```
tawf-gov/
├── gov/                    # Ethereum Solidity contracts (active, Sepolia → Arbitrum)
├── tawf-gov-frontend/      # React frontend
├── tawf-gov-solana/        # Solana Anchor programs (deprecated, stub)
├── ROADMAP.md              # EVM roadmap
└── ARCHITECTURE.md         # System architecture docs
```

## License

Apache 2.0, see LICENSE.
