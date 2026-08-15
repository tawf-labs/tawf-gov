# Deprecated: Solana Implementation

This directory is stubbed and no longer maintained.

Tawf governance runs on the Ethereum VM. The DAO is live on Sepolia and is being
moved to Arbitrum. The Solana Anchor programs in this directory were an early
experiment and are kept only for reference.

## Status

| Layer | Status |
|---|---|
| EVM (Ethereum) | Active, live on Sepolia, targeting Arbitrum mainnet |
| Solana (this directory) | Stubbed in favor of EVM |

## Why EVM

Ethereum provides the standards and security guarantees that a Sharia-compliant
treasury requires. The ERC-5192 soulbound identity, the OpenZeppelin audit base,
and the mature multisig and time-lock primitives are all first-class on EVM. The
core contracts stay on Ethereum.

Any future multichain expansion is application-level only and will not replace
the Ethereum core.
