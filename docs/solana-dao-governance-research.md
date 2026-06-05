# Solana DAO Governance — EVM → Solana Mapping

> Research compiled June 2025. Covers Anchor 1.0.x, SPL Governance, Token-2022, and Islamic finance DAOs on Solana.

---

## 1. Anchor Framework — Current State

### Version

| Package | Version | Notes |
|---------|---------|-------|
| `anchor-lang` | **1.0.2** | Stable release (docs.rs/crates.io) |
| `anchor-spl` | 1.0.2 | CPI helpers for SPL programs |
| `anchor-client` | 1.0.2 | Rust client |
| `@anchor-lang/core` | 1.0.x | TS client (npm) |
| `@anchor-lang/cli` | 1.0.x | CLI tooling |

Install via AVM: `avm install latest && avm use latest`

---

### 1.1 Account Structures (PDA Derivation)

**Pattern:** Deterministic addresses from seeds + program ID. No private key — program signs via `invoke_signed`.

```rust
#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(
        init,
        payer = authority,
        space = 8 + DaoConfig::INIT_SPACE,
        seeds = [b"config", authority.key().as_ref()],
        bump
    )]
    pub config: Account<'info, DaoConfig>,

    #[account(mut)]
    pub authority: Signer<'info>,

    pub system_program: Program<'info, System>,
}

#[account]
#[derive(InitSpace)]
pub struct DaoConfig {
    pub authority: Pubkey,       // 32 bytes
    pub proposal_count: u64,     // 8 bytes
    pub voting_period: i64,      // 8 bytes
    pub quorum: u64,             // 8 bytes
    pub bump: u8,                // 1 byte
}
```

**Client-side PDA derivation:**
```typescript
const [configPDA, bump] = PublicKey.findProgramAddressSync(
  [Buffer.from("config"), authority.publicKey.toBuffer()],
  program.programId
);
```

**Key rules:**
- Each PDA seed ≤ 32 bytes, max 16 seeds
- `#[account(seeds = [...], bump)]` enforces canonical bump
- Store bump in account data at init for later verification
- `#[derive(InitSpace)]` auto-calculates space

---

### 1.2 State Management

Solana uses **account-based state** (not contract storage like EVM):

| EVM | Solana/Anchor |
|-----|---------------|
| `mapping(address => uint256) balances` | PDA account per user: `seeds = [b"user", user.key()]` |
| Contract storage | Separate account owned by program |
| `sload`/`sstore` | Account data read/write (borsh serialized) |
| Global singleton | Multiple PDAs with different seeds |

```rust
#[account]
pub struct Proposal {
    pub dao_config: Pubkey,      // which DAO this belongs to
    pub proposer: Pubkey,        // who created it
    pub title: String,           // #[max_len(64)]
    pub description: String,     // #[max_len(256)]
    pub yes_votes: u64,
    pub no_votes: u64,
    pub state: ProposalState,    // Active, Passed, Rejected, Executed
    pub bump: u8,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq)]
pub enum ProposalState {
    Active,
    Passed,
    Rejected,
    Executed,
}
```

---

### 1.3 Access Control

Solana has **no built-in `Ownable`**. Use PDAs + signer checks:

```rust
#[derive(Accounts)]
pub struct ExecuteProposal<'info> {
    #[account(
        mut,
        seeds = [b"proposal", config.key().as_ref(), &proposal.id.to_le_bytes()],
        bump = proposal.bump,
        has_one = config,
        constraint = proposal.state == ProposalState::Passed
            @ ErrorCode::ProposalNotPassed,
    )]
    pub proposal: Account<'info, Proposal>,

    #[account(
        seeds = [b"config"],
        bump = config.bump,
        has_one = authority,     // only DAO authority can execute
    )]
    pub config: Account<'info, DaoConfig>,

    pub authority: Signer<'info>,
}
```

**Common access control patterns:**

| EVM | Solana/Anchor |
|-----|---------------|
| `Ownable` / `onlyOwner` | `has_one = authority` on PDA account |
| Role-based (`hasRole`) | Multiple signer accounts or role PDAs |
| `msg.sender == owner` | `Signer<'info>` + `has_one` constraint |
| Multisig | Multiple `Signer` accounts required |
| Timelock | On-chain timestamp check + proposal state |

---

### 1.4 Token Interactions

