use anchor_lang::prelude::*;

declare_id!("6viNr1fokMKD3zfp5Cv2E8Lij2K27pecYPd92F2hT5gZ");

const MAX_URI_LENGTH: usize = 256;

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq)]
pub enum VotingTier {
    Tier1,
    Tier2,
    Tier3,
}

impl VotingTier {
    pub fn voting_power(&self) -> u8 {
        match self {
            VotingTier::Tier1 => 1,
            VotingTier::Tier2 => 2,
            VotingTier::Tier3 => 3,
        }
    }
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct VoterMetrics {
    pub donations_count: u64,
    pub governance_votes: u64,
    pub first_donation_timestamp: i64,
    pub successful_proposals: u64,
    pub campaigns_participated: u64,
    pub is_verified: bool,
}

#[account]
pub struct VotingNftData {
    pub holder: Pubkey,
    pub tier: VotingTier,
    pub metrics: VoterMetrics,
    pub metadata_uri: String,
    pub minted_at: i64,
    pub last_tier_upgrade: i64,
    pub bump: u8,
}

impl VotingNftData {
    pub const SPACE: usize = 8
        + 32                    // holder
        + 1                     // tier
        + 8 + 8 + 8 + 8 + 8 + 1 // metrics
        + 4 + MAX_URI_LENGTH    // metadata_uri
        + 8                     // minted_at
        + 8                     // last_tier_upgrade
        + 1;                    // bump
}

#[program]
pub mod voting_nft {
    use super::*;

    pub fn mint_voting_nft(ctx: Context<MintVotingNft>, metadata_uri: String) -> Result<()> {
        require!(metadata_uri.len() <= MAX_URI_LENGTH, VotingNftError::UriTooLong);

        let nft = &mut ctx.accounts.nft;
        let clock = Clock::get()?;

        nft.holder = ctx.accounts.holder.key();
        nft.tier = VotingTier::Tier1;
        nft.metrics = VoterMetrics {
            donations_count: 0,
            governance_votes: 0,
            first_donation_timestamp: 0,
            successful_proposals: 0,
            campaigns_participated: 0,
            is_verified: false,
        };
        nft.metadata_uri = metadata_uri.clone();
        nft.minted_at = clock.unix_timestamp;
        nft.last_tier_upgrade = clock.unix_timestamp;
        nft.bump = ctx.bumps.nft;

        emit!(VotingNftMinted {
            holder: ctx.accounts.holder.key(),
            tier: VotingTier::Tier1,
        });
        Ok(())
    }

    pub fn upgrade_tier(ctx: Context<UpgradeTier>, new_tier: VotingTier, reason: String) -> Result<()> {
        let nft = &mut ctx.accounts.nft;
        require!(new_tier as u8 >= nft.tier as u8, VotingNftError::CannotDowngrade);
        require!(new_tier as u8 > nft.tier as u8, VotingNftError::SameTier);

        let holder = nft.holder;
        let old_tier = nft.tier;
        nft.tier = new_tier;
        nft.last_tier_upgrade = Clock::get()?.unix_timestamp;

        emit!(TierUpgraded { holder, old_tier, new_tier, reason });
        Ok(())
    }

    pub fn auto_upgrade_tier(ctx: Context<AutoUpgradeTier>) -> Result<()> {
        let nft = &mut ctx.accounts.nft;
        let clock = Clock::get()?;

        require!(nft.metrics.is_verified, VotingNftError::NotVerified);

        let new_tier = if nft.metrics.campaigns_participated >= 10 || nft.metrics.successful_proposals >= 1 {
            VotingTier::Tier3
        } else if nft.metrics.campaigns_participated >= 3
            || nft.metrics.governance_votes >= 5
            || (nft.metrics.first_donation_timestamp > 0
                && clock.unix_timestamp >= nft.metrics.first_donation_timestamp + 30 * 86400)
        {
            VotingTier::Tier2
        } else {
            VotingTier::Tier1
        };

        if new_tier as u8 > nft.tier as u8 {
            let holder = nft.holder;
            let old_tier = nft.tier;
            nft.tier = new_tier;
            nft.last_tier_upgrade = clock.unix_timestamp;
            emit!(TierUpgraded {
                holder,
                old_tier,
                new_tier,
                reason: "Auto-upgraded based on participation".to_string(),
            });
        }
        Ok(())
    }

    pub fn record_donation(ctx: Context<RecordDonation>, is_first_donation: bool) -> Result<()> {
        let nft = &mut ctx.accounts.nft;
        let holder = nft.holder;
        let metrics = &mut nft.metrics;

        if is_first_donation && metrics.first_donation_timestamp == 0 {
            metrics.first_donation_timestamp = Clock::get()?.unix_timestamp;
        }
        metrics.donations_count += 1;
        let count = metrics.donations_count;

        emit!(DonationRecorded { holder, new_donation_count: count });
        Ok(())
    }

    pub fn record_governance_vote(ctx: Context<RecordGovernanceVote>) -> Result<()> {
        let nft = &mut ctx.accounts.nft;
        let holder = nft.holder;
        nft.metrics.governance_votes += 1;
        let count = nft.metrics.governance_votes;

        emit!(GovernanceVoteRecorded { holder, new_vote_count: count });
        Ok(())
    }

