use anchor_lang::prelude::*;
use anchor_spl::token_interface::{self, Mint, MintTo, TokenAccount, TokenInterface};

declare_id!("84qrLb5tLKCFUXJ1NDhKvp73dLLEi3e5LURZ9cDUEjom");

/// IDRX Mock Token. Dev-only SPL token simulating IDRX (6 decimals).
/// Authority is a fixed PDA so any wallet can call `mint_to` for testing.
#[program]
pub mod idrx_mock {
    use super::*;

    pub fn initialize_mint(ctx: Context<InitializeMint>) -> Result<()> {
        msg!("IDRX Mock Mint: {}", ctx.accounts.mint.key());
        Ok(())
    }

    pub fn mint_to(ctx: Context<MintTokens>, amount: u64) -> Result<()> {
        let bumps = ctx.bumps;
        let signer_seeds: &[&[&[u8]]] = &[&[b"idrx-authority", &[bumps.mint_authority]]];

        let cpi_accounts = MintTo {
            mint: ctx.accounts.mint.to_account_info(),
            to: ctx.accounts.recipient_token_account.to_account_info(),
            authority: ctx.accounts.mint_authority.to_account_info(),
        };
        let cpi_ctx = CpiContext::new_with_signer(
            ctx.accounts.token_program.key(),
            cpi_accounts,
            signer_seeds,
        );
        token_interface::mint_to(cpi_ctx, amount)?;

        msg!("Minted {} IDRX → {}", amount, ctx.accounts.recipient_token_account.key());
        Ok(())
    }
}

#[derive(Accounts)]
pub struct InitializeMint<'info> {
    #[account(mut)]
    pub payer: Signer<'info>,

    /// IDRX mock mint (6 decimals). Seeds = ["idrx-mint"].
    #[account(
        init,
        seeds = [b"idrx-mint"],
        bump,
        payer = payer,
        mint::decimals = 6,
        mint::authority = mint_authority,
    )]
    pub mint: InterfaceAccount<'info, Mint>,

    /// Fixed PDA mint authority. Seeds = ["idrx-authority"].
    /// CHECK: PDA validated by seeds; owns the mint.
    #[account(seeds = [b"idrx-authority"], bump)]
    pub mint_authority: UncheckedAccount<'info>,

    pub system_program: Program<'info, System>,
    pub token_program: Interface<'info, TokenInterface>,
    pub rent: Sysvar<'info, Rent>,
}

#[derive(Accounts)]
pub struct MintTokens<'info> {
    /// Any signer can invoke mint_to; authority is the PDA.
    pub authority: Signer<'info>,

    /// IDRX mock mint. Mutable, so supply increases.
    #[account(mut, seeds = [b"idrx-mint"], bump)]
    pub mint: InterfaceAccount<'info, Mint>,

    /// Fixed PDA mint authority.
    /// CHECK: PDA validated by seeds; signs via invoke_signed.
    #[account(seeds = [b"idrx-authority"], bump)]
    pub mint_authority: UncheckedAccount<'info>,

    /// Recipient token account (must be ATA for `mint`).
    #[account(mut, token::mint = mint)]
    pub recipient_token_account: InterfaceAccount<'info, TokenAccount>,

    pub token_program: Interface<'info, TokenInterface>,
}
