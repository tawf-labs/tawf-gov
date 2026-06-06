use anchor_lang::prelude::*;
use anchor_spl::token_interface::{self, Mint, TokenAccount, TransferChecked, TokenInterface};

declare_id!("6ANXqsFLDfiPzuodehSvtYhc6T9JwU26B5X7zji1TRXF");

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq)]
pub enum ZakatPoolStatus {
    Active,
    GracePeriod,
    Redistributed,
    Completed,
}

#[account]
pub struct ZakatPool {
    pub pool_id: u64,
    pub proposal: Pubkey,
    pub organizer: Pubkey,
    pub idrx_mint: Pubkey,
    pub funding_goal: u64,
    pub raised_amount: u64,
    pub created_at: i64,
    pub deadline: i64,
    pub grace_period_end: i64,
    pub status: ZakatPoolStatus,
    pub extension_used: bool,
    pub fallback_recipient: Pubkey,
    pub funds_withdrawn: bool,
    pub bump: u8,
}

impl ZakatPool {
    pub const SPACE: usize = 8 + 8 + 32 + 32 + 32 + 8 + 8 + 8 + 8 + 8 + 1 + 1 + 32 + 1 + 1;
}

#[program]
pub mod zakat_escrow {
    use super::*;

    pub fn create_zakat_pool(ctx: Context<CreateZakatPool>, funding_goal: u64) -> Result<()> {
        require!(funding_goal > 0, ZakatError::ZeroGoal);

        let pool = &mut ctx.accounts.pool;
        let clock = Clock::get()?;

        pool.organizer = ctx.accounts.organizer.key();
        pool.proposal = ctx.accounts.proposal.key();
        pool.idrx_mint = ctx.accounts.idrx_mint.key();
        pool.funding_goal = funding_goal;
        pool.raised_amount = 0;
        pool.created_at = clock.unix_timestamp;
        pool.deadline = clock.unix_timestamp + 30 * 86400;
        pool.grace_period_end = pool.deadline + 7 * 86400;
        pool.status = ZakatPoolStatus::Active;
        pool.extension_used = false;
        pool.fallback_recipient = Pubkey::default();
        pool.funds_withdrawn = false;
        pool.bump = ctx.bumps.pool;

        emit!(ZakatPoolCreated {
            pool_id: pool.pool_id,
            organizer: ctx.accounts.organizer.key(),
        });
        Ok(())
    }

    pub fn donate(ctx: Context<DonateZakat>, amount: u64) -> Result<()> {
        let pool = &mut ctx.accounts.pool;
        require!(pool.status == ZakatPoolStatus::Active, ZakatError::PoolNotActive);
        require!(amount > 0, ZakatError::ZeroDonation);

        let cpi_accounts = TransferChecked {
            from: ctx.accounts.donor_ata.to_account_info(),
            mint: ctx.accounts.idrx_mint.to_account_info(),
            to: ctx.accounts.pool_vault.to_account_info(),
            authority: ctx.accounts.donor.to_account_info(),
        };
        let cpi_ctx = CpiContext::new(ctx.accounts.token_program.key(), cpi_accounts);
        token_interface::transfer_checked(cpi_ctx, amount, 6)?;

        pool.raised_amount = pool.raised_amount.checked_add(amount).unwrap();

        emit!(ZakatDonationReceived {
            donor: ctx.accounts.donor.key(),
            pool_id: pool.pool_id,
            amount,
        });
        Ok(())
    }

    pub fn withdraw(ctx: Context<WithdrawZakat>) -> Result<()> {
        let pool = &mut ctx.accounts.pool;
        require!(pool.status == ZakatPoolStatus::Active, ZakatError::PoolNotActive);
        require!(!pool.funds_withdrawn, ZakatError::AlreadyWithdrawn);
        require!(pool.raised_amount > 0, ZakatError::NoFunds);

        let clock = Clock::get()?;
        require!(clock.unix_timestamp <= pool.deadline, ZakatError::PastDeadline);

        pool.funds_withdrawn = true;
        pool.status = ZakatPoolStatus::Completed;

        let signer_seeds: &[&[&[u8]]] = &[&[b"zakat", pool.organizer.as_ref(), &[pool.bump]]];

        let cpi_accounts = TransferChecked {
            from: ctx.accounts.pool_vault.to_account_info(),
            mint: ctx.accounts.idrx_mint.to_account_info(),
            to: ctx.accounts.recipient_ata.to_account_info(),
            authority: ctx.accounts.pool_vault.to_account_info(),
        };
        let cpi_ctx = CpiContext::new_with_signer(
            ctx.accounts.token_program.key(),
            cpi_accounts,
            signer_seeds,
        );
        token_interface::transfer_checked(cpi_ctx, pool.raised_amount, 6)?;

        emit!(ZakatWithdrawn {
            pool_id: pool.pool_id,
            amount: pool.raised_amount,
        });
        Ok(())
    }
}

#[derive(Accounts)]
pub struct CreateZakatPool<'info> {
    #[account(mut)]
    pub admin: Signer<'info>,
    /// CHECK: proposal account
    pub proposal: UncheckedAccount<'info>,
    pub idrx_mint: InterfaceAccount<'info, Mint>,
    /// CHECK: organizer
    pub organizer: UncheckedAccount<'info>,
    #[account(
        init,
        seeds = [b"zakat", organizer.key().as_ref()],
        bump,
        payer = admin,
        space = ZakatPool::SPACE,
    )]
    pub pool: Account<'info, ZakatPool>,
    pub system_program: Program<'info, System>,
    pub token_program: Interface<'info, TokenInterface>,
}

#[derive(Accounts)]
pub struct DonateZakat<'info> {
    #[account(mut)]
    pub donor: Signer<'info>,
    #[account(mut)]
    pub pool: Account<'info, ZakatPool>,
    pub idrx_mint: InterfaceAccount<'info, Mint>,
    #[account(mut)]
    pub donor_ata: InterfaceAccount<'info, TokenAccount>,
    /// CHECK: pool vault
    #[account(mut)]
    pub pool_vault: UncheckedAccount<'info>,
    pub token_program: Interface<'info, TokenInterface>,
}

#[derive(Accounts)]
pub struct WithdrawZakat<'info> {
    pub caller: Signer<'info>,
    #[account(mut)]
    pub pool: Account<'info, ZakatPool>,
    pub idrx_mint: InterfaceAccount<'info, Mint>,
    /// CHECK: pool vault
    #[account(mut)]
    pub pool_vault: UncheckedAccount<'info>,
    #[account(mut)]
    pub recipient_ata: InterfaceAccount<'info, TokenAccount>,
    pub token_program: Interface<'info, TokenInterface>,
}

#[event]
pub struct ZakatPoolCreated {
    pub pool_id: u64,
    pub organizer: Pubkey,
}

#[event]
pub struct ZakatDonationReceived {
    pub donor: Pubkey,
    pub pool_id: u64,
    pub amount: u64,
}

#[event]
pub struct ZakatWithdrawn {
    pub pool_id: u64,
    pub amount: u64,
}

#[error_code]
pub enum ZakatError {
    #[msg("Funding goal must be > 0")]
    ZeroGoal,
    #[msg("Pool is not active")]
    PoolNotActive,
    #[msg("Donation amount must be > 0")]
    ZeroDonation,
    #[msg("Funds already withdrawn")]
    AlreadyWithdrawn,
    #[msg("No funds available")]
    NoFunds,
    #[msg("Past deadline - funds must be redistributed")]
    PastDeadline,
}
