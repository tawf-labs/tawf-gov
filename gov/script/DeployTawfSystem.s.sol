// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Script.sol";
import "../src/identity/TawfDID.sol";
import "../src/identity/TawfReputation.sol";
import "../src/governance/CommunityDAO.sol";
import "../src/governance/ProposalRegistry.sol";
import "../src/governance/ZKShariaDAO.sol";
import "../src/protocol/WakafTreasury.sol";
import "../src/protocol/CampaignManager.sol";
import "../src/protocol/VendorRegistry.sol";
import "../src/protocol/NFTReceiptIssuer.sol";
import "../src/admin/ProtocolAdmin.sol";
import "../src/admin/TawfLabsMultisig.sol";

/**
 * @title DeployTawfSystem
 * @notice Deployment script for the entire Tawf governance system
 */
contract DeployTawfSystem is Script {
    // Deployment addresses
    TawfDID public didContract;
    TawfReputation public reputationContract;
    CommunityDAO public communityDAO;
    ProposalRegistry public proposalRegistry;
    ZKShariaDAO public zkShariaDAO;
    WakafTreasury public wakafTreasury;
    CampaignManager public campaignManager;
    VendorRegistry public vendorRegistry;
    NFTReceiptIssuer public nftReceiptIssuer;
    ProtocolAdmin public protocolAdmin;
    TawfLabsMultisig public multisig;

    // Governance parameters
    uint256 public constant PROPOSAL_THRESHOLD = 100; // Minimum reputation to propose
    uint256 public constant VOTING_DELAY = 1; // 1 block delay
    uint256 public constant VOTING_PERIOD = 50400; // ~7 days (assuming 12s blocks)
    uint256 public constant QUORUM_VOTES = 1000; // Minimum votes for quorum
    uint256 public constant MIN_COUNCIL_VOTES = 3; // Minimum Sharia council votes

    // Multisig parameters
    address[] public initialSigners;
    uint256 public constant MULTISIG_THRESHOLD = 2; // 2-of-N multisig

    function setUp() public {
        // Setup initial multisig signers (should be replaced with actual addresses)
        initialSigners = new address[](3);
        initialSigners[0] = address(0x1); // Replace with actual signer
        initialSigners[1] = address(0x2); // Replace with actual signer
        initialSigners[2] = address(0x3); // Replace with actual signer
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying Tawf Governance System...");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // ======================================
        // 1. Deploy Identity Layer
        // ======================================
        console.log("\n=== Deploying Identity Layer ===");
        
        didContract = new TawfDID();
        console.log("TawfDID deployed at:", address(didContract));

        reputationContract = new TawfReputation(address(didContract));
        console.log("TawfReputation deployed at:", address(reputationContract));

        // ======================================
        // 2. Deploy Admin Layer
        // ======================================
        console.log("\n=== Deploying Admin Layer ===");
        
        protocolAdmin = new ProtocolAdmin();
        console.log("ProtocolAdmin deployed at:", address(protocolAdmin));

        multisig = new TawfLabsMultisig(initialSigners, MULTISIG_THRESHOLD);
        console.log("TawfLabsMultisig deployed at:", address(multisig));

        // ======================================
        // 3. Deploy Protocol Layer
        // ======================================
        console.log("\n=== Deploying Protocol Layer ===");
        
        vendorRegistry = new VendorRegistry(address(didContract));
        console.log("VendorRegistry deployed at:", address(vendorRegistry));

        nftReceiptIssuer = new NFTReceiptIssuer();
        console.log("NFTReceiptIssuer deployed at:", address(nftReceiptIssuer));

        campaignManager = new CampaignManager(
            address(vendorRegistry),
            address(nftReceiptIssuer)
        );
        console.log("CampaignManager deployed at:", address(campaignManager));

        wakafTreasury = new WakafTreasury();
        console.log("WakafTreasury deployed at:", address(wakafTreasury));

        // ======================================
        // 4. Deploy Governance Layer
        // ======================================
        console.log("\n=== Deploying Governance Layer ===");
        
        communityDAO = new CommunityDAO(
            address(didContract),
            address(reputationContract),
            PROPOSAL_THRESHOLD,
            VOTING_DELAY,
            VOTING_PERIOD,
            QUORUM_VOTES
        );
        console.log("CommunityDAO deployed at:", address(communityDAO));

        proposalRegistry = new ProposalRegistry(address(communityDAO));
        console.log("ProposalRegistry deployed at:", address(proposalRegistry));

        zkShariaDAO = new ZKShariaDAO(
            address(proposalRegistry),
            MIN_COUNCIL_VOTES
        );
        console.log("ZKShariaDAO deployed at:", address(zkShariaDAO));

        // ======================================
        // 5. Configure Roles and Permissions
        // ======================================
        console.log("\n=== Configuring Roles and Permissions ===");
        
        // Grant CampaignManager permission to issue receipts
        nftReceiptIssuer.grantRole(
            nftReceiptIssuer.ISSUER_ROLE(),
            address(campaignManager)
        );
        console.log("Granted ISSUER_ROLE to CampaignManager");

        // Grant CampaignManager permission to add campaigns to vendor registry
        vendorRegistry.grantRole(
            vendorRegistry.ADMIN_ROLE(),
            address(campaignManager)
        );
        console.log("Granted ADMIN_ROLE to CampaignManager in VendorRegistry");

        // Grant Multisig admin roles
        protocolAdmin.grantRole(
            protocolAdmin.ADMIN_ROLE(),
            address(multisig)
        );
        console.log("Granted ADMIN_ROLE to Multisig in ProtocolAdmin");

        // Grant reputation manager role to CommunityDAO
        reputationContract.grantRole(
            reputationContract.REPUTATION_MANAGER_ROLE(),
            address(communityDAO)
        );
        console.log("Granted REPUTATION_MANAGER_ROLE to CommunityDAO");

        vm.stopBroadcast();

        // ======================================
        // 6. Print Deployment Summary
        // ======================================
        console.log("\n=== Deployment Summary ===");
        console.log("Identity Layer:");
        console.log("  TawfDID:", address(didContract));
        console.log("  TawfReputation:", address(reputationContract));
        console.log("\nGovernance Layer:");
        console.log("  CommunityDAO:", address(communityDAO));
        console.log("  ProposalRegistry:", address(proposalRegistry));
        console.log("  ZKShariaDAO:", address(zkShariaDAO));
        console.log("\nProtocol Layer:");
        console.log("  WakafTreasury:", address(wakafTreasury));
        console.log("  CampaignManager:", address(campaignManager));
        console.log("  VendorRegistry:", address(vendorRegistry));
        console.log("  NFTReceiptIssuer:", address(nftReceiptIssuer));
        console.log("\nAdmin Layer:");
        console.log("  ProtocolAdmin:", address(protocolAdmin));
        console.log("  TawfLabsMultisig:", address(multisig));
        console.log("\n=== Deployment Complete ===");
    }

    // Helper function to save deployment addresses
    function getDeploymentAddresses() external view returns (
        address _didContract,
        address _reputationContract,
        address _communityDAO,
        address _proposalRegistry,
        address _zkShariaDAO,
        address _wakafTreasury,
        address _campaignManager,
        address _vendorRegistry,
        address _nftReceiptIssuer,
        address _protocolAdmin,
        address _multisig
    ) {
        return (
            address(didContract),
            address(reputationContract),
            address(communityDAO),
            address(proposalRegistry),
            address(zkShariaDAO),
            address(wakafTreasury),
            address(campaignManager),
            address(vendorRegistry),
            address(nftReceiptIssuer),
            address(protocolAdmin),
            address(multisig)
        );
    }
}