    pub fn record_proposal(ctx: Context<RecordProposal>, approved: bool) -> Result<()> {
        let nft = &mut ctx.accounts.nft;
        let holder = nft.holder;
        if approved {
            nft.metrics.successful_proposals += 1;
        }
        let count = nft.metrics.successful_proposals;

        emit!(ProposalRecorded { holder, approved, new_successful_count: count });
        Ok(())
    }

    pub fn record_campaign_participation(ctx: Context<RecordCampaignParticipation>) -> Result<()> {
        let nft = &mut ctx.accounts.nft;
        let holder = nft.holder;
        nft.metrics.campaigns_participated += 1;
        let count = nft.metrics.campaigns_participated;

        emit!(CampaignParticipationRecorded { holder, new_campaigns_count: count });
        Ok(())
    }

    pub fn verify_voter(ctx: Context<VerifyVoter>) -> Result<()> {
        let nft = &mut ctx.accounts.nft;
        require!(!nft.metrics.is_verified, VotingNftError::AlreadyVerified);
        let holder = nft.holder;
        nft.metrics.is_verified = true;
        emit!(VoterVerified { holder });
        Ok(())
    }
}

#[derive(Accounts)]
pub struct MintVotingNft<'info> {
    #[account(mut)]
    pub minter: Signer<'info>,
    /// CHECK: holder may not be a signer
    pub holder: AccountInfo<'info>,
    #[account(
        init,
        seeds = [b"voting-nft", holder.key().as_ref()],
        bump,
        payer = minter,
        space = VotingNftData::SPACE,
    )]
    pub nft: Account<'info, VotingNftData>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct UpgradeTier<'info> {
    pub upgrader: Signer<'info>,
    #[account(
        mut,
        seeds = [b"voting-nft", nft.holder.as_ref()],
        bump = nft.bump,
    )]
    pub nft: Account<'info, VotingNftData>,
}

#[derive(Accounts)]
pub struct AutoUpgradeTier<'info> {
    /// CHECK: any signer can trigger auto-upgrade
    pub caller: Signer<'info>,
    #[account(
        mut,
        seeds = [b"voting-nft", nft.holder.as_ref()],
        bump = nft.bump,
    )]
    pub nft: Account<'info, VotingNftData>,
}

#[derive(Accounts)]
pub struct RecordDonation<'info> {
    pub authority: Signer<'info>,
    #[account(
        mut,
        seeds = [b"voting-nft", nft.holder.as_ref()],
        bump = nft.bump,
    )]
    pub nft: Account<'info, VotingNftData>,
}

#[derive(Accounts)]
pub struct RecordGovernanceVote<'info> {
    pub authority: Signer<'info>,
    #[account(
        mut,
        seeds = [b"voting-nft", nft.holder.as_ref()],
        bump = nft.bump,
    )]
    pub nft: Account<'info, VotingNftData>,
}

#[derive(Accounts)]
pub struct RecordProposal<'info> {
    pub authority: Signer<'info>,
    #[account(
        mut,
        seeds = [b"voting-nft", nft.holder.as_ref()],
        bump = nft.bump,
    )]
    pub nft: Account<'info, VotingNftData>,
}

#[derive(Accounts)]
pub struct RecordCampaignParticipation<'info> {
    pub authority: Signer<'info>,
    #[account(
        mut,
        seeds = [b"voting-nft", nft.holder.as_ref()],
        bump = nft.bump,
    )]
    pub nft: Account<'info, VotingNftData>,
}

#[derive(Accounts)]
pub struct VerifyVoter<'info> {
    pub admin: Signer<'info>,
    #[account(
        mut,
        seeds = [b"voting-nft", nft.holder.as_ref()],
        bump = nft.bump,
    )]
    pub nft: Account<'info, VotingNftData>,
}

#[event]
pub struct VotingNftMinted {
    pub holder: Pubkey,
    pub tier: VotingTier,
}

#[event]
pub struct TierUpgraded {
    pub holder: Pubkey,
    pub old_tier: VotingTier,
    pub new_tier: VotingTier,
    pub reason: String,
}

#[event]
pub struct DonationRecorded {
    pub holder: Pubkey,
    pub new_donation_count: u64,
}

#[event]
pub struct GovernanceVoteRecorded {
    pub holder: Pubkey,
    pub new_vote_count: u64,
}

#[event]
pub struct ProposalRecorded {
    pub holder: Pubkey,
    pub approved: bool,
    pub new_successful_count: u64,
}

#[event]
pub struct CampaignParticipationRecorded {
    pub holder: Pubkey,
    pub new_campaigns_count: u64,
}

#[event]
pub struct VoterVerified {
    pub holder: Pubkey,
}

#[error_code]
pub enum VotingNftError {
    #[msg("URI exceeds maximum length")]
    UriTooLong,
    #[msg("Cannot downgrade tier")]
    CannotDowngrade,
    #[msg("Already at this tier or higher")]
    SameTier,
    #[msg("Voter is not verified")]
    NotVerified,
    #[msg("Voter already verified")]
    AlreadyVerified,
}