**SPL Token (original):**
```rust
use anchor_spl::token::{self, Token, TokenAccount, Mint, Transfer};

#[derive(Accounts)]
pub struct StakeTokens<'info> {
    #[account(mut)]
    pub user_token_account: Account<'info, TokenAccount>,

    #[account(mut)]
    pub vault_token_account: Account<'info, TokenAccount>,

    pub user_authority: Signer<'info>,

    pub token_program: Program<'info, Token>,
}

pub fn stake_tokens(ctx: Context<StakeTokens>, amount: u64) -> Result<()> {
    let cpi_accounts = Transfer {
        from: ctx.accounts.user_token_account.to_account_info(),
        to: ctx.accounts.vault_token_account.to_account_info(),
        authority: ctx.accounts.user_authority.to_account_info(),
    };
    let cpi_program = ctx.accounts.token_program.to_account_info();
    token::transfer(CpiContext::new(cpi_program, cpi_accounts), amount)?;
    Ok(())
}
```

**Token-2022 (extensions):**
```rust
use anchor_spl::token_interface::{Token2022, TokenAccount, Mint, TransferChecked};

#[derive(Accounts)]
pub interface TransferTokens<'info> {
    #[account(mut)]
    pub from: InterfaceAccount<'info, TokenAccount>,
    #[account(mut)]
    pub to: InterfaceAccount<'info, TokenAccount>,
    pub authority: Signer<'info>,
    pub token_program: Program<'info, Token2022>,
}
```

**Token-2022 Extensions relevant to DAOs:**
- `non-transferable` — soulbound tokens (for membership/credentials)
- `transfer-fee` — automatic fee on transfer
- `default-account-state` — frozen by default (requires unfreeze)
- `metadata` — on-chain metadata (no Metaplex needed)
- `permanent-delegate` — program can always transfer

---

### 1.5 Cross-Program Invocations (CPI)

```rust
// CPI to SPL Token Program
use anchor_spl::token::{self, Token, Transfer};

pub fn transfer_via_cpi(ctx: Context<TransferTokens>, amount: u64) -> Result<()> {
    let cpi_accounts = Transfer {
        from: ctx.accounts.from.to_account_info(),
        to: ctx.accounts.to.to_account_info(),
        authority: ctx.accounts.authority.to_account_info(),
    };
    let cpi_program = ctx.accounts.token_program.to_account_info();
    token::transfer(CpiContext::new(cpi_program, cpi_accounts), amount)
}

// CPI with PDA signer (program signs on behalf of PDA)
pub fn transfer_from_pda(ctx: Context<TransferFromPda>, amount: u64) -> Result<()> {
    let seeds = &[b"vault".as_ref(), &[ctx.accounts.vault.bump]];
    let signer_seeds = &[&seeds[..]];

    let cpi_accounts = Transfer {
        from: ctx.accounts.vault.to_account_info(),
        to: ctx.accounts.recipient.to_account_info(),
        authority: ctx.accounts.vault.to_account_info(),
    };
    let cpi_program = ctx.accounts.token_program.to_account_info();
    token::transfer(
        CpiContext::new_with_signer(cpi_program, cpi_accounts, signer_seeds),
        amount,
    )
}
```

**CPI limits:**
- Max call depth: 4 levels (cross-program)
- Max stack depth: 64 layers
- Each CPI costs additional compute units

---

## 2. EVM → Solana Pattern Mapping

### 2.1 Token Standards

| EVM | Solana | Notes |
|-----|--------|-------|
| **ERC-20** | **SPL Token** / **Token-2022** | All tokens managed by single Token Program |
| **ERC-721** | **Metaplex NFTs** (Token Metadata) | Each NFT = SPL token with supply=1 |
| **ERC-1155** | **Metaplex compressed NFTs** | State compression for bulk NFTs |
| **ERC-4626** | Custom vault program | No standard equivalent |

### 2.2 Key Concept Mapping

| EVM Concept | Solana Equivalent |
|-------------|-------------------|
| `msg.sender` | `Signer<'info>` account |
| `msg.value` (SOL) | `SystemAccount` + lamports check, or SOL transfer via CPI |
| `require(condition, "msg")` | `require!(condition, ErrorCode::Variant)` or `assert_eq!` |
| Solidity `event` | `#[event]` struct + `emit!` macro |
| `mapping(K => V)` | PDA accounts with seed derivation |
| Dynamic arrays | `Vec<T>` in account with `#[max_len(N)]` |
| Contract address | Program ID |
| `address(this)` | `ctx.program_id` |
| `tx.origin` | First signer of transaction |
| `block.timestamp` | `Clock::get()?.unix_timestamp` |
| `block.number` | `Clock::get()?.slot` |
| Constructor | `#[account(init, ...)]` in first instruction |
| `selfdestruct` | `close` constraint on account |
| Inheritance | Composition via CPI calls |
| Interface | `InterfaceAccount<'info, T>` |
| `payable` | Check lamports in handler |
| `fallback()` | Not applicable |
| `receive()` | SOL deposit via `system_instruction::transfer` CPI |

