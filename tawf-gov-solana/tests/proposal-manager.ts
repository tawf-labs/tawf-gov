import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { ProposalManager } from "../target/types/proposal_manager";
import { PublicKey } from "@solana/web3.js";
import { expect } from "chai";

describe("proposal-manager", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.proposalManager as Program<ProposalManager>;
  const deployer = provider.wallet.publicKey;
  const organizer = anchor.web3.Keypair.generate();

  const [proposalPda] = PublicKey.findProgramAddressSync(
    [Buffer.from("proposal"), organizer.publicKey.toBuffer()],
    program.programId
  );

  before(async () => {
    const sig = await provider.connection.requestAirdrop(organizer.publicKey, 10 * anchor.web3.LAMPORTS_PER_SOL);
    await provider.connection.confirmTransaction(sig);
  });

  it("Creates a proposal with milestones", async () => {
    const title = "Build Mosque Renovation";
    const description = "Funds to renovate the community mosque";
    const fundingGoal = new anchor.BN(100_000_000_000); // 100,000 IDRX
    const isEmergency = false;
    const zkProof = Array(32).fill(0);
    const checklistItems = ["Sharia compliant", "Community approved"];
    const metadataUri = "ipfs://proposal-meta";
    const milestoneDescs = ["Foundation work", "Roof repair", "Interior finishing"];
    const milestoneAmounts = [new anchor.BN(40_000_000_000), new anchor.BN(30_000_000_000), new anchor.BN(30_000_000_000)];

    const tx = await program.methods
      .createProposal(
        organizer.publicKey,
        title,
        description,
        fundingGoal,
        isEmergency,
        zkProof,
        checklistItems,
        metadataUri,
        milestoneDescs,
        milestoneAmounts,
      )
      .accountsStrict({
        signer: deployer,
        proposal: proposalPda,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .rpc();

    console.log("Proposal created TX:", tx);

    const p = await program.account.proposal.fetch(proposalPda);
    expect(p.organizer.toBase58()).to.equal(organizer.publicKey.toBase58());
    expect(p.title).to.equal(title);
    expect(p.fundingGoal.toNumber()).to.equal(100_000_000_000);
    expect(p.isEmergency).to.be.false;
    expect(p.milestones.length).to.equal(3);
    expect(p.milestones[0].targetAmount.toNumber()).to.equal(40_000_000_000);
  });

  it("Updates KYC status", async () => {
    await program.methods
      .updateKycStatus({ verified: {} }, "KYC passed")
      .accountsStrict({ authority: deployer, proposal: proposalPda })
      .rpc();

    const p = await program.account.proposal.fetch(proposalPda);
    expect(p.kycStatus).to.deep.equal({ verified: {} });
    expect(p.kycNotes).to.equal("KYC passed");
  });

  it("Submits for community vote", async () => {
    await program.methods
      .submitForCommunityVote()
      .accountsStrict({ signer: deployer, proposal: proposalPda })
      .rpc();

    const p = await program.account.proposal.fetch(proposalPda);
    expect(p.status).to.deep.equal({ communityVote: {} });
    expect(p.communityVoteEnd.toNumber()).to.be.greaterThan(p.communityVoteStart.toNumber());
  });

  it("Updates proposal status after vote", async () => {
    await program.methods
      .updateProposalStatus(
        { active: {} },
        new anchor.BN(80),
        new anchor.BN(10),
        new anchor.BN(5),
      )
      .accountsStrict({ authority: deployer, proposal: proposalPda })
      .rpc();

    const p = await program.account.proposal.fetch(proposalPda);
    expect(p.status).to.deep.equal({ active: {} });
    expect(p.votesFor.toNumber()).to.equal(80);
    expect(p.votesAgainst.toNumber()).to.equal(10);
  });

  it("Cancels the proposal", async () => {
    await program.methods
      .cancelProposal()
      .accountsStrict({ signer: deployer, proposal: proposalPda })
      .rpc();

    const p = await program.account.proposal.fetch(proposalPda);
    expect(p.status).to.deep.equal({ canceled: {} });
  });
});
