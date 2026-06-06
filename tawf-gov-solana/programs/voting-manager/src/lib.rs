use anchor_lang::prelude::*;

declare_id!("5vm34iLwi38MMXeLQwy7VmshMx3sc6pKLMhaEdTxcUQh");

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq)]
pub enum VoteOption {
    Against,
    Support,
    Abstain,
}

#[account]
pub struct Vote {
    pub voter: Pubkey,
    pub proposal: Pubkey,
    pub option: VoteOption,
    pub weight: u8,
    pub bump: u8,
}

impl Vote {
    pub const SPACE: usize = 8 + 32 + 32 + 1 + 1 + 1;
}

#[program]
pub mod voting_manager {
    use super::*;

    pub fn cast_vote(
        ctx: Context<CastVote>,
        option: VoteOption,
        weight: u8,
    ) -> Result<()> {
        let vote = &mut ctx.accounts.vote;
        vote.voter = ctx.accounts.voter.key();
        vote.proposal = ctx.accounts.proposal.key();
        vote.option = option;
        vote.weight = weight;
        vote.bump = ctx.bumps.vote;
        emit!(VoteCast {
            voter: ctx.accounts.voter.key(),
            proposal: ctx.accounts.proposal.key(),
            option,
            weight,
        });
        Ok(())
    }

    pub fn finalize_vote(
        ctx: Context<FinalizeVote>,
        votes_for: u64,
        votes_against: u64,
        votes_abstain: u64,
        quorum_percentage: u8,
        pass_threshold: u8,
        total_nft_supply: u64,
    ) -> Result<()> {
        let total_votes = votes_for + votes_against + votes_abstain;
        let quorum_required = (total_nft_supply * quorum_percentage as u64) / 100;
        let quorum_reached = total_votes >= quorum_required;

        let passed = if quorum_reached {
            let valid_votes = votes_for + votes_against;
            if valid_votes > 0 {
                (votes_for * 100) >= (valid_votes * pass_threshold as u64)
            } else {
                false
            }
        } else {
            false
        };

        emit!(VoteFinalized {
            proposal: ctx.accounts.proposal.key(),
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
pub struct CastVote<'info> {
    #[account(mut)]
    pub voter: Signer<'info>,
    /// CHECK: proposal account, validated by program logic
    pub proposal: UncheckedAccount<'info>,
    #[account(
        init,
        seeds = [b"vote", proposal.key().as_ref(), voter.key().as_ref()],
        bump,
        payer = voter,
        space = Vote::SPACE,
    )]
    pub vote: Account<'info, Vote>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct FinalizeVote<'info> {
    pub caller: Signer<'info>,
    /// CHECK: proposal account, validated by program logic
    pub proposal: UncheckedAccount<'info>,
}

#[event]
pub struct VoteCast {
    pub voter: Pubkey,
    pub proposal: Pubkey,
    pub option: VoteOption,
    pub weight: u8,
}

#[event]
pub struct VoteFinalized {
    pub proposal: Pubkey,
    pub passed: bool,
    pub votes_for: u64,
    pub votes_against: u64,
    pub votes_abstain: u64,
    pub quorum_reached: bool,
}