### 2.3 Events vs Logs

```rust
// EVM Solidity
// event Transfer(address indexed from, address indexed to, uint256 value);
// emit Transfer(from, to, value);

// Solana Anchor
#[event]
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct TransferEvent {
    pub from: Pubkey,
    pub to: Pubkey,
    pub amount: u64,
}

// In instruction handler:
emit!(TransferEvent {
    from: ctx.accounts.sender.key(),
    to: ctx.accounts.recipient.key(),
    amount,
});
```

**Key difference:** Solana events are emitted as program log data (`sol_log_data`), not stored on-chain. Off-chain indexers (Helius, Shyft, etc.) parse logs.

### 2.4 Error Handling

```rust
// EVM Solidity
// require(amount > 0, "Amount must be positive");
// revert InsufficientBalance();

// Solana Anchor
#[error_code]
pub enum ErrorCode {
    #[msg("Amount must be positive")]
    InvalidAmount,

    #[msg("Insufficient balance")]
    InsufficientBalance,

    #[msg("Unauthorized")]
    Unauthorized,

    #[msg("Proposal not passed")]
    ProposalNotPassed,
}

// Usage
require!(amount > 0, ErrorCode::InvalidAmount);
```

### 2.5 Account Sizes (rent planning)

| Account Type | Size | Notes |
|-------------|------|-------|
| Discriminator | 8 bytes | Prepend to all Anchor accounts |
| `Pubkey` | 32 bytes | |
| `u64` / `i64` | 8 bytes | |
| `bool` | 1 byte | |
| `String` | 4 + N bytes | 4-byte length prefix + data |
| `Vec<T>` | 4 + N * size_of(T) | 4-byte length prefix |
| `Enum` | 1 + variant_size | 1-byte tag |

**Rent exemption minimum (June 2025):**
```rust
// Calculate rent-exempt amount
let rent = Rent::get()?;
let min_lamports = rent.minimum_balance(account_size);

// Or use InitSpace for auto-calculation
#[account(init, payer = payer, space = 8 + MyAccount::INIT_SPACE)]
```

---

## 3. Solana Transaction Limits

| Limit | Value | Source |
|-------|-------|--------|
| **Max transaction size** | **1,232 bytes** | IPv6 MTU - headers |
| **Max accounts per tx** | 64 (128 w/ lookup tables) | Protocol limit |
| **Max signatures** | 12 | Ed25519 (64 bytes each) |
| **Base fee** | 5,000 lamports/signature | Fixed |
| **Max CU per tx** | **1,400,000** | Compute budget |
| **Default CU per instruction** | 200,000 | |
| **Max CU per block** | 48,000,000 | |
| **Max CU per user per block** | 12,000,000 | |
| **Max account data size** | 10 MB | Per account |
| **Max PDA seed length** | 32 bytes | |
| **Max PDA seeds** | 16 | |
| **Blockhash expiry** | 150 slots | ~1 minute |
| **Stack size** | 4 KB per frame | |
| **Heap size** | 32 KB | |

### Priority Fees

```
Priority Fee = Compute Unit Limit × Compute Unit Price (in micro-lamports)
```

```typescript
// Set compute budget
import { ComputeBudgetProgram } from "@solana/web3.js";

const instructions = [
  ComputeBudgetProgram.setComputeUnitLimit({ units: 200_000 }),
  ComputeBudgetProgram.setComputeUnitPrice({ microLamports: 50_000 }),
  // ... your instruction
];
```

### Transaction Size Workaround

For data-heavy operations, use **write-account helper program** or **state compression** (Merkle tree + concurrent merkle proofs) to exceed 1232 bytes per logical transaction.

---

## 4. DAO Governance on Solana — Existing Projects

### 4.1 SPL Governance (Realms)

**Program:** `GovER5Lthms3bLBqWub97yVrMmEogzX7xNjdXpPPCVZw`

The canonical on-chain governance framework. Now managed by **Realms Today Trust** (separated from Solana Labs at Breakpoint 2024).

