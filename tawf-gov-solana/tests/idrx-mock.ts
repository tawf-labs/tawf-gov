import * as anchor from "@anchor-lang/core";
import { Program } from "@anchor-lang/core";
import { IdrxMock } from "../target/types/idrx_mock";
import {
  getAssociatedTokenAddressSync,
  getMint,
  createAssociatedTokenAccount,
} from "@solana/spl-token";
import { PublicKey } from "@solana/web3.js";

const TOKEN_2022_PROGRAM_ID = new PublicKey("TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb");

describe("idrx-mock", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.idrxMock as Program<IdrxMock>;
  const wallet = provider.wallet.publicKey;

  const [mintPda] = PublicKey.findProgramAddressSync(
    [Buffer.from("idrx-mint")],
    program.programId
  );
  const [authorityPda] = PublicKey.findProgramAddressSync(
    [Buffer.from("idrx-authority")],
    program.programId
  );

  it("Initializes the IDRX mock mint (idempotent)", async () => {
    const existing = await provider.connection.getAccountInfo(mintPda);
    if (existing) {
      console.log("Mint already exists, skipping init");
      return;
    }

    const tx = await program.methods
      .initializeMint()
      .accountsStrict({
        payer: wallet,
        mint: mintPda,
        mintAuthority: authorityPda,
        systemProgram: anchor.web3.SystemProgram.programId,
        tokenProgram: TOKEN_2022_PROGRAM_ID,
        rent: anchor.web3.SYSVAR_RENT_PUBKEY,
      })
      .rpc();

    console.log("Mint initialized. TX:", tx);

    const mint = await getMint(provider.connection, mintPda, undefined, TOKEN_2022_PROGRAM_ID);
    console.log("Mint decimals:", mint.decimals);
    console.log("Mint authority:", mint.mintAuthority!.toBase58());
  });

  it("Mints IDRX to the wallet's ATA", async () => {
    const amount = new anchor.BN(100_000_000_000); // 100,000 IDRX

    const ata = getAssociatedTokenAddressSync(mintPda, wallet, false, TOKEN_2022_PROGRAM_ID);

    const ataInfo = await provider.connection.getAccountInfo(ata);
    if (!ataInfo) {
      const sig = await createAssociatedTokenAccount(
        provider.connection,
        provider.wallet.payer,
        mintPda,
        wallet,
        undefined,
        TOKEN_2022_PROGRAM_ID
      );
      console.log("ATA created. TX:", sig);
    }

    const tx = await program.methods
      .mintTo(amount)
      .accountsStrict({
        authority: wallet,
        mint: mintPda,
        mintAuthority: authorityPda,
        recipientTokenAccount: ata,
        tokenProgram: TOKEN_2022_PROGRAM_ID,
      })
      .rpc();

    console.log("Minted. TX:", tx);

    const balance = await provider.connection.getTokenAccountBalance(ata);
    console.log("Recipient balance:", balance.value.uiAmountString, "IDRX");
  });
});
