use anchor_lang::prelude::*;
use anchor_spl::token_interface::{self, Mint, TokenAccount, TransferChecked, TokenInterface};

declare_id!("GAT3Cc9Aw7wuyZmWvdE37fjnCsPUsjt969Ekwng1xhvZ");

const MAX_DONORS: usize = 100;
const MAX_TITLE: usize = 200;

#[account]
pub struct CampaignPool {
    pub pool_id: u64,
    pub proposal: Pubkey,
    pub organizer: Pubkey,
    pub idrx_mint: Pubkey,
    pub funding_goal: u64,
    pub raised_amount: u64,
    pub is_active: bool,
    pub uses_milestones: bool,
    pub funds_withdrawn: bool,
    pub bump: u8,
}

impl CampaignPool {
    pub const SPACE: usize = 8 + 8 + 32 + 32 + 32 + 8 + 8 + 1 + 1 + 1 + 1;
}

#[account]
pub struct DonorRecord {
    pub donor: Pubkey,
    pub pool: Pubkey,
    pub amount: u64,
    pub bump: u8,
}

impl DonorRecord {
    pub const SPACE: usize = 8 + 32 + 32 + 8 + 1;
}

#[program]
pub mod pool_manager {
    use super::*;

    pub fn create_pool(
        ctx: Context<CreatePool>,
        funding_goal: u64,
        uses_milestones: bool,
    ) -> Result<()> {
        require!(funding_goal > 0, PoolError::ZeroGoal);

        let pool = &mut ctx.accounts.pool;
        pool.organizer = ctx.accounts.organizer.key();
        pool.proposal = ctx.accounts.proposal.key();
        pool.idrx_mint = ctx.accounts.idrx_mint.key();
        pool.funding_goal = funding_goal;
        pool.raised_amount = 0;
        pool.is_active = true;
        pool.uses_milestones = uses_milestones;
        pool.funds_withdrawn = false;
        pool.bump = ctx.bumps.pool;

        emit!(PoolCreated {
            pool_id: ctx.accounts.pool.pool_id,
            organizer: ctx.accounts.organizer.key(),
        });
        Ok(())
    }

    pub fn donate(ctx: Context<Donate>, amount: u64) -> Result<()> {
        require!(ctx.accounts.pool.is_active, PoolError::PoolNotActive);
        require!(amount > 0, PoolError::ZeroDonation);

        let pool = &mut ctx.accounts.pool;

        let signer_seeds: &[&[&[u8]]] = &[&[b"pool", pool.organizer.as_ref(), &[pool.bump]]];

        let cpi_accounts = TransferChecked {
            from: ctx.accounts.donor_ata.to_account_info(),
            mint: ctx.accounts.idrx_mint.to_account_info(),
            to: ctx.accounts.pool_vault.to_account_info(),
            authority: ctx.accounts.donor.to_account_info(),
        };
        let cpi_ctx = CpiContext::new(ctx.accounts.token_program.to_account_info(), cpi_accounts);
        token_interface::transfer_checked(cpi_ctx, amount, 6)?;

        pool.raised_amount = pool.raised_amount.checked_add(amount).unwrap();

        let donor_record = &mut ctx.accounts.donor_record;
        donor_record.donor = ctx.accounts.donor.key();
        donor_record.pool = pool.key();
        donor_record.amount = donor_record.amount.checked_add(amount).unwrap();
        donor_record.bump = ctx.bumps.donor_record;

        emit!(DonationReceived {
            donor: ctx.accounts.donor.key(),
            pool_id: pool.pool_id,
            amount,
        });
        Ok(())
    }

    pub fn withdraw_funds(ctx: Context<WithdrawFunds>) -> Result<()> {
        let pool = &mut ctx.accounts.pool;
        require!(pool.is_active, PoolError::PoolNotActive);
        require!(!pool.funds_withdrawn, PoolError::AlreadyWithdrawn);
        require!(pool.raised_amount > 0, PoolError::NoFunds);
        require!(!pool.uses_milestones, PoolError::UseMilestoneWithdraw);
        require!(pool.raised_amount >= pool.funding_goal, PoolError::GoalNotMet);

        pool.funds_withdrawn = true;
        pool.is_active = false;

        let signer_seeds: &[&[&[u8]]] = &[&[b"pool", pool.organizer.as_ref(), &[pool.bump]]];

        let cpi_accounts = TransferChecked {
            from: ctx.accounts.pool_vault.to_account_info(),
            mint: ctx.accounts.idrx_mint.to_account_info(),
            to: ctx.accounts.organizer_ata.to_account_info(),
            authority: ctx.accounts.pool_vault.to_account_info(),
        };
        let cpi_ctx = CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            cpi_accounts,
            signer_seeds,
        );
        token_interface::transfer_checked(cpi_ctx, pool.raised_amount, 6)?;

        emit!(FundsWithdrawn {
            pool_id: pool.pool_id,
            amount: pool.raised_amount,
        });
        Ok(())
    }
}

#[derive(Accounts)]
pub struct CreatePool<'info> {
    #[account(mut)]
    pub admin: Signer<'info>,
    /// CHECK: proposal account, validated by program logic
    pub proposal: AccountInfo<'info>,
    pub idrx_mint: InterfaceAccount<'info, Mint>,
    /// CHECK: organizer may not be a signer
    pub organizer: AccountInfo<'info>,
    #[account(
        init,
        seeds = [b"pool", organizer.key().as_ref()],
        bump,
        payer = admin,
        space = CampaignPool::SPACE,
    )]
    pub pool: Account<'info, CampaignPool>,
    pub system_program: Program<'info, System>,
    pub token_program: Interface<'info, TokenInterface>,
}

#[derive(Accounts)]
pub struct Donate<'info> {
    #[account(mut)]
    pub donor: Signer<'info>,
    #[account(mut)]
    pub pool: Account<'info, CampaignPool>,
    pub idrx_mint: InterfaceAccount<'info, Mint>,
    #[account(mut)]
    pub donor_ata: InterfaceAccount<'info, TokenAccount>,
    /// CHECK: pool vault, a PDA holding donated IDRX
    #[account(mut)]
    pub pool_vault: AccountInfo<'info>,
    #[account(
        init,
        seeds = [b"donor", pool.key().as_ref(), donor.key().as_ref()],
        bump,
        payer = donor,
        space = DonorRecord::SPACE,
    )]
    pub donor_record: Account<'info, DonorRecord>,
    pub token_program: Interface<'info, TokenInterface>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct WithdrawFunds<'info> {
    pub caller: Signer<'info>,
    #[account(mut)]
    pub pool: Account<'info, CampaignPool>,
    pub idrx_mint: InterfaceAccount<'info, Mint>,
    /// CHECK: pool vault PDA
    #[account(mut)]
    pub pool_vault: AccountInfo<'info>,
    #[account(mut)]
    pub organizer_ata: InterfaceAccount<'info, TokenAccount>,
    pub token_program: Interface<'info, TokenInterface>,
}

#[event]
pub struct PoolCreated {
    pub pool_id: u64,
    pub organizer: Pubkey,
}

#[event]
pub struct DonationReceived {
    pub donor: Pubkey,
    pub pool_id: u64,
    pub amount: u64,
}

#[event]
pub struct FundsWithdrawn {
    pub pool_id: u64,
    pub amount: u64,
}

#[error_code]
pub enum PoolError {
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
    #[msg("Use withdrawMilestoneFunds for milestone campaigns")]
    UseMilestoneWithdraw,
    #[msg("Funding goal not met")]
    GoalNotMet,
}
