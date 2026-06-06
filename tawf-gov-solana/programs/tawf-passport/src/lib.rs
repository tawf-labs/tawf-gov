use anchor_lang::prelude::*;

declare_id!("6669YfjNt8YbQ1wrQw9jJXpQKzGhEvGjhpGepMPcsmNb");

const MAX_CREDENTIALS: usize = 8;
const MAX_URI_LENGTH: usize = 256;

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq)]
pub enum PassportType {
    Individual,
    Organization,
    Mosque,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct Credential {
    pub hash: [u8; 32],
    pub vc_ipfs_uri: String,
    pub valid: bool,
}

#[account]
pub struct Passport {
    pub holder: Pubkey,
    pub passport_type: PassportType,
    pub metadata_uri: String,
    pub verified: bool,
    pub issuer_did: String,
    pub credentials: Vec<Credential>,
    pub bump: u8,
}

impl Passport {
    pub const SPACE: usize = 8
        + 32                              // holder
        + 1                               // passport_type (enum)
        + 4 + MAX_URI_LENGTH              // metadata_uri
        + 1                               // verified (bool)
        + 4 + MAX_URI_LENGTH              // issuer_did
        + 4 + MAX_CREDENTIALS * (32 + 4 + MAX_URI_LENGTH + 1) // credentials vec
        + 1;                              // bump
}

#[program]
pub mod tawf_passport {
    use super::*;

    pub fn issue_passport(
        ctx: Context<IssuePassport>,
        passport_type: PassportType,
        metadata_uri: String,
    ) -> Result<()> {
        require!(metadata_uri.len() <= MAX_URI_LENGTH, PassportError::UriTooLong);

        let passport = &mut ctx.accounts.passport;
        passport.holder = ctx.accounts.holder.key();
        passport.passport_type = passport_type;
        passport.metadata_uri = metadata_uri;
        passport.verified = false;
        passport.issuer_did = String::new();
        passport.credentials = Vec::new();
        passport.bump = ctx.bumps.passport;

        emit!(PassportIssued {
            holder: ctx.accounts.holder.key(),
            passport_type: passport_type,
        });
        Ok(())
    }

    pub fn set_verified(ctx: Context<SetVerified>, verified: bool) -> Result<()> {
        let passport = &mut ctx.accounts.passport;
        passport.verified = verified;
        emit!(PassportVerified {
            holder: passport.holder,
            verified,
        });
        Ok(())
    }

    pub fn update_metadata(ctx: Context<UpdateMetadata>, metadata_uri: String) -> Result<()> {
        require!(metadata_uri.len() <= MAX_URI_LENGTH, PassportError::UriTooLong);
        let passport = &mut ctx.accounts.passport;
        passport.metadata_uri = metadata_uri;
        Ok(())
    }

    pub fn set_issuer_did(ctx: Context<SetIssuerDID>, issuer_did: String) -> Result<()> {
        require!(issuer_did.len() <= MAX_URI_LENGTH, PassportError::UriTooLong);
        let passport = &mut ctx.accounts.passport;
        passport.issuer_did = issuer_did;
        Ok(())
    }

    pub fn issue_credential(
        ctx: Context<IssueCredential>,
        credential_hash: [u8; 32],
        vc_ipfs_uri: String,
    ) -> Result<()> {
        require!(vc_ipfs_uri.len() <= MAX_URI_LENGTH, PassportError::UriTooLong);
        let passport = &mut ctx.accounts.passport;
        require!(passport.credentials.len() < MAX_CREDENTIALS, PassportError::MaxCredentials);

        passport.credentials.push(Credential {
            hash: credential_hash,
            vc_ipfs_uri,
            valid: true,
        });

        emit!(CredentialIssued {
            holder: passport.holder,
            credential_hash,
        });
        Ok(())
    }

