import * as anchor from "@anchor-lang/core";
import { Program } from "@anchor-lang/core";
import { PoolManager } from "../target/types/pool_manager";
import { PublicKey } from "@solana/web3.js";
import { getAssociatedTokenAddressSync } from "@solana/spl-token";
import { expect } from "chai";

const TOKEN_2022_PROGRAM_ID = new PublicKey("TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb");

describe("pool-manager", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.poolManager as Program<PoolManager>;
  const deployer = provider.wallet.publicKey;
  const organizer = anchor.web3.Keypair.generate();

  const [poolPda] = PublicKey.findProgramAddressSync(
    [Buffer.from("pool"), organizer.publicKey.toBuffer()],
    program.programId
  );
  const [vaultPda] = PublicKey.findProgramAddressSync(
    [Buffer.from("vault"), poolPda.toBuffer()],
    program.programId
  );

  // IDRX mock mint + authority
  const idrxProgramId = new PublicKey("84qrLb5tLKCFUXJ1NDhKvp73dLLEi3e5LURZ9cDUEjom");
  const [idrxMint] = PublicKey.findProgramAddressSync([Buffer.from("idrx-mint")], idrxProgramId);
  const [idrxAuthority] = PublicKey.findProgramAddressSync([Buffer.from("idrx-authority")], idrxProgramId);

  const proposalPubkey = anchor.web3.Keypair.generate().publicKey;

  before(async () => {
    const sig = await provider.connection.requestAirdrop(organizer.publicKey, 10 * anchor.web3.LAMPORTS_PER_SOL);
    await provider.connection.confirmTransaction(sig);
  });

  it("Creates a campaign pool", async () => {
    const fundingGoal = new anchor.BN(1_000_000_000_000); // 1M IDRX
    const usesMilestones = false;

    const tx = await program.methods
      .createPool(fundingGoal, usesMilestones)
      .accountsStrict({
        admin: deployer,
        proposal: proposalPubkey,
        idrxMint: idrxMint,
        organizer: organizer.publicKey,
        pool: poolPda,
        systemProgram: anchor.web3.SystemProgram.programId,
        tokenProgram: TOKEN_2022_PROGRAM_ID,
      })
      .rpc();

    console.log("Pool created TX:", tx);

    const pool = await program.account.campaignPool.fetch(poolPda);
    expect(pool.organizer.toBase58()).to.equal(organizer.publicKey.toBase58());
    expect(pool.isActive).to.be.true;
    expect(pool.fundingGoal.toNumber()).to.equal(1_000_000_000_000);
  });
});
