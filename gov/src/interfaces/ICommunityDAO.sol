// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ICommunityDAO
 * @notice Interface for Community DAO Governance
 * @dev Allows community members to create and vote on proposals
 */
interface ICommunityDAO {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Executed
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        uint256 startBlock;
        uint256 endBlock;
        ProposalState state;
        bytes callData;
    }

    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string title,
        uint256 startBlock,
        uint256 endBlock
    );
    event VoteCast(address indexed voter, uint256 indexed proposalId, uint8 support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    // Errors
    error InsufficientReputation();
    error ProposalNotActive();
    error AlreadyVoted();
    error InvalidProposal();
    error Unauthorized();

    /**
     * @notice Create a new proposal
     * @param title Proposal title
     * @param description Proposal description
     * @param callData Encoded call data for execution
     */
    function propose(string calldata title, string calldata description, bytes calldata callData)
        external
        returns (uint256 proposalId);

    /**
     * @notice Cast a vote on a proposal
     * @param proposalId ID of the proposal
     * @param support 0 = Against, 1 = For, 2 = Abstain
     */
    function castVote(uint256 proposalId, uint8 support) external;

    /**
     * @notice Get proposal details
     * @param proposalId ID of the proposal
     */
    function getProposal(uint256 proposalId) external view returns (Proposal memory);

    /**
     * @notice Get proposal state
     * @param proposalId ID of the proposal
     */
    function state(uint256 proposalId) external view returns (ProposalState);
}
