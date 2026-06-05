use anchor_lang::prelude::*;

declare_id!("45Wawfsz4Zqj7iP1PyVm6bA8NwpvYZUTDP79xdQgCXov");

const MAX_TITLE: usize = 200;
const MAX_DESCRIPTION: usize = 500;
const MAX_URI: usize = 256;
const MAX_KYC_NOTES: usize = 256;
const MAX_CHECKLIST_ITEMS: usize = 8;
const MAX_CHECKLIST_ITEM_LEN: usize = 200;
const MAX_MILESTONES: usize = 10;
const MAX_MILESTONE_DESC: usize = 200;
const ZK_PROOF_LEN: usize = 32;

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq)]
pub enum ProposalStatus {
    Draft,
    KycPending,
    CommunityVote,
    PoolCreated,
    Active,
    Completed,
    Canceled,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq)]
pub enum KycStatus {
    NotRequired,
    Pending,
    Verified,
    Rejected,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq)]
pub enum CampaignType {
    Zakat,
    Wakaf,
    Donation,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq)]
pub enum MilestoneStatus {
    Pending,
    ProofSubmitted,
    Voting,
    Completed,
    Rejected,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct Milestone {
    pub milestone_id: u64,
    pub description: String,
    pub target_amount: u64,
    pub proof_ipfs: String,
    pub status: MilestoneStatus,
    pub proof_submitted_at: i64,
    pub vote_start: i64,
    pub vote_end: i64,
    pub votes_for: u64,
    pub votes_against: u64,
    pub votes_abstain: u64,
    pub released_at: i64,
}

#[account]
pub struct Proposal {
    pub proposal_id: u64,
    pub organizer: Pubkey,
    pub title: String,
    pub description: String,
    pub funding_goal: u64,
    pub is_emergency: bool,
    pub created_at: i64,
    pub status: ProposalStatus,
    pub kyc_status: KycStatus,
    pub kyc_notes: String,
    pub community_vote_start: i64,
    pub community_vote_end: i64,
    pub voting_period: i64,
    pub votes_for: u64,
    pub votes_against: u64,
    pub votes_abstain: u64,
    pub zakat_checklist_items: Vec<String>,
    pub metadata_uri: String,
    pub current_milestone_index: u64,
    pub total_released_amount: u64,
    pub pool_id: u64,
    pub campaign_type: CampaignType,
    pub milestones: Vec<Milestone>,
    pub bump: u8,
}

impl Proposal {
    pub const SPACE: usize = 8
        + 8  // proposal_id
        + 32 // organizer
        + 4 + MAX_TITLE
        + 4 + MAX_DESCRIPTION
        + 8  // funding_goal
        + 1  // is_emergency
        + 8  // created_at
        + 1  // status
        + 1  // kyc_status
        + 4 + MAX_KYC_NOTES
        + 8 + 8 // vote start/end
        + 8  // voting_period
        + 8 + 8 + 8 // votes
        + 4 + MAX_CHECKLIST_ITEMS * (4 + MAX_CHECKLIST_ITEM_LEN)
        + 4 + MAX_URI
        + 8  // current_milestone_index
        + 8  // total_released_amount
        + 8  // pool_id
        + 1  // campaign_type
        + 4 + MAX_MILESTONES * (8 + 4 + MAX_MILESTONE_DESC + 8 + 4 + MAX_URI + 1 + 8 + 8 + 8 + 8 + 8 + 8 + 8) // milestones
        + 1; // bump
}

#[program]
pub mod proposal_manager {
    use super::*;

