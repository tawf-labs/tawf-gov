import * as anchor from "@anchor-lang/core";
import { Program } from "@anchor-lang/core";
import { VotingManager } from "../target/types/voting_manager";
import { PublicKey } from "@solana/web3.js";
import { expect } from "chai";

describe("voting-manager", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.votingManager as Program<VotingManager>;
  const voter = anchor.web3.Keypair.generate();
  const voterPubkey = voter.publicKey;

  const proposalPubkey = anchor.web3.Keypair.generate().publicKey;

  const [votePda] = PublicKey.findProgramAddressSync(
    [Buffer.from("vote"), proposalPubkey.toBuffer(), voterPubkey.toBuffer()],
    program.programId
  );

  before(async () => {
    const sig = await provider.connection.requestAirdrop(voterPubkey, 10 * anchor.web3.LAMPORTS_PER_SOL);
    await provider.connection.confirmTransaction(sig);
  });

  it("Casts a vote (For, weight 2)", async () => {
    const tx = await program.methods
      .castVote({ support: {} }, 2)
      .accountsStrict({
        voter: voterPubkey,
        proposal: proposalPubkey,
        vote: votePda,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .signers([voter])
      .rpc();

    console.log("Vote cast TX:", tx);

    const vote = await program.account.vote.fetch(votePda);
    expect(vote.voter.toBase58()).to.equal(voterPubkey.toBase58());
    expect(vote.proposal.toBase58()).to.equal(proposalPubkey.toBase58());
    expect(vote.weight).to.equal(2);
  });

  it("Finalizes the vote", async () => {
    const tx = await program.methods
      .finalizeVote(
        new anchor.BN(100),
        new anchor.BN(30),
        new anchor.BN(10),
        10,
        51,
        new anchor.BN(50),
      )
      .accountsStrict({
        caller: provider.wallet.publicKey,
        proposal: proposalPubkey,
      })
      .rpc();

    console.log("Finalized TX:", tx);
  });
});
