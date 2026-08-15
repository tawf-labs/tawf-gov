# Tawf Governance: EVM Roadmap

> **Core**: Ethereum VM (Sepolia, targeting Arbitrum)
> **Status**: Phase 1-3 deployed on Sepolia, Phase 4-5 pending

---

## ✅ Phase 1: Identity Layer (Complete)

| Contract | Status | Chain |
|----------|--------|-------|
| TawfPassport | ✅ Deployed | Sepolia |
| VotingNFT | ✅ Deployed | Sepolia |

Milestone: Soulbound identity and tiered voting credentials on Sepolia.

---

## ✅ Phase 2: Governance Layer (Complete)

| Contract | Status | Chain |
|----------|--------|-------|
| ProposalManager | ✅ Deployed | Sepolia |
| VotingManager | ✅ Deployed | Sepolia |
| MilestoneManager | ✅ Deployed | Sepolia |

Milestone: Full proposal lifecycle with tier-weighted voting on Sepolia.

---

## ✅ Phase 3: Protocol Layer (Complete)

| Contract | Status | Chain |
|----------|--------|-------|
| PoolManager | ✅ Deployed | Sepolia |
| ZakatEscrowManager | ✅ Deployed | Sepolia |
| WakafTreasury | ✅ Deployed | Sepolia |
| DonationReceiptNFT | ✅ Deployed | Sepolia |
| MockIDRX | ✅ Deployed | Sepolia |

Milestone: Fundraising, Zakat escrow, and treasury management on Sepolia.

---

## 🚧 Phase 4: Arbitrum Migration

| Task | Status |
|------|--------|
| Contract audit (external firm) | ⬜ |
| Deploy to Arbitrum Sepolia testnet | ⬜ |
| Integration tests on Arbitrum | ⬜ |
| Deploy to Arbitrum mainnet | ⬜ |

Milestone: Audited contracts running on Arbitrum mainnet with lower gas costs
while preserving Ethereum security guarantees.

---

## 🔮 Phase 5: Production

| Task | Status |
|------|--------|
| Frontend: wallet connection and governance UI | ✅ |
| Frontend: proposal creation and voting | ⬜ |
| Sharia council dashboard | ⬜ |
| Community launch | ⬜ |

---

## Solana (Deprecated)

A Solana migration with 12 Anchor programs exists on branch
`feat/solana-migration` but is stubbed in favor of EVM. See
`tawf-gov-solana/DEPRECATED.md`. The Ethereum VM provides the security
standards needed for Sharia-compliant treasury operations.

## Deployment Stats

| Metric | Value |
|--------|-------|
| Contracts on Sepolia | 11 Solidity contracts |
| Multisig | 2-of-N TawfLabsMultisig |
| ZK proofs | Groth16 / UltraHONK via ZKTCore |
| Target L2 | Arbitrum |

## License

Apache 2.0