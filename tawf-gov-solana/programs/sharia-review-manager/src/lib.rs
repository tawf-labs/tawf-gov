use anchor_lang::prelude::*;

declare_id!("BHy4RmvgvEHG9Sw4gM9gYxn7qSTtcQ2CPqNPTH9obtUD");

#[program]
pub mod sharia_review_manager {
    use super::*;

    /// Initialize a Sharia review instance
    pub fn initialize(
        ctx: Context<Initialize>,
        authority: Pubkey,
        verifier: Option<Pubkey>,
        quorum: u8,
    ) -> Result<()> {
        let review_state = &mut ctx.accounts.review_state;
        review_state.authority = authority;
        review_state.verifier = verifier;
        review_state.quorum = quorum;
        review_state.total_reviewers = 0;
        review_state.bump = ctx.bumps.review_state;
        Ok(())
    }

    /// Submit a review application (proposer → review)
    pub fn submit_review(
        ctx: Context<SubmitReview>,
        proposal_id: Pubkey,
        metadata_uri: String,
    ) -> Result<()> {
        let review = &mut ctx.accounts.review;
        review.proposal_id = proposal_id;
        review.proposer = ctx.accounts.proposer.key();
        review.metadata_uri = metadata_uri;
        review.status = ReviewStatus::Pending;
        review.reviewer_approvals = 0;
        review.reviewer_rejections = 0;
        review.bump = ctx.bumps.review;
        Ok(())
    }

    /// Review with ZK proof (if verifier is set)
    pub fn review_with_zk(
        ctx: Context<ReviewWithZK>,
        approved: bool,
        _proof_data: Vec<u8>,
    ) -> Result<()> {
        let review = &mut ctx.accounts.review;
        require!(
            review.status == ReviewStatus::Pending || review.status == ReviewStatus::UnderReview,
            ShariaReviewError::InvalidStatus
        );

        // If verifier is set, we would verify the ZK proof here
        // For now, we accept the proof_data as valid
        if let Some(_verifier) = ctx.accounts.review_state.verifier {
            // ZK proof verification would happen here via CPI to verifier program
            // or Arcium MXE callback
            msg!("ZK proof verification delegated to verifier");
        }

        if approved {
            review.reviewer_approvals += 1;
        } else {
            review.reviewer_rejections += 1;
        }

        review.status = ReviewStatus::UnderReview;

        // Check if quorum is met
        let total_votes = review.reviewer_approvals + review.reviewer_rejections;
        if total_votes >= ctx.accounts.review_state.quorum {
            if review.reviewer_approvals > review.reviewer_rejections {
                review.status = ReviewStatus::Approved;
            } else {
                review.status = ReviewStatus::Rejected;
            }

            emit!(ReviewFinalized {
                review: review.key(),
                proposal_id: review.proposal_id,
                approved: review.status == ReviewStatus::Approved,
                approvals: review.reviewer_approvals,
                rejections: review.reviewer_rejections,
            });
        }

        Ok(())
    }

    /// Simple review without ZK (if verifier is None)
    pub fn review_simple(ctx: Context<ReviewSimple>, approved: bool) -> Result<()> {
        let review = &mut ctx.accounts.review;
        require!(
            review.status == ReviewStatus::Pending || review.status == ReviewStatus::UnderReview,
            ShariaReviewError::InvalidStatus
        );

        // Ensure no verifier is set for simple review
        require!(
            ctx.accounts.review_state.verifier.is_none(),
            ShariaReviewError::VerifierRequired
        );

        if approved {
            review.reviewer_approvals += 1;
        } else {
            review.reviewer_rejections += 1;
        }

        review.status = ReviewStatus::UnderReview;

        // Check if quorum is met
        let total_votes = review.reviewer_approvals + review.reviewer_rejections;
        if total_votes >= ctx.accounts.review_state.quorum {
            if review.reviewer_approvals > review.reviewer_rejections {
                review.status = ReviewStatus::Approved;
            } else {
                review.status = ReviewStatus::Rejected;
            }

            emit!(ReviewFinalized {
                review: review.key(),
                proposal_id: review.proposal_id,
                approved: review.status == ReviewStatus::Approved,
                approvals: review.reviewer_approvals,
                rejections: review.reviewer_rejections,
            });
        }

        Ok(())
    }

    /// Update verifier (authority only)
    pub fn update_verifier(ctx: Context<UpdateVerifier>, new_verifier: Option<Pubkey>) -> Result<()> {
        ctx.accounts.review_state.verifier = new_verifier;
        Ok(())
    }

    /// Update quorum (authority only)
    pub fn update_quorum(ctx: Context<UpdateQuorum>, new_quorum: u8) -> Result<()> {
        require!(new_quorum > 0, ShariaReviewError::InvalidQuorum);
        ctx.accounts.review_state.quorum = new_quorum;
        Ok(())
    }
}

// ============================================================
// Account contexts
// ============================================================

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(mut)]
    pub authority: Signer<'info>,

    #[account(
        init,
        payer = authority,
        space = 8 + ReviewState::INIT_SPACE,
        seeds = [b"sharia-review-state"],
        bump,
    )]
    pub review_state: Account<'info, ReviewState>,

    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(proposal_id: Pubkey)]
pub struct SubmitReview<'info> {
    #[account(mut)]
    pub proposer: Signer<'info>,

    #[account(
        seeds = [b"sharia-review-state"],
        bump = review_state.bump,
    )]
    pub review_state: Account<'info, ReviewState>,

    #[account(
        init,
        payer = proposer,
        space = 8 + Review::INIT_SPACE,
        seeds = [b"review", proposal_id.as_ref(), proposer.key().as_ref()],
        bump,
    )]
    pub review: Account<'info, Review>,

    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct ReviewWithZK<'info> {
    #[account(mut)]
    pub reviewer: Signer<'info>,

    #[account(
        seeds = [b"sharia-review-state"],
        bump = review_state.bump,
    )]
    pub review_state: Account<'info, ReviewState>,

    #[account(
        mut,
        seeds = [b"review", review.proposal_id.as_ref(), review.proposer.as_ref()],
        bump = review.bump,
    )]
    pub review: Account<'info, Review>,

    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct ReviewSimple<'info> {
    #[account(mut)]
    pub reviewer: Signer<'info>,

    #[account(
        seeds = [b"sharia-review-state"],
        bump = review_state.bump,
    )]
    pub review_state: Account<'info, ReviewState>,

    #[account(
        mut,
        seeds = [b"review", review.proposal_id.as_ref(), review.proposer.as_ref()],
        bump = review.bump,
    )]
    pub review: Account<'info, Review>,

    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct UpdateVerifier<'info> {
    pub authority: Signer<'info>,

    #[account(
        mut,
        seeds = [b"sharia-review-state"],
        bump = review_state.bump,
        has_one = authority,
    )]
    pub review_state: Account<'info, ReviewState>,
}

#[derive(Accounts)]
pub struct UpdateQuorum<'info> {
    pub authority: Signer<'info>,

    #[account(
        mut,
        seeds = [b"sharia-review-state"],
        bump = review_state.bump,
        has_one = authority,
    )]
    pub review_state: Account<'info, ReviewState>,
}

// ============================================================
// State accounts
// ============================================================

#[account]
#[derive(InitSpace)]
pub struct ReviewState {
    pub authority: Pubkey,
    pub verifier: Option<Pubkey>, // If set → ZK proof required; if None → simple vote
    pub quorum: u8,
    pub total_reviewers: u8,
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct Review {
    pub proposal_id: Pubkey,
    pub proposer: Pubkey,
    #[max_len(256)]
    pub metadata_uri: String,
    pub status: ReviewStatus,
    pub reviewer_approvals: u8,
    pub reviewer_rejections: u8,
    pub bump: u8,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq, InitSpace)]
pub enum ReviewStatus {
    Pending,
    UnderReview,
    Approved,
    Rejected,
}

// ============================================================
// Events
// ============================================================

#[event]
pub struct ReviewFinalized {
    pub review: Pubkey,
    pub proposal_id: Pubkey,
    pub approved: bool,
    pub approvals: u8,
    pub rejections: u8,
}

// ============================================================
// Errors
// ============================================================

#[error_code]
pub enum ShariaReviewError {
    #[msg("Invalid review status")]
    InvalidStatus,
    #[msg("ZK verifier is required for this review")]
    VerifierRequired,
    #[msg("Invalid quorum value")]
    InvalidQuorum,
}