    pub fn revoke_credential(ctx: Context<RevokeCredential>, credential_hash: [u8; 32]) -> Result<()> {
        let passport = &mut ctx.accounts.passport;
        for cred in passport.credentials.iter_mut() {
            if cred.hash == credential_hash {
                cred.valid = false;
                emit!(CredentialRevoked {
                    holder: passport.holder,
                    credential_hash,
                });
                return Ok(());
            }
        }
        Err(PassportError::CredentialNotFound.into())
    }

    pub fn renounce_passport(ctx: Context<RenouncePassport>) -> Result<()> {
        emit!(PassportRenounced { holder: ctx.accounts.passport.holder });
        Ok(())
    }
}

#[derive(Accounts)]
pub struct IssuePassport<'info> {
    #[account(mut)]
    pub issuer: Signer<'info>,
    /// CHECK: holder may not be a signer
    pub holder: UncheckedAccount<'info>,
    #[account(
        init,
        seeds = [b"passport", holder.key().as_ref()],
        bump,
        payer = issuer,
        space = Passport::SPACE,
    )]
    pub passport: Account<'info, Passport>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct SetVerified<'info> {
    pub admin: Signer<'info>,
    #[account(
        mut,
        seeds = [b"passport", passport.holder.as_ref()],
        bump = passport.bump,
    )]
    pub passport: Account<'info, Passport>,
}

#[derive(Accounts)]
pub struct UpdateMetadata<'info> {
    pub holder: Signer<'info>,
    #[account(
        mut,
        seeds = [b"passport", passport.holder.as_ref()],
        bump = passport.bump,
        constraint = passport.holder == holder.key() @ PassportError::Unauthorized,
    )]
    pub passport: Account<'info, Passport>,
}

#[derive(Accounts)]
pub struct SetIssuerDID<'info> {
    pub admin: Signer<'info>,
    #[account(
        mut,
        seeds = [b"passport", passport.holder.as_ref()],
        bump = passport.bump,
    )]
    pub passport: Account<'info, Passport>,
}

#[derive(Accounts)]
pub struct IssueCredential<'info> {
    pub issuer: Signer<'info>,
    #[account(
        mut,
        seeds = [b"passport", passport.holder.as_ref()],
        bump = passport.bump,
    )]
    pub passport: Account<'info, Passport>,
}

#[derive(Accounts)]
pub struct RevokeCredential<'info> {
    pub admin: Signer<'info>,
    #[account(
        mut,
        seeds = [b"passport", passport.holder.as_ref()],
        bump = passport.bump,
    )]
    pub passport: Account<'info, Passport>,
}

#[derive(Accounts)]
pub struct RenouncePassport<'info> {
    #[account(mut)]
    pub holder: Signer<'info>,
    #[account(
        mut,
        seeds = [b"passport", passport.holder.as_ref()],
        bump = passport.bump,
        constraint = passport.holder == holder.key() @ PassportError::Unauthorized,
        close = holder,
    )]
    pub passport: Account<'info, Passport>,
}

#[event]
pub struct PassportIssued {
    pub holder: Pubkey,
    pub passport_type: PassportType,
}

#[event]
pub struct PassportVerified {
    pub holder: Pubkey,
    pub verified: bool,
}

#[event]
pub struct PassportRenounced {
    pub holder: Pubkey,
}

#[event]
pub struct CredentialIssued {
    pub holder: Pubkey,
    pub credential_hash: [u8; 32],
}

#[event]
pub struct CredentialRevoked {
    pub holder: Pubkey,
    pub credential_hash: [u8; 32],
}

#[error_code]
pub enum PassportError {
    #[msg("Holder already has a passport")]
    AlreadyHasPassport,
    #[msg("URI exceeds maximum length")]
    UriTooLong,
    #[msg("Maximum credentials reached")]
    MaxCredentials,
    #[msg("Credential not found")]
    CredentialNotFound,
    #[msg("Unauthorized")]
    Unauthorized,
}
