import * as anchor from "@anchor-lang/core";
import { Program } from "@anchor-lang/core";
import { ZakatEscrow } from "../target/types/zakat_escrow";
import { PublicKey } from "@solana/web3.js";
import { getAssociatedTokenAddressSync, getMint } from "@solana/spl-token";
import { expect } from "chai";

const TOKEN_2022_PROGRAM_ID = new PublicKey("TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb");
const IDRX_PROGRAM_ID = new PublicKey("84qrLb5tLKCFUXJ1NDhKvp73dLLEi3e5LURZ9cDUEjom");

describe("zakat-escrow", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.zakatEscrow as Program<ZakatEscrow>;
  const deployer = provider.wallet.publicKey;
  const organizer = anchor.web3.Keypair.generate();

  const [poolPda] = PublicKey.findProgramAddressSync(
    [Buffer.from("zakat"), organizer.publicKey.toBuffer()],
    program.programId
  );

  const [idrxMint] = PublicKey.findProgramAddressSync([Buffer.from("idrx-mint")], IDRX_PROGRAM_ID);

  before(async () => {
    const sig = await provider.connection.requestAirdrop(organizer.publicKey, 10 * anchor.web3.LAMPORTS_PER_SOL);
    await provider.connection.confirmTransaction(sig);
  });

  it("Creates a Zakat pool", async () => {
    const tx = await program.methods
      .createZakatPool(new anchor.BN(500_000_000_000))
      .accountsStrict({
        admin: deployer,
        proposal: anchor.web3.Keypair.generate().publicKey,
        idrxMint,
        organizer: organizer.publicKey,
        pool: poolPda,
        systemProgram: anchor.web3.SystemProgram.programId,
        tokenProgram: TOKEN_2022_PROGRAM_ID,
      })
      .rpc();

    console.log("Zakat pool created TX:", tx);

    const pool = await program.account.zakatPool.fetch(poolPda);
    expect(pool.fundingGoal.toNumber()).to.equal(500_000_000_000);
    expect(pool.status).to.deep.equal({ active: {} });
  });
});
