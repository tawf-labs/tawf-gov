// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IProposalRegistry
 * @notice Interface for Proposal Registry and Batching
 * @dev Manages proposal lifecycle and batching for efficient execution
 */
interface IProposalRegistry {
    enum ProposalStatus {
        Registered,
        UnderReview,
        Approved,
        Rejected,
        Batched,
        Executed
    }

    struct RegisteredProposal {
        uint256 id;
        uint256 communityProposalId;
        address proposer;
        ProposalStatus status;
        uint256 timestamp;
        uint256 batchId;
        bytes callData;
    }

    // Events
    event ProposalRegistered(uint256 indexed id, uint256 indexed communityProposalId, address indexed proposer);
    event ProposalBatched(uint256 indexed id, uint256 indexed batchId);
    event BatchCreated(uint256 indexed batchId, uint256[] proposalIds);
    event BatchExecuted(uint256 indexed batchId);
    event ProposalStatusChanged(uint256 indexed id, ProposalStatus status);

    // Errors
    error ProposalNotFound();
    error InvalidStatus();
    error Unauthorized();
    error AlreadyBatched();

    /**
     * @notice Register a proposal from Community DAO
     * @param communityProposalId ID from Community DAO
     * @param callData Encoded call data
     */
    function registerProposal(uint256 communityProposalId, bytes calldata callData)
        external
        returns (uint256 id);

    /**
     * @notice Create a batch of proposals
     * @param proposalIds Array of proposal IDs to batch
     */
    function createBatch(uint256[] calldata proposalIds) external returns (uint256 batchId);

    /**
     * @notice Execute a batch
     * @param batchId ID of the batch to execute
     */
    function executeBatch(uint256 batchId) external;

    /**
     * @notice Update proposal status
     * @param proposalId ID of the proposal
     * @param status New status
     */
    function updateProposalStatus(uint256 proposalId, ProposalStatus status) external;

    /**
     * @notice Get proposal details
     * @param proposalId ID of the proposal
     */
    function getProposal(uint256 proposalId) external view returns (RegisteredProposal memory);
}