**Architecture:**
```
Realm
├── Governance (one per governed asset)
│   ├── Config (voting thresholds, timelocks)
│   ├── Proposals
│   │   ├── Proposal Signoffs
│   │   ├── Votes (Yes/No/Abstain)
│   │   └── Execution Instructions
│   └── Native Treasury (DAO wallet, PDA)
├── Community Token (governance token)
└── Council Token (optional multisig)
```

**Key accounts (on-chain):**
- **Realm** — top-level container for a DAO
- **Governance** — config per governed asset (token, program, mint)
- **Proposal** — individual governance proposal
- **TokenOwnerRecord** — tracks a voter's token balance & votes
- **NativeTreasury** — DAO's SOL wallet (PDA)

**Voting flow:**
1. Create proposal (requires token holdings above threshold)
2. Signoff by council (if council exists)
3. Community voting (token-weighted)
4. Execution after timelock

**Integration via Anchor CPI:**
```rust
use anchor_spl::governance::Governance;

// CPI to SPL Governance to create proposal
let cpi_accounts = governance::cpi::accounts::CreateProposal {
    governance: governance_account,
    proposal: proposal_account,
    token_owner_record: voter_record,
    governing_token_mint: community_mint,
    payer: payer,
    system_program: system_program,
};
```

### 4.2 Realms Today

- **URL:** https://realms.today
- **Frontend:** React app for DAO creation and governance
- **Features:** Multisig DAO, token-weighted DAO, NFT DAO, program governance
- **New:** DAO credit cards, Realms Accelerator, R.E.D. grants ($200K)
- **Legal:** Developing DAO incorporation services (Trust + bank accounts)

### 4.3 Tribeca

Alternative governance framework with:
- **Governor** — proposal tracking and voting
- **Goki Smart Wallet** — multisig execution
- **Electorate** — customizable voting mechanism

### 4.4 Other Governance Tools

| Project | Type | Notes |
|---------|------|-------|
| **Switchboard** | Oracle | Decentralized data feeds, not governance per se |
| **Goblin Gold** | DAO tooling | Lightweight governance |
| **Squads** | Multisig | Programmable multisig (used by many DAOs) |
| **Jupiter DAO** | DAO | Most engaged DAO by voter participation on Solana |

---

## 5. Islamic Finance / Zakat DAOs on Solana

### Existing Projects

| Project | Chain | Notes |
|---------|-------|-------|
| **M.Sharia ($MSHA)** | Own chain | Shariah-compliant DAO, zakat automation, 350K+ users. Telegram mini-game onboarding |
| **Islamic Coin (ISLM)** | **HAQQ Network** | Fatwa-approved. 10% of minted coins → Evergreen DAO for charity. Sharia board with 40+ banks |
| **Haqq Network** | Cosmos-based | Sharia-compliant L1. Blocks interest/gambling projects |

**No known Zakat/Islamic finance DAOs on Solana specifically.** This is a greenfield opportunity.

**For your DAO (Tawf):**
- IDRX (Indonesian Rupiah stablecoin) is already on Solana: `idrxTdNftk6tYedPv2M7tCFHBVCpk5rkiNRd8yUArhr`
- SPL Governance via Realms provides the governance infrastructure
- Custom Zakat calculation logic can be on-chain program
- Use Token-2022 `non-transferable` extension for membership credentials
- Soulbound NFTs for contributor badges/reputation

---

## 6. IDRX on Solana

### Token Details

| Field | Value |
|-------|-------|
| **Mint Address** | `idrxTdNftk6tYedPv2M7tCFHBVCpk5rkiNRd8yUArhr` |
| **Program** | SPL Token or Token-2022 |
| **Decimals** | Likely 6 (IDR stablecoin) |
| **Networks** | Polygon, BNB, Solana, Base, Gnosis |

### Integration Pattern

