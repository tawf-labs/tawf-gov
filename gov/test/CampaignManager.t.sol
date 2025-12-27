// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/protocol/CampaignManager.sol";
import "../src/protocol/VendorRegistry.sol";
import "../src/protocol/NFTReceiptIssuer.sol";
import "../src/identity/TawfDID.sol";

contract CampaignManagerTest is Test {
    CampaignManager public campaignManager;
    VendorRegistry public vendorRegistry;
    NFTReceiptIssuer public receiptIssuer;
    TawfDID public didContract;
    
    address public admin = address(0x1);
    address public vendor1 = address(0x2);
    address public contributor1 = address(0x3);
    address public contributor2 = address(0x4);

    function setUp() public {
        vm.startPrank(admin);
        
        // Deploy contracts
        didContract = new TawfDID();
        vendorRegistry = new VendorRegistry(address(didContract));
        receiptIssuer = new NFTReceiptIssuer();
        campaignManager = new CampaignManager(
            address(vendorRegistry),
            address(receiptIssuer)
        );

        // Grant roles
        receiptIssuer.grantRole(receiptIssuer.ISSUER_ROLE(), address(campaignManager));
        vendorRegistry.grantRole(vendorRegistry.ADMIN_ROLE(), address(campaignManager));

        // Setup vendor
        didContract.issueDID(vendor1, "ipfs://vendor1");
        vm.stopPrank();

        vm.prank(vendor1);
        vendorRegistry.registerVendor("Vendor 1", "ipfs://vendor1-meta");

        vm.prank(admin);
        vendorRegistry.verifyVendor(vendor1);
    }

    function test_CreateCampaign() public {
        vm.startPrank(vendor1);
        
        string memory title = "Test Campaign";
        string memory descriptionURI = "ipfs://campaign1";
        uint256 goal = 10 ether;
        uint256 duration = 30 days;

        uint256 campaignId = campaignManager.createCampaign(title, descriptionURI, goal, duration);
        
        assertEq(campaignId, 1);
        
        ICampaignManager.Campaign memory campaign = campaignManager.getCampaign(campaignId);
        assertEq(campaign.organizer, vendor1);
        assertEq(campaign.title, title);
        assertEq(campaign.goal, goal);
        assertEq(uint256(campaign.status), uint256(ICampaignManager.CampaignStatus.Active));
        
        vm.stopPrank();
    }

    function test_Contribute() public {
        vm.prank(vendor1);
        uint256 campaignId = campaignManager.createCampaign(
            "Test Campaign",
            "ipfs://campaign1",
            10 ether,
            30 days
        );

        vm.deal(contributor1, 2 ether);
        
        vm.prank(contributor1);
        campaignManager.contribute{value: 1 ether}(campaignId);

        ICampaignManager.Campaign memory campaign = campaignManager.getCampaign(campaignId);
        assertEq(campaign.raised, 1 ether);

        ICampaignManager.Contribution memory contribution = 
            campaignManager.getContribution(campaignId, contributor1);
        assertEq(contribution.amount, 1 ether);
        assertEq(contribution.contributor, contributor1);
    }

    function test_MultipleContributions() public {
        vm.prank(vendor1);
        uint256 campaignId = campaignManager.createCampaign(
            "Test Campaign",
            "ipfs://campaign1",
            10 ether,
            30 days
        );

        vm.deal(contributor1, 2 ether);
        vm.deal(contributor2, 2 ether);

        vm.prank(contributor1);
        campaignManager.contribute{value: 1 ether}(campaignId);

        vm.prank(contributor2);
        campaignManager.contribute{value: 0.5 ether}(campaignId);

        ICampaignManager.Campaign memory campaign = campaignManager.getCampaign(campaignId);
        assertEq(campaign.raised, 1.5 ether);
    }

    function test_CampaignCompletes() public {
        vm.prank(vendor1);
        uint256 campaignId = campaignManager.createCampaign(
            "Test Campaign",
            "ipfs://campaign1",
            1 ether,
            30 days
        );

        vm.deal(contributor1, 2 ether);
        
        vm.prank(contributor1);
        campaignManager.contribute{value: 1 ether}(campaignId);

        ICampaignManager.Campaign memory campaign = campaignManager.getCampaign(campaignId);
        assertEq(uint256(campaign.status), uint256(ICampaignManager.CampaignStatus.Completed));
    }

    function test_WithdrawFunds() public {
        vm.prank(vendor1);
        uint256 campaignId = campaignManager.createCampaign(
            "Test Campaign",
            "ipfs://campaign1",
            1 ether,
            30 days
        );

        vm.deal(contributor1, 2 ether);
        
        vm.prank(contributor1);
        campaignManager.contribute{value: 1 ether}(campaignId);

        uint256 balanceBefore = vendor1.balance;

        vm.prank(vendor1);
        campaignManager.withdrawFunds(campaignId);

        assertEq(vendor1.balance, balanceBefore + 1 ether);
    }

    function test_VerifyCampaign() public {
        vm.prank(vendor1);
        uint256 campaignId = campaignManager.createCampaign(
            "Test Campaign",
            "ipfs://campaign1",
            10 ether,
            30 days
        );

        vm.prank(admin);
        campaignManager.verifyCampaign(campaignId);

        ICampaignManager.Campaign memory campaign = campaignManager.getCampaign(campaignId);
        assertTrue(campaign.verified);
    }

    function test_RevertWhen_UnverifiedVendor() public {
        address unverifiedVendor = address(0x5);
        
        vm.startPrank(admin);
        didContract.issueDID(unverifiedVendor, "ipfs://unverified");
        vm.stopPrank();

        vm.prank(unverifiedVendor);
        vendorRegistry.registerVendor("Unverified", "ipfs://meta");

        vm.startPrank(unverifiedVendor);
        
        vm.expectRevert(ICampaignManager.Unauthorized.selector);
        campaignManager.createCampaign("Title", "ipfs://desc", 1 ether, 30 days);
        
        vm.stopPrank();
    }

    function test_RevertWhen_InvalidDuration() public {
        vm.startPrank(vendor1);
        
        vm.expectRevert(ICampaignManager.InvalidAmount.selector);
        campaignManager.createCampaign("Title", "ipfs://desc", 1 ether, 1 hours);
        
        vm.stopPrank();
    }

    function test_PauseUnpause() public {
        vm.startPrank(admin);
        
        campaignManager.pause();
        
        vm.stopPrank();

        vm.startPrank(vendor1);
        
        vm.expectRevert();  // EnforcedPause in newer OZ versions
        campaignManager.createCampaign("Title", "ipfs://desc", 1 ether, 30 days);
        
        vm.stopPrank();

        vm.prank(admin);
        campaignManager.unpause();

        vm.prank(vendor1);
        uint256 campaignId = campaignManager.createCampaign("Title", "ipfs://desc", 1 ether, 30 days);
        assertEq(campaignId, 1);
    }
}
