# Tawf Governance System

The governance backbone for the TAWF Sharia DApps Ecosystem. Provides identity (Tawf Passport), reputation, proposals, voting, milestone-based fund release, campaign pools, and Zakat-compliant escrow.

**Live on Ethereum Sepolia** — wired to ZKTCore from [zkt-hackathon](https://github.com/tawf-labs/zkt-hackathon).

## Architecture

```
src/
├── identity/
│   ├── TawfPassport.sol       ERC-5192 soulbound — Muzakki, Mustahik, Organization, ShariaCouncil
│   ├── TawfReputation.sol     Points-based reputation with history
│   ├── ERC5192.sol            Minimal Soulbound NFT (Final, EIP-5192)
│   └── IERC5192.sol           ERC-5192 interface
├── governance/
│   ├── ProposalManager.sol    Proposal lifecycle, KYC, campaign types, milestones
│   ├── VotingManager.sol      Tiered NFT voting (Tier 1/2/3 based on participation)
│   ├── MilestoneManager.sol   Sequential fund release with proof submission + voting
│   └── ParticipationTracker.sol  Privacy-safe activity counts (no amounts stored)
├── protocol/
│   ├── PoolManager.sol        Campaign pool creation, fundraising, withdrawal
│   ├── ZakatEscrowManager.sol Shafi'i-compliant Zakat escrow (30-day deadline, grace, redistribution)
│   └── DonationReceiptNFT.sol Soulbound ERC-721 receipt per donation
├── tokens/
│   ├── MockIDRX.sol           Testnet ERC-20 stablecoin with faucet
│   └── VotingNFT.sol          Soulbound voting power (Tier 1=1, Tier 2=2, Tier 3=3 votes)
├── admin/
│   ├── ProtocolAdmin.sol      Pause + admin controls
│   └── TawfLabsMultisig.sol   2-of-N multisig wallet
├── protocol/
│   └── WakafTreasury.sol      Endowment fund management
└── interfaces/
    ├── ITawfPassport.sol
    ├── ITawfReputation.sol
    ├── IProposalManager.sol
    └── IProtocolAdmin.sol
```

## Sepolia Deployment (V1 — 2026-05-29)

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

## Tawf Passport Types (ERC-5192)

| Type | Who | Can do |
|------|-----|--------|
| **Muzakki** | Donor | Donate, generate ZK eligibility proofs |
| **Mustahik** | Recipient | Receive zakat, encrypted off-chain metadata |
| **Organization** | NGO/Charity | Create proposals, manage campaigns, withdraw funds |
| **ShariaCouncil** | Islamic scholar | Review proposals, session-code auth (no wallet needed) |

Soulbound via ERC-5192. Burn rights: holder can `renouncePassport()`, admin can `revokePassport()`.

## Quick Start

```bash
git clone https://github.com/tawf-labs/tawf-gov.git
cd tawf-gov/gov
forge build
```

### Deploy

```bash
forge script script/DeployTawfSystem.s.sol \
  --rpc-url sepolia --account <name> --broadcast
```

### Test

```bash
forge test
```

## Integration with zkt-hackathon

The ZK layer ([zkt-hackathon](https://github.com/tawf-labs/zkt-hackathon)) imports these contracts via forge submodule:

```solidity
import "@tawf-gov/governance/ProposalManager.sol";
import "@tawf-gov/protocol/PoolManager.sol";
// ... etc
```

ZKTCore acts as the orchestration layer, wiring ZK proof verification (Groth16/UltraHONK) and nullifier-based double-spend prevention on top of the DAO contracts provided by this repo.

## Governance Parameters

| Parameter | Default | Settable via |
|-----------|---------|-------------|
| Voting period | 7 days | `ZKTCore.setVotingPeriod()` |
| Quorum | 10% of VotingNFT supply | `VotingManager.setQuorumPercentage()` |
| Pass threshold | 51% | `VotingManager.setPassThreshold()` |
| Sharia quorum | 3 reviewers | `ShariaReviewManager.setShariaQuorum()` |
| Zakat deadline | 30 days | Hardcoded in ZakatEscrowManager |

## License

MIT — see LICENSE.