    pub fn create_proposal(
        ctx: Context<CreateProposal>,
        organizer: Pubkey,
        title: String,
        description: String,
        funding_goal: u64,
        is_emergency: bool,
        mock_zk_kyc_proof: [u8; 32],
        zakat_checklist_items: Vec<String>,
        metadata_uri: String,
        milestone_descriptions: Vec<String>,
        milestone_amounts: Vec<u64>,
    ) -> Result<()> {
        require!(funding_goal > 0, ProposalError::ZeroFundingGoal);
        require!(!title.is_empty(), ProposalError::EmptyTitle);
        require!(title.len() <= MAX_TITLE, ProposalError::TitleTooLong);
        require!(description.len() <= MAX_DESCRIPTION, ProposalError::DescriptionTooLong);
        require!(metadata_uri.len() <= MAX_URI, ProposalError::UriTooLong);
        require!(zakat_checklist_items.len() <= MAX_CHECKLIST_ITEMS, ProposalError::TooManyChecklistItems);

        let proposal = &mut ctx.accounts.proposal;
        let clock = Clock::get()?;

        proposal.organizer = organizer;
        proposal.title = title;
        proposal.description = description;
        proposal.funding_goal = funding_goal;
        proposal.is_emergency = is_emergency;
        proposal.created_at = clock.unix_timestamp;
        proposal.status = ProposalStatus::Draft;
        proposal.kyc_status = if is_emergency { KycStatus::NotRequired } else { KycStatus::Pending };
        proposal.kyc_notes = String::new();
        proposal.community_vote_start = 0;
        proposal.community_vote_end = 0;
        proposal.voting_period = 7 * 86400;
        proposal.votes_for = 0;
        proposal.votes_against = 0;
        proposal.votes_abstain = 0;
        proposal.zakat_checklist_items = zakat_checklist_items;
        proposal.metadata_uri = metadata_uri;
        proposal.current_milestone_index = 0;
        proposal.total_released_amount = 0;
        proposal.pool_id = 0;
        proposal.campaign_type = CampaignType::Donation;
        proposal.milestones = Vec::new();
        proposal.bump = ctx.bumps.proposal;

        require!(milestone_descriptions.len() == milestone_amounts.len(), ProposalError::MilestoneMismatch);
        if !milestone_descriptions.is_empty() {
            require!(!is_emergency, ProposalError::EmergencyNoMilestones);
            require!(milestone_descriptions.len() <= MAX_MILESTONES, ProposalError::TooManyMilestones);

            let mut total_milestone_amount: u64 = 0;
            for i in 0..milestone_descriptions.len() {
                require!(milestone_amounts[i] > 0, ProposalError::ZeroMilestoneAmount);
                require!(milestone_descriptions[i].len() <= MAX_MILESTONE_DESC, ProposalError::MilestoneDescTooLong);
                total_milestone_amount = total_milestone_amount.checked_add(milestone_amounts[i]).unwrap();
                require!(milestone_descriptions[i].len() > 0, ProposalError::EmptyMilestoneDesc);

                proposal.milestones.push(Milestone {
                    milestone_id: i as u64,
                    description: milestone_descriptions[i].clone(),
                    target_amount: milestone_amounts[i],
                    proof_ipfs: String::new(),
                    status: MilestoneStatus::Pending,
                    proof_submitted_at: 0,
                    vote_start: 0,
                    vote_end: 0,
                    votes_for: 0,
                    votes_against: 0,
                    votes_abstain: 0,
                    released_at: 0,
                });
            }
            require!(total_milestone_amount <= funding_goal, ProposalError::MilestoneExceedsGoal);
        }

        emit!(ProposalCreated {
            proposal_id: ctx.accounts.proposal.proposal_id,
            organizer,
        });
        Ok(())
    }

    pub fn update_kyc_status(
        ctx: Context<UpdateKycStatus>,
        new_status: KycStatus,
        notes: String,
    ) -> Result<()> {
        require!(notes.len() <= MAX_KYC_NOTES, ProposalError::KycNotesTooLong);
        let proposal = &mut ctx.accounts.proposal;
        proposal.kyc_status = new_status;
        proposal.kyc_notes = notes;
        emit!(KycStatusUpdated { proposal_id: proposal.proposal_id, new_status });
        Ok(())
    }

    pub fn submit_for_community_vote(ctx: Context<SubmitForVote>) -> Result<()> {
        let proposal = &mut ctx.accounts.proposal;
        require!(proposal.status == ProposalStatus::Draft, ProposalError::InvalidStatus);

        if !proposal.is_emergency {
            require!(proposal.kyc_status == KycStatus::Verified, ProposalError::KycNotVerified);
        }

        let clock = Clock::get()?;
        proposal.community_vote_start = clock.unix_timestamp;
        proposal.community_vote_end = clock.unix_timestamp + proposal.voting_period;
        proposal.status = ProposalStatus::CommunityVote;

        emit!(ProposalSubmitted { proposal_id: proposal.proposal_id });
        Ok(())
    }

    pub fn cancel_proposal(ctx: Context<CancelProposal>) -> Result<()> {
        let proposal = &mut ctx.accounts.proposal;
        require!(
            proposal.status != ProposalStatus::PoolCreated && proposal.status != ProposalStatus::Completed,
            ProposalError::CannotCancelActive
        );
        proposal.status = ProposalStatus::Canceled;
        emit!(ProposalCanceled { proposal_id: proposal.proposal_id });
        Ok(())
    }

