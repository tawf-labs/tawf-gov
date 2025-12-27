// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/governance/CommunityDAO.sol";
import "../src/identity/TawfDID.sol";
import "../src/identity/TawfReputation.sol";

contract CommunityDAOTest is Test {
    CommunityDAO public dao;
    TawfDID public didContract;
    TawfReputation public reputationContract;
    
    address public admin = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public user3 = address(0x4);

    uint256 public constant PROPOSAL_THRESHOLD = 100;
    uint256 public constant VOTING_DELAY = 1;
    uint256 public constant VOTING_PERIOD = 100;
    uint256 public constant QUORUM_VOTES = 300;

    function setUp() public {
        vm.startPrank(admin);
        
        // Deploy contracts
        didContract = new TawfDID();
        reputationContract = new TawfReputation(address(didContract));
        dao = new CommunityDAO(
            address(didContract),
            address(reputationContract),
            PROPOSAL_THRESHOLD,
            VOTING_DELAY,
            VOTING_PERIOD,
            QUORUM_VOTES
        );

        // Grant reputation manager role to dao
        reputationContract.grantRole(reputationContract.REPUTATION_MANAGER_ROLE(), address(dao));

        // Setup test users with DIDs and reputation
        didContract.issueDID(user1, "ipfs://user1");
        didContract.issueDID(user2, "ipfs://user2");
        didContract.issueDID(user3, "ipfs://user3");

        reputationContract.increaseReputation(user1, 200, "Initial");
        reputationContract.increaseReputation(user2, 150, "Initial");
        reputationContract.increaseReputation(user3, 150, "Initial");

        vm.stopPrank();
    }

    function test_CreateProposal() public {
        vm.startPrank(user1);
        
        string memory title = "Test Proposal";
        string memory description = "This is a test proposal";
        bytes memory callData = abi.encodeWithSignature("test()");

        uint256 proposalId = dao.propose(title, description, callData);
        
        assertEq(proposalId, 1);
        
        ICommunityDAO.Proposal memory proposal = dao.getProposal(proposalId);
        assertEq(proposal.proposer, user1);
        assertEq(proposal.title, title);
        assertEq(proposal.description, description);
        
        vm.stopPrank();
    }

    function test_RevertWhen_InsufficientReputationToPropose() public {
        vm.startPrank(admin);
        address lowRepUser = address(0x5);
        didContract.issueDID(lowRepUser, "ipfs://lowrep");
        reputationContract.increaseReputation(lowRepUser, 50, "Low");
        vm.stopPrank();

        vm.startPrank(lowRepUser);
        
        vm.expectRevert(ICommunityDAO.InsufficientReputation.selector);
        dao.propose("Title", "Description", "");
        
        vm.stopPrank();
    }

    function test_CastVote() public {
        // Create proposal
        vm.prank(user1);
        uint256 proposalId = dao.propose("Title", "Description", "");

        // Wait for voting to start
        vm.roll(block.number + VOTING_DELAY + 1);

        // Vote
        vm.prank(user2);
        dao.castVote(proposalId, 1); // Vote "For"

        ICommunityDAO.Proposal memory proposal = dao.getProposal(proposalId);
        assertEq(proposal.forVotes, 150); // user2's reputation

        assertTrue(dao.hasVoted(proposalId, user2));
    }

    function test_RevertWhen_AlreadyVoted() public {
        vm.prank(user1);
        uint256 proposalId = dao.propose("Title", "Description", "");

        vm.roll(block.number + VOTING_DELAY + 1);

        vm.startPrank(user2);
        dao.castVote(proposalId, 1);
        
        vm.expectRevert(ICommunityDAO.AlreadyVoted.selector);
        dao.castVote(proposalId, 1);
        
        vm.stopPrank();
    }

    function test_ProposalSucceeds() public {
        vm.prank(user1);
        uint256 proposalId = dao.propose("Title", "Description", "");

        vm.roll(block.number + VOTING_DELAY + 1);

        // All users vote "For"
        vm.prank(user1);
        dao.castVote(proposalId, 1);
        
        vm.prank(user2);
        dao.castVote(proposalId, 1);
        
        vm.prank(user3);
        dao.castVote(proposalId, 1);

        // Move past voting period
        vm.roll(block.number + VOTING_PERIOD + 1);

        // Check proposal succeeded
        assertEq(uint256(dao.state(proposalId)), uint256(ICommunityDAO.ProposalState.Succeeded));
    }

    function test_ProposalDefeated() public {
        vm.prank(user1);
        uint256 proposalId = dao.propose("Title", "Description", "");

        vm.roll(block.number + VOTING_DELAY + 1);

        // All users vote "Against"
        vm.prank(user1);
        dao.castVote(proposalId, 0);
        
        vm.prank(user2);
        dao.castVote(proposalId, 0);
        
        vm.prank(user3);
        dao.castVote(proposalId, 0);

        // Move past voting period
        vm.roll(block.number + VOTING_PERIOD + 1);

        // Check proposal defeated
        assertEq(uint256(dao.state(proposalId)), uint256(ICommunityDAO.ProposalState.Defeated));
    }

    function test_CancelProposal() public {
        vm.prank(user1);
        uint256 proposalId = dao.propose("Title", "Description", "");

        vm.prank(user1);
        dao.cancel(proposalId);

        assertEq(uint256(dao.state(proposalId)), uint256(ICommunityDAO.ProposalState.Canceled));
    }

    function test_UpdateParameters() public {
        vm.prank(admin);
        dao.updateParameters(200, 2, 200, 500);

        // Verify parameters updated (would need getter functions)
    }
}
