import * as anchor from "@anchor-lang/core";
import { Program } from "@anchor-lang/core";
import { TawfPassport } from "../target/types/tawf_passport";
import { PublicKey } from "@solana/web3.js";
import { expect } from "chai";

describe("tawf-passport", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.tawfPassport as Program<TawfPassport>;
  const deployer = provider.wallet.publicKey;

  const holder = anchor.web3.Keypair.generate();
  const holderPubkey = holder.publicKey;

  const [passportPda] = PublicKey.findProgramAddressSync(
    [Buffer.from("passport"), holderPubkey.toBuffer()],
    program.programId
  );

  async function airdrop(keypair: anchor.web3.Keypair) {
    const sig = await provider.connection.requestAirdrop(keypair.publicKey, 10 * anchor.web3.LAMPORTS_PER_SOL);
    await provider.connection.confirmTransaction(sig);
  }

  before(async () => {
    await airdrop(holder);
  });

  it("Issues a passport", async () => {
    const tx = await program.methods
      .issuePassport({ individual: {} }, "ipfs://metadata-uri")
      .accountsStrict({
        issuer: deployer,
        holder: holderPubkey,
        passport: passportPda,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .rpc();

    console.log("Passport issued TX:", tx);

    const passport = await program.account.passport.fetch(passportPda);
    expect(passport.holder.toBase58()).to.equal(holderPubkey.toBase58());
    expect(passport.verified).to.be.false;
    expect(passport.metadataUri).to.equal("ipfs://metadata-uri");
  });

  it("Set verified", async () => {
    await program.methods
      .setVerified(true)
      .accountsStrict({
        admin: deployer,
        passport: passportPda,
      })
      .rpc();

    const passport = await program.account.passport.fetch(passportPda);
    expect(passport.verified).to.be.true;
  });

  it("Sets issuer DID", async () => {
    await program.methods
      .setIssuerDid("did:example:123")
      .accountsStrict({
        admin: deployer,
        passport: passportPda,
      })
      .rpc();

    const passport = await program.account.passport.fetch(passportPda);
    expect(passport.issuerDid).to.equal("did:example:123");
  });

  it("Issues a credential", async () => {
    const hash = anchor.web3.Keypair.generate().publicKey.toBytes().slice(0, 32) as any;

    await program.methods
      .issueCredential([...hash] as any, "ipfs://credential-vc")
      .accountsStrict({
        issuer: deployer,
        passport: passportPda,
      })
      .rpc();

    const passport = await program.account.passport.fetch(passportPda);
    expect(passport.credentials.length).to.equal(1);
    expect(passport.credentials[0].valid).to.be.true;
  });

  it("Renounces passport", async () => {
    const tx = await program.methods
      .renouncePassport()
      .accountsStrict({
        holder: holderPubkey,
        passport: passportPda,
      })
      .signers([holder])
      .rpc();

    console.log("Renounced TX:", tx);
  });
});
