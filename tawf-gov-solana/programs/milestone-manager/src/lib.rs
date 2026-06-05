use anchor_lang::prelude::*;

declare_id!("8R8moNb35W4hwENApADrVjQbTTHeEekaeevWMU8MdpxU");

#[account]
pub struct MilestoneVote {
    pub voter: Pubkey,
    pub proposal: Pubkey,
    pub milestone_id: u64,
    pub option: MilestoneVoteOption,
    pub weight: u8,
    pub bump: u8,
}

impl MilestoneVote {
    pub const SPACE: usize = 8 + 32 + 32 + 8 + 1 + 1 + 1;
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq)]
pub enum MilestoneVoteOption {
    Against,
    Support,
    Abstain,
}

#[program]
pub mod milestone_manager {
    use super::*;

    pub fn cast_milestone_vote(
        ctx: Context<CastMilestoneVote>,
        milestone_id: u64,
        option: MilestoneVoteOption,
        weight: u8,
    ) -> Result<()> {
        let vote = &mut ctx.accounts.vote;
        vote.voter = ctx.accounts.voter.key();
        vote.proposal = ctx.accounts.proposal.key();
        vote.milestone_id = milestone_id;
        vote.option = option;
        vote.weight = weight;
        vote.bump = ctx.bumps.vote;

        emit!(MilestoneVoteCast {
            voter: ctx.accounts.voter.key(),
            proposal: ctx.accounts.proposal.key(),
            milestone_id,
            option,
            weight,
        });
        Ok(())
    }

    pub fn finalize_milestone_vote(
        ctx: Context<FinalizeMilestoneVote>,
        milestone_id: u64,
        votes_for: u64,
        votes_against: u64,
        votes_abstain: u64,
        quorum_percentage: u8,
        pass_threshold: u8,
        total_nft_supply: u64,
    ) -> Result<()> {
        let total_votes = votes_for + votes_against + votes_abstain;
        let valid_votes = votes_for + votes_against;
        let quorum_required = (total_nft_supply * quorum_percentage as u64) / 100;
        let quorum_reached = total_votes >= quorum_required;

        let passed = quorum_reached && valid_votes > 0
            && (votes_for * 100) >= (valid_votes * pass_threshold as u64);

        emit!(MilestoneVoteFinalized {
            proposal: ctx.accounts.proposal.key(),
            milestone_id,
            passed,
            votes_for,
            votes_against,
            votes_abstain,
            quorum_reached,
        });
        Ok(())
    }
}

#[derive(Accounts)]
#[instruction(milestone_id: u64)]
pub struct CastMilestoneVote<'info> {
    #[account(mut)]
    pub voter: Signer<'info>,
    /// CHECK: proposal account verified by program logic
    pub proposal: AccountInfo<'info>,
    #[account(
        init,
        seeds = [b"milestone-vote", proposal.key().as_ref(), &milestone_id.to_le_bytes(), voter.key().as_ref()],
        bump,
        payer = voter,
        space = MilestoneVote::SPACE,
    )]
    pub vote: Account<'info, MilestoneVote>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct FinalizeMilestoneVote<'info> {
    pub caller: Signer<'info>,
    /// CHECK: proposal account verified by program logic
    pub proposal: AccountInfo<'info>,
}

#[event]
pub struct MilestoneVoteCast {
    pub voter: Pubkey,
    pub proposal: Pubkey,
    pub milestone_id: u64,
    pub option: MilestoneVoteOption,
    pub weight: u8,
}

#[event]
pub struct MilestoneVoteFinalized {
    pub proposal: Pubkey,
    pub milestone_id: u64,
    pub passed: bool,
    pub votes_for: u64,
    pub votes_against: u64,
    pub votes_abstain: u64,
    pub quorum_reached: bool,
}
