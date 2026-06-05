use anchor_lang::prelude::*;

declare_id!("5EVbuidmVDXAWwn6RpXB9D3By8xB8Thbv8VfuiahD4Bb");

const MAX_URI: usize = 256;

#[account]
pub struct DonationReceipt {
    pub token_id: u64,
    pub donor: Pubkey,
    pub pool_id: u64,
    pub amount: u64,
    pub campaign_title: String,
    pub campaign_type: String,
    pub metadata_uri: String,
    pub created_at: i64,
    pub bump: u8,
}

impl DonationReceipt {
    pub const SPACE: usize = 8 + 8 + 32 + 8 + 8 + 4 + 200 + 4 + 50 + 4 + MAX_URI + 8 + 1;
}

#[program]
pub mod donation_receipt_nft {
    use super::*;

    pub fn mint_receipt(
        ctx: Context<MintReceipt>,
        pool_id: u64,
        amount: u64,
        campaign_title: String,
        campaign_type: String,
        metadata_uri: String,
    ) -> Result<()> {
        require!(amount > 0, ReceiptError::ZeroAmount);
        require!(campaign_title.len() <= 200, ReceiptError::TitleTooLong);
        require!(campaign_type.len() <= 50, ReceiptError::TypeTooLong);
        require!(metadata_uri.len() <= MAX_URI, ReceiptError::UriTooLong);

        let receipt = &mut ctx.accounts.receipt;
        receipt.donor = ctx.accounts.donor.key();
        receipt.pool_id = pool_id;
        receipt.amount = amount;
        receipt.campaign_title = campaign_title;
        receipt.campaign_type = campaign_type;
        receipt.metadata_uri = metadata_uri;
        receipt.created_at = Clock::get()?.unix_timestamp;
        receipt.bump = ctx.bumps.receipt;

        emit!(ReceiptMinted {
            token_id: receipt.token_id,
            donor: ctx.accounts.donor.key(),
            pool_id,
            amount,
        });
        Ok(())
    }
}

#[derive(Accounts)]
#[instruction(pool_id: u64)]
pub struct MintReceipt<'info> {
    #[account(mut)]
    pub minter: Signer<'info>,
    /// CHECK: donor may not be a signer
    pub donor: AccountInfo<'info>,
    #[account(
        init,
        seeds = [b"receipt", donor.key().as_ref(), &pool_id.to_le_bytes()],
        bump,
        payer = minter,
        space = DonationReceipt::SPACE,
    )]
    pub receipt: Account<'info, DonationReceipt>,
    pub system_program: Program<'info, System>,
}

#[event]
pub struct ReceiptMinted {
    pub token_id: u64,
    pub donor: Pubkey,
    pub pool_id: u64,
    pub amount: u64,
}

#[error_code]
pub enum ReceiptError {
    #[msg("Amount must be > 0")]
    ZeroAmount,
    #[msg("Campaign title too long")]
    TitleTooLong,
    #[msg("Campaign type too long")]
    TypeTooLong,
    #[msg("Metadata URI too long")]
    UriTooLong,
}
