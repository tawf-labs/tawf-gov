// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IProposalRegistry.sol";
import "../interfaces/ICommunityDAO.sol";

/**
 * @title ProposalRegistry
 * @notice Proposal Registry and Batching Contract
 * @dev Manages proposal lifecycle and batching for efficient execution
 */
contract ProposalRegistry is AccessControl, ReentrancyGuard, IProposalRegistry {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    ICommunityDAO public immutable communityDAO;

    // Proposal storage
    mapping(uint256 => RegisteredProposal) private _proposals;
    uint256 private _proposalCount;

    // Batch storage
    mapping(uint256 => uint256[]) private _batches;
    uint256 private _batchCount;

    // Mapping from community proposal ID to registry proposal ID
    mapping(uint256 => uint256) private _communityToRegistryId;

    constructor(address _communityDAO) {
        communityDAO = ICommunityDAO(_communityDAO);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(EXECUTOR_ROLE, msg.sender);
    }

    /**
     * @notice Register a proposal from Community DAO
     * @param communityProposalId ID from Community DAO
     * @param callData Encoded call data
     */
    function registerProposal(uint256 communityProposalId, bytes calldata callData)
        external
        onlyRole(ADMIN_ROLE)
        nonReentrant
        returns (uint256 id)
    {
        // Verify proposal exists in Community DAO
        ICommunityDAO.Proposal memory proposal = communityDAO.getProposal(communityProposalId);
        
        _proposalCount++;
        id = _proposalCount;

        _proposals[id] = RegisteredProposal({
            id: id,
            communityProposalId: communityProposalId,
            proposer: proposal.proposer,
            status: ProposalStatus.Registered,
            timestamp: block.timestamp,
            batchId: 0,
            callData: callData
        });

        _communityToRegistryId[communityProposalId] = id;

        emit ProposalRegistered(id, communityProposalId, proposal.proposer);
    }

    /**
     * @notice Create a batch of proposals
     * @param proposalIds Array of proposal IDs to batch
     */
    function createBatch(uint256[] calldata proposalIds)
        external
        onlyRole(ADMIN_ROLE)
        nonReentrant
        returns (uint256 batchId)
    {
        if (proposalIds.length == 0) revert InvalidStatus();

        _batchCount++;
        batchId = _batchCount;

        for (uint256 i = 0; i < proposalIds.length; i++) {
            uint256 proposalId = proposalIds[i];
            
            if (proposalId == 0 || proposalId > _proposalCount) revert ProposalNotFound();
            
            RegisteredProposal storage proposal = _proposals[proposalId];
            
            if (proposal.status != ProposalStatus.Approved) revert InvalidStatus();
            if (proposal.batchId != 0) revert AlreadyBatched();

            proposal.status = ProposalStatus.Batched;
            proposal.batchId = batchId;

            _batches[batchId].push(proposalId);
            
            emit ProposalBatched(proposalId, batchId);
        }

        emit BatchCreated(batchId, proposalIds);
    }

    /**
     * @notice Execute a batch
     * @param batchId ID of the batch to execute
     */
    function executeBatch(uint256 batchId) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        if (batchId == 0 || batchId > _batchCount) revert InvalidStatus();

        uint256[] memory proposalIds = _batches[batchId];
        
        for (uint256 i = 0; i < proposalIds.length; i++) {
            uint256 proposalId = proposalIds[i];
            RegisteredProposal storage proposal = _proposals[proposalId];
            
            if (proposal.status == ProposalStatus.Batched) {
                proposal.status = ProposalStatus.Executed;
            }
        }

        emit BatchExecuted(batchId);
    }

    /**
     * @notice Update proposal status
     * @param proposalId ID of the proposal
     * @param status New status
     */
    function updateProposalStatus(uint256 proposalId, ProposalStatus status)
        external
        onlyRole(ADMIN_ROLE)
    {
        if (proposalId == 0 || proposalId > _proposalCount) revert ProposalNotFound();

        _proposals[proposalId].status = status;
        emit ProposalStatusChanged(proposalId, status);
    }

    /**
     * @notice Get proposal details
     * @param proposalId ID of the proposal
     */
    function getProposal(uint256 proposalId) external view returns (RegisteredProposal memory) {
        if (proposalId == 0 || proposalId > _proposalCount) revert ProposalNotFound();
        return _proposals[proposalId];
    }

    /**
     * @notice Get batch proposals
     * @param batchId ID of the batch
     */
    function getBatch(uint256 batchId) external view returns (uint256[] memory) {
        if (batchId == 0 || batchId > _batchCount) revert InvalidStatus();
        return _batches[batchId];
    }

    /**
     * @notice Get registry ID from community proposal ID
     * @param communityProposalId Community DAO proposal ID
     */
    function getRegistryId(uint256 communityProposalId) external view returns (uint256) {
        return _communityToRegistryId[communityProposalId];
    }

    /**
     * @notice Get total proposal count
     */
    function getProposalCount() external view returns (uint256) {
        return _proposalCount;
    }

    /**
     * @notice Get total batch count
     */
    function getBatchCount() external view returns (uint256) {
        return _batchCount;
    }
}
