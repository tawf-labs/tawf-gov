import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { DonationReceiptNft } from "../target/types/donation_receipt_nft";
import { PublicKey } from "@solana/web3.js";
import { expect } from "chai";

describe("donation-receipt-nft", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.donationReceiptNft as Program<DonationReceiptNft>;
  const donor = anchor.web3.Keypair.generate();

  before(async () => {
    const sig = await provider.connection.requestAirdrop(donor.publicKey, 10 * anchor.web3.LAMPORTS_PER_SOL);
    await provider.connection.confirmTransaction(sig);
  });

  it("Mints a donation receipt", async () => {
    const poolId = new anchor.BN(1);
    const [receiptPda] = PublicKey.findProgramAddressSync(
      [Buffer.from("receipt"), donor.publicKey.toBuffer(), poolId.toArrayLike(Buffer, "le", 8)],
      program.programId
    );

    const tx = await program.methods
      .mintReceipt(poolId, new anchor.BN(50_000_000_000), "Build Mosque", "Zakat", "ipfs://receipt-meta")
      .accountsStrict({
        minter: donor.publicKey,
        donor: donor.publicKey,
        receipt: receiptPda,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .signers([donor])
      .rpc();

    console.log("Receipt minted TX:", tx);

    const r = await program.account.donationReceipt.fetch(receiptPda);
    expect(r.amount.toNumber()).to.equal(50_000_000_000);
    expect(r.campaignTitle).to.equal("Build Mosque");
  });
});
