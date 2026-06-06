import * as anchor from "@anchor-lang/core";
import { Program } from "@anchor-lang/core";
import { VotingNft } from "../target/types/voting_nft";
import { PublicKey } from "@solana/web3.js";
import { expect } from "chai";

describe("voting-nft", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.votingNft as Program<VotingNft>;
  const deployer = provider.wallet.publicKey;

  const holder = anchor.web3.Keypair.generate();
  const holderPubkey = holder.publicKey;

  const [nftPda] = PublicKey.findProgramAddressSync(
    [Buffer.from("voting-nft"), holderPubkey.toBuffer()],
    program.programId
  );

  async function airdrop(keypair: anchor.web3.Keypair) {
    const sig = await provider.connection.requestAirdrop(keypair.publicKey, 10 * anchor.web3.LAMPORTS_PER_SOL);
    await provider.connection.confirmTransaction(sig);
  }

  before(async () => {
    await airdrop(holder);
  });

  it("Mints a Voting NFT", async () => {
    const tx = await program.methods
      .mintVotingNft("ipfs://voting-nft-metadata")
      .accountsStrict({
        minter: deployer,
        holder: holderPubkey,
        nft: nftPda,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .rpc();

    console.log("Minted TX:", tx);

    const nft = await program.account.votingNftData.fetch(nftPda);
    expect(nft.holder.toBase58()).to.equal(holderPubkey.toBase58());
    expect(nft.tier).to.deep.equal({ tier1: {} });
    expect(nft.metrics.isVerified).to.be.false;
  });

  it("Records a donation", async () => {
    await program.methods
      .recordDonation(true)
      .accountsStrict({ authority: deployer, nft: nftPda })
      .rpc();

    const nft = await program.account.votingNftData.fetch(nftPda);
    expect(nft.metrics.donationsCount.toNumber()).to.equal(1);
    expect(nft.metrics.firstDonationTimestamp.toNumber()).to.be.greaterThan(0);
  });

  it("Records governance votes", async () => {
    for (let i = 0; i < 5; i++) {
      await program.methods
        .recordGovernanceVote()
        .accountsStrict({ authority: deployer, nft: nftPda })
        .rpc();
    }

    const nft = await program.account.votingNftData.fetch(nftPda);
    expect(nft.metrics.governanceVotes.toNumber()).to.equal(5);
  });

  it("Verifies the voter", async () => {
    await program.methods
      .verifyVoter()
      .accountsStrict({ admin: deployer, nft: nftPda })
      .rpc();

    const nft = await program.account.votingNftData.fetch(nftPda);
    expect(nft.metrics.isVerified).to.be.true;
  });

  it("Auto-upgrades to Tier2 (5 governance votes)", async () => {
    await program.methods
      .autoUpgradeTier()
      .accountsStrict({ caller: deployer, nft: nftPda })
      .rpc();

    const nft = await program.account.votingNftData.fetch(nftPda);
    expect(nft.tier).to.deep.equal({ tier2: {} });
  });

  it("Records campaign participation to reach Tier3", async () => {
    for (let i = 0; i < 10; i++) {
      await program.methods
        .recordCampaignParticipation()
        .accountsStrict({ authority: deployer, nft: nftPda })
        .rpc();
    }

    await program.methods
      .autoUpgradeTier()
      .accountsStrict({ caller: deployer, nft: nftPda })
      .rpc();

    const nft = await program.account.votingNftData.fetch(nftPda);
    expect(nft.tier).to.deep.equal({ tier3: {} });
    expect(nft.metrics.campaignsParticipated.toNumber()).to.equal(10);
  });
});
