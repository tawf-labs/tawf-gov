import * as anchor from "@anchor-lang/core";
import { Program } from "@anchor-lang/core";
import { MilestoneManager } from "../target/types/milestone_manager";
import { PublicKey } from "@solana/web3.js";
import { expect } from "chai";

describe("milestone-manager", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.milestoneManager as Program<MilestoneManager>;
  const voter = anchor.web3.Keypair.generate();
  const voterPubkey = voter.publicKey;
  const proposalPubkey = anchor.web3.Keypair.generate().publicKey;
  const milestoneId = new anchor.BN(0);

  const [votePda] = PublicKey.findProgramAddressSync(
    [Buffer.from("milestone-vote"), proposalPubkey.toBuffer(), Uint8Array.from([0,0,0,0,0,0,0,0]), voterPubkey.toBuffer()],
    program.programId
  );

  before(async () => {
    const sig = await provider.connection.requestAirdrop(voterPubkey, 10 * anchor.web3.LAMPORTS_PER_SOL);
    await provider.connection.confirmTransaction(sig);
  });

  it("Casts milestone vote", async () => {
    const tx = await program.methods
      .castMilestoneVote(milestoneId, { support: {} }, 2)
      .accountsStrict({
        voter: voterPubkey,
        proposal: proposalPubkey,
        vote: votePda,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .signers([voter])
      .rpc();

    console.log("Milestone vote cast TX:", tx);

    const vote = await program.account.milestoneVote.fetch(votePda);
    expect(vote.voter.toBase58()).to.equal(voterPubkey.toBase58());
    expect(vote.weight).to.equal(2);
    expect(vote.milestoneId.toNumber()).to.equal(0);
  });

  it("Finalizes milestone vote", async () => {
    const tx = await program.methods
      .finalizeMilestoneVote(milestoneId, new anchor.BN(50), new anchor.BN(10), new anchor.BN(5), 10, 51, new anchor.BN(30))
      .accountsStrict({ caller: provider.wallet.publicKey, proposal: proposalPubkey })
      .rpc();

    console.log("Finalized milestone vote TX:", tx);
  });
});
