use anchor_lang::prelude::*;
use anchor_spl::token_interface::{self, Mint, TokenAccount, TransferChecked, TokenInterface};

declare_id!("HaYfHVmSpTwrydoP4fX8yZDsEbkuiA1NW7aUvFmLG6gg");

#[account]
pub struct Allocation {
    pub id: u64,
    pub recipient: Pubkey,
    pub amount: u64,
    pub purpose: String,
    pub executed: bool,
    pub created_at: i64,
    pub bump: u8,
}

impl Allocation {
    pub const SPACE: usize = 8 + 8 + 32 + 8 + 4 + 256 + 1 + 8 + 1;
}

#[account]
pub struct Treasury {
    pub idrx_mint: Pubkey,
    pub total_allocated: u64,
    pub bump: u8,
}

impl Treasury {
    pub const SPACE: usize = 8 + 32 + 8 + 1;
}

#[program]
pub mod wakaf_treasury {
    use super::*;

    pub fn initialize(ctx: Context<InitializeTreasury>) -> Result<()> {
        let treasury = &mut ctx.accounts.treasury;
        treasury.idrx_mint = ctx.accounts.idrx_mint.key();
        treasury.total_allocated = 0;
        treasury.bump = ctx.bumps.treasury;
        Ok(())
    }

    pub fn create_allocation(
        ctx: Context<CreateAllocation>,
        id: u64,
        recipient: Pubkey,
        amount: u64,
        purpose: String,
    ) -> Result<()> {
        require!(amount > 0, TreasuryError::ZeroAmount);
        require!(purpose.len() <= 256, TreasuryError::PurposeTooLong);

        let allocation = &mut ctx.accounts.allocation;
        allocation.id = id;
        allocation.recipient = recipient;
        allocation.amount = amount;
        allocation.purpose = purpose;
        allocation.executed = false;
        allocation.created_at = Clock::get()?.unix_timestamp;
        allocation.bump = ctx.bumps.allocation;

        let treasury = &mut ctx.accounts.treasury;
        treasury.total_allocated = treasury.total_allocated.checked_add(amount).unwrap();

        emit!(AllocationCreated { id, recipient, amount });
        Ok(())
    }

    pub fn execute_allocation(ctx: Context<ExecuteAllocation>) -> Result<()> {
        let allocation = &mut ctx.accounts.allocation;
        require!(!allocation.executed, TreasuryError::AlreadyExecuted);

        let treasury = &mut ctx.accounts.treasury;
        treasury.total_allocated = treasury.total_allocated.checked_sub(allocation.amount).unwrap();
        allocation.executed = true;

        let bump = treasury.bump;
        let signer_seeds: &[&[&[u8]]] = &[&[b"treasury-vault", &[bump]]];

        let cpi_accounts = TransferChecked {
            from: ctx.accounts.treasury_vault.to_account_info(),
            mint: ctx.accounts.idrx_mint.to_account_info(),
            to: ctx.accounts.recipient_ata.to_account_info(),
            authority: ctx.accounts.treasury_vault.to_account_info(),
        };
        let cpi_ctx = CpiContext::new_with_signer(
            ctx.accounts.token_program.key(),
            cpi_accounts,
            signer_seeds,
        );
        token_interface::transfer_checked(cpi_ctx, allocation.amount, 6)?;

        emit!(AllocationExecuted { id: allocation.id, recipient: allocation.recipient, amount: allocation.amount });
        Ok(())
    }
}

#[derive(Accounts)]
pub struct InitializeTreasury<'info> {
    #[account(mut)]
    pub admin: Signer<'info>,
    pub idrx_mint: InterfaceAccount<'info, Mint>,
    #[account(
        init,
        seeds = [b"treasury"],
        bump,
        payer = admin,
        space = Treasury::SPACE,
    )]
    pub treasury: Account<'info, Treasury>,
    pub system_program: Program<'info, System>,
    pub token_program: Interface<'info, TokenInterface>,
}

#[derive(Accounts)]
#[instruction(id: u64)]
pub struct CreateAllocation<'info> {
    #[account(mut)]
    pub allocator: Signer<'info>,
    #[account(
        mut,
        seeds = [b"treasury"],
        bump = treasury.bump,
    )]
    pub treasury: Account<'info, Treasury>,
    /// CHECK: recipient account
    pub recipient: UncheckedAccount<'info>,
    #[account(
        init,
        seeds = [b"allocation", id.to_le_bytes().as_ref()],
        bump,
        payer = allocator,
        space = Allocation::SPACE,
    )]
    pub allocation: Account<'info, Allocation>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct ExecuteAllocation<'info> {
    pub executor: Signer<'info>,
    #[account(
        mut,
        seeds = [b"treasury"],
        bump = treasury.bump,
    )]
    pub treasury: Account<'info, Treasury>,
    #[account(mut)]
    pub idrx_mint: InterfaceAccount<'info, Mint>,
    /// CHECK: treasury vault PDA
    #[account(mut)]
    pub treasury_vault: UncheckedAccount<'info>,
    #[account(mut)]
    pub recipient_ata: InterfaceAccount<'info, TokenAccount>,
    #[account(mut)]
    pub allocation: Account<'info, Allocation>,
    pub token_program: Interface<'info, TokenInterface>,
}

#[event]
pub struct AllocationCreated {
    pub id: u64,
    pub recipient: Pubkey,
    pub amount: u64,
}

#[event]
pub struct AllocationExecuted {
    pub id: u64,
    pub recipient: Pubkey,
    pub amount: u64,
}

#[error_code]
pub enum TreasuryError {
    #[msg("Amount must be > 0")]
    ZeroAmount,
    #[msg("Purpose too long")]
    PurposeTooLong,
    #[msg("Allocation already executed")]
    AlreadyExecuted,
}
