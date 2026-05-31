// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;
import "forge-std/Script.sol";
import "../src/tokens/MockIDRX.sol";
import "../src/identity/TawfPassport.sol";
import "../src/identity/TawfReputation.sol";
import "../src/tokens/VotingNFT.sol";
import "../src/protocol/DonationReceiptNFT.sol";
import "../src/governance/ProposalManager.sol";
import "../src/governance/VotingManager.sol";
import "../src/governance/MilestoneManager.sol";
import "../src/governance/ParticipationTracker.sol";
import "../src/protocol/PoolManager.sol";
import "../src/protocol/ZakatEscrowManager.sol";

contract DeployTawfSystem is Script {
    function run() external {
        address deployer = msg.sender;
        console.log("=== Tawf System Deploy ===");
        console.log("Deployer:", deployer);

        vm.startBroadcast();

        // 1. Tokens
        MockIDRX idrx = new MockIDRX();
        DonationReceiptNFT receiptNFT = new DonationReceiptNFT();

        // 2. Identity
        TawfPassport passport = new TawfPassport();
        TawfReputation reputation = new TawfReputation(address(passport));
        VotingNFT votingNFT = new VotingNFT();

        // 3. Governance
        ProposalManager pm = new ProposalManager();
        pm.setTawfPassport(address(passport));
        VotingManager vmgr = new VotingManager(address(pm), address(votingNFT));
        MilestoneManager mm = new MilestoneManager(address(pm), address(votingNFT));
        ParticipationTracker tracker = new ParticipationTracker();

        // 4. Protocol
        PoolManager poolMgr = new PoolManager(address(pm), address(idrx), address(receiptNFT));
        ZakatEscrowManager escrow = new ZakatEscrowManager(address(pm), address(idrx), address(receiptNFT));

        // 5. Role grants — ZKTCore gets all sub-contract roles
        // (ZKTCore will be deployed separately by zkt-hackathon)
        // Grant deployer temporary admin roles for setup
        pm.grantRole(pm.ORGANIZER_ROLE(), deployer);
        pm.grantRole(pm.ADMIN_ROLE(), deployer);
        pm.grantRole(pm.KYC_ORACLE_ROLE(), deployer);
        pm.grantRole(pm.VOTING_MANAGER_ROLE(), address(vmgr));

        receiptNFT.grantRole(receiptNFT.MINTER_ROLE(), deployer);
        receiptNFT.grantRole(receiptNFT.MINTER_ROLE(), address(poolMgr));
        receiptNFT.grantRole(receiptNFT.MINTER_ROLE(), address(escrow));

        votingNFT.grantRole(votingNFT.MINTER_ROLE(), deployer);
        votingNFT.grantRole(votingNFT.ADMIN_ROLE(), deployer);
        votingNFT.grantRole(votingNFT.UPGRADER_ROLE(), deployer);

        poolMgr.grantRole(poolMgr.ADMIN_ROLE(), deployer);
        poolMgr.grantRole(poolMgr.CORE_ROLE(), deployer);

        escrow.grantRole(escrow.ADMIN_ROLE(), deployer);
        escrow.grantRole(escrow.SHARIA_COUNCIL_ROLE(), deployer);
        escrow.setDefaultFallbackPool(deployer);

        mm.grantRole(mm.ORGANIZER_ROLE(), deployer);

        tracker.grantRole(tracker.TRACKER_ROLE(), deployer);
        tracker.grantRole(tracker.VERIFIER_ROLE(), deployer);

        // Issue a ShariaCouncil passport to deployer for testing
        passport.issuePassport(deployer, PassportType.ShariaCouncil, "ipfs://deployer-sharia-council");
        passport.setVerified(deployer, true);

        // Set W3C Verifiable Credential issuer DID
        passport.setIssuerDID("did:ethr:0x0000000000000000000000000000000000000000");

        // Issue a sample W3C Verifiable Credential to deployer
        passport.issueCredential(deployer, bytes32(uint256(1)), "ipfs://vc-deployer-sharia-council");

        vm.stopBroadcast();

        console.log("\n=== Deployed Addresses ===");
        console.log("MockIDRX:", address(idrx));
        console.log("TawfPassport:", address(passport));
        console.log("TawfReputation:", address(reputation));
        console.log("VotingNFT:", address(votingNFT));
        console.log("DonationReceiptNFT:", address(receiptNFT));
        console.log("ProposalManager:", address(pm));
        console.log("VotingManager:", address(vmgr));
        console.log("MilestoneManager:", address(mm));
        console.log("ParticipationTracker:", address(tracker));
        console.log("PoolManager:", address(poolMgr));
        console.log("ZakatEscrowManager:", address(escrow));
    }
}
