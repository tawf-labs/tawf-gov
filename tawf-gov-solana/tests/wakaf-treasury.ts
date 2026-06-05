import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { WakafTreasury } from "../target/types/wakaf_treasury";
import { PublicKey } from "@solana/web3.js";
import { expect } from "chai";

const TOKEN_2022_PROGRAM_ID = new PublicKey("TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb");
const IDRX_PROGRAM_ID = new PublicKey("84qrLb5tLKCFUXJ1NDhKvp73dLLEi3e5LURZ9cDUEjom");

describe("wakaf-treasury", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.wakafTreasury as Program<WakafTreasury>;
  const deployer = provider.wallet.publicKey;

  const [treasuryPda] = PublicKey.findProgramAddressSync([Buffer.from("treasury")], program.programId);
  const [treasuryVaultPda] = PublicKey.findProgramAddressSync([Buffer.from("treasury-vault")], program.programId);
  const [idrxMint] = PublicKey.findProgramAddressSync([Buffer.from("idrx-mint")], IDRX_PROGRAM_ID);

  it("Initializes treasury", async () => {
    const tx = await program.methods
      .initialize()
      .accountsStrict({
        admin: deployer,
        idrxMint,
        treasury: treasuryPda,
        systemProgram: anchor.web3.SystemProgram.programId,
        tokenProgram: TOKEN_2022_PROGRAM_ID,
      })
      .rpc();

    console.log("Treasury initialized TX:", tx);
    const t = await program.account.treasury.fetch(treasuryPda);
    expect(t.idrxMint.toBase58()).to.equal(idrxMint.toBase58());
  });

  it("Creates allocation", async () => {
    const recipient = anchor.web3.Keypair.generate().publicKey;
    const [allocPda] = PublicKey.findProgramAddressSync(
      [Buffer.from("allocation"), new anchor.BN(1).toArrayLike(Buffer, "le", 8)],
      program.programId
    );

    const tx = await program.methods
      .createAllocation(new anchor.BN(1), recipient, new anchor.BN(100_000_000_000), "Mosque maintenance")
      .accountsStrict({
        allocator: deployer,
        treasury: treasuryPda,
        recipient,
        allocation: allocPda,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .rpc();

    console.log("Allocation created TX:", tx);
    const a = await program.account.allocation.fetch(allocPda);
    expect(a.amount.toNumber()).to.equal(100_000_000_000);
    expect(a.executed).to.be.false;
  });
});
