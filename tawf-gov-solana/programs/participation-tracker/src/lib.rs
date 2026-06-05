use anchor_lang::prelude::*;

declare_id!("E7iLBgJ4nfWA5bLpwuTwBbEDVJBu9Zm1Vc2WZgZyNNqP");

#[program]
pub mod participation_tracker {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        msg!("Tawf Foundation - participation-tracker initialized");
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize {}