    pub fn update_proposal_status(
        ctx: Context<UpdateProposalStatus>,
        new_status: ProposalStatus,
        votes_for: u64,
        votes_against: u64,
        votes_abstain: u64,
    ) -> Result<()> {
        let proposal = &mut ctx.accounts.proposal;
        proposal.status = new_status;
        proposal.votes_for = votes_for;
        proposal.votes_against = votes_against;
        proposal.votes_abstain = votes_abstain;
        Ok(())
    }

    pub fn update_proposal_pool_id(ctx: Context<UpdateProposalPoolId>, pool_id: u64) -> Result<()> {
        ctx.accounts.proposal.pool_id = pool_id;
        Ok(())
    }
}

#[derive(Accounts)]
#[instruction(organizer: Pubkey)]
pub struct CreateProposal<'info> {
    #[account(mut)]
    pub signer: Signer<'info>,
    #[account(
        init,
        seeds = [b"proposal", organizer.as_ref()],
        bump,
        payer = signer,
        space = Proposal::SPACE,
    )]
    pub proposal: Account<'info, Proposal>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct UpdateKycStatus<'info> {
    pub authority: Signer<'info>,
    #[account(
        mut,
        seeds = [b"proposal", proposal.organizer.as_ref()],
        bump = proposal.bump,
    )]
    pub proposal: Account<'info, Proposal>,
}

#[derive(Accounts)]
pub struct SubmitForVote<'info> {
    pub signer: Signer<'info>,
    #[account(
        mut,
        seeds = [b"proposal", proposal.organizer.as_ref()],
        bump = proposal.bump,
    )]
    pub proposal: Account<'info, Proposal>,
}

#[derive(Accounts)]
pub struct CancelProposal<'info> {
    pub signer: Signer<'info>,
    #[account(
        mut,
        seeds = [b"proposal", proposal.organizer.as_ref()],
        bump = proposal.bump,
    )]
    pub proposal: Account<'info, Proposal>,
}

#[derive(Accounts)]
pub struct UpdateProposalStatus<'info> {
    pub authority: Signer<'info>,
    #[account(
        mut,
        seeds = [b"proposal", proposal.organizer.as_ref()],
        bump = proposal.bump,
    )]
    pub proposal: Account<'info, Proposal>,
}

#[derive(Accounts)]
pub struct UpdateProposalPoolId<'info> {
    pub authority: Signer<'info>,
    #[account(
        mut,
        seeds = [b"proposal", proposal.organizer.as_ref()],
        bump = proposal.bump,
    )]
    pub proposal: Account<'info, Proposal>,
}

#[event]
pub struct ProposalCreated {
    pub proposal_id: u64,
    pub organizer: Pubkey,
}

#[event]
pub struct KycStatusUpdated {
    pub proposal_id: u64,
    pub new_status: KycStatus,
}

#[event]
pub struct ProposalSubmitted {
    pub proposal_id: u64,
}

#[event]
pub struct ProposalCanceled {
    pub proposal_id: u64,
}

#[error_code]
pub enum ProposalError {
    #[msg("Funding goal must be > 0")]
    ZeroFundingGoal,
    #[msg("Title cannot be empty")]
    EmptyTitle,
    #[msg("Title too long")]
    TitleTooLong,
    #[msg("Description too long")]
    DescriptionTooLong,
    #[msg("URI too long")]
    UriTooLong,
    #[msg("Too many checklist items")]
    TooManyChecklistItems,
    #[msg("Milestone descriptions and amounts length mismatch")]
    MilestoneMismatch,
    #[msg("Emergency campaigns cannot have milestones")]
    EmergencyNoMilestones,
    #[msg("Too many milestones")]
    TooManyMilestones,
    #[msg("Milestone amount must be > 0")]
    ZeroMilestoneAmount,
    #[msg("Milestone total exceeds funding goal")]
    MilestoneExceedsGoal,
    #[msg("Milestone description required")]
    EmptyMilestoneDesc,
    #[msg("Milestone description too long")]
    MilestoneDescTooLong,
    #[msg("KYC notes too long")]
    KycNotesTooLong,
    #[msg("Invalid proposal status for this operation")]
    InvalidStatus,
    #[msg("KYC must be verified first")]
    KycNotVerified,
    #[msg("Cannot cancel active or completed proposal")]
    CannotCancelActive,
}