```rust
use anchor_spl::token::{Token, TokenAccount, Mint};

// IDRX mint constant
declare_id!("idrxTdNftk6tYedPv2M7tCFHBVCpk5rkiNRd8yUArhr");

#[derive(Accounts)]
pub struct DonateZakat<'info> {
    #[account(mut)]
    pub donor_idrx_account: Account<'info, TokenAccount>,

    #[account(mut)]
    pub zakat_vault: Account<'info, TokenAccount>,

    pub idrx_mint: Account<'info, Mint>,

    #[account(
        mut,
        constraint = donor_authority.key() == donor_idrx_account.owner
    )]
    pub donor_authority: Signer<'info>,

    pub token_program: Program<'info, Token>,
}

pub fn donate_zakat(ctx: Context<DonateZakat>, amount: u64) -> Result<()> {
    // Verify the mint is IDRX
    require!(
        ctx.accounts.idrx_mint.key() == idrx::ID::id(),
        ErrorCode::InvalidMint
    );

    let cpi_accounts = Transfer {
        from: ctx.accounts.donor_idrx_account.to_account_info(),
        to: ctx.accounts.zakat_vault.to_account_info(),
        authority: ctx.accounts.donor_authority.to_account_info(),
    };
    token::transfer(
        CpiContext::new(ctx.accounts.token_program.to_account_info(), cpi_accounts),
        amount,
    )?;

    emit!(ZakatDonation {
        donor: ctx.accounts.donor_authority.key(),
        amount,
        timestamp: Clock::get()?.unix_timestamp,
    });

    Ok(())
}
```

**Client-side (TypeScript):**
```typescript
import { Program, AnchorProvider } from "@coral-xyz/anchor";
import { TOKEN_PROGRAM_ID } from "@solana/spl-token";

const IDRX_MINT = new PublicKey("idrxTdNftk6tYedPv2M7tCFHBVCpk5rkiNRd8yUArhr");

// Derive vault PDA
const [vaultPDA] = PublicKey.findProgramAddressSync(
  [Buffer.from("zakat_vault")],
  program.programId
);

// User's IDRX ATA
const userATA = getAssociatedTokenAddressSync(IDRX_MINT, userWallet);

await program.methods
  .donateZakat(new anchor.BN(amount * 1e6)) // 6 decimals
  .accounts({
    donorIdrxAccount: userATA,
    zakatVault: vaultPDA,
    idrxMint: IDRX_MINT,
    donorAuthority: userWallet,
    tokenProgram: TOKEN_PROGRAM_ID,
  })
  .rpc();
```

---

## 7. Recommended Architecture for Tawf DAO

```
┌─────────────────────────────────────────────────┐
│                    FRONTEND                      │
│  React/Next.js + @solana/web3.js + wallet-adapter│
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────┐
│              GOVERNANCE LAYER                     │
│  SPL Governance (Realms) or Custom Anchor Program│
│  - Proposal creation                             │
│  - Token-weighted voting                         │
│  - Timelock execution                            │
│  - Council multisig                              │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────┐
│              TREASURY LAYER                       │
│  PDA vaults for SOL + IDRX + other tokens        │
│  - Zakat vault (auto-calculation)                │
│  - Community grants vault                        │
│  - Operations vault                              │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────┐
│              TOKEN LAYER                          │
│  IDRX: idrxTdNftk6tYedPv2M7tCFHBVCpk5rkiNRd8yUArhr │
│  Governance token: Custom SPL/Token-2022          │
│  Membership: Token-2022 non-transferable          │
└─────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **Governance:** Start with SPL Governance (battle-tested), fork if custom logic needed
2. **Treasury:** PDA vaults with multi-sig authority for high-value operations
3. **Zakat:** Custom on-chain calculator using IDRX, with automatic distribution
4. **Membership:** Token-2022 non-transferable tokens for contributor credentials
5. **Transparency:** All governance on-chain, real-time dashboard via indexer

---

## 8. Quick Reference Cheat Sheet

```
EVM                          SOLANA
─────────────────────────────────────────────
contract deploy              program deploy (anchor deploy)
constructor                  #[account(init, ...)]
mapping[key]                 PDA with seeds
require(x > 0)               require!(x > 0, ErrorCode::X)
emit Event                   emit!(Event { ... })
msg.sender                   Signer<'info>
msg.value                    lamports / system transfer CPI
Ownable                       has_one = owner constraint
ERC20.transfer()             SPL Token CPI transfer()
ERC721                       Metaplex / MPL Core
tx.origin                    First signer in transaction
fallback()                   N/A
selfdestruct                 close constraint
block.timestamp              Clock::get()?.unix_timestamp
immutable variables          Constants / static seeds
library/inheritance          CPI composition
OpenZeppelin                 anchor-spl / Metaplex
Hardhat/Foundry              Anchor CLI + anchor test
ethers.js / viem             @coral-xyz/anchor / @solana/web3.js
OpenZeppelin upgrades        BPF Upgradeable Loader (program upgrade)
```
