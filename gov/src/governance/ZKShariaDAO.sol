// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IZKShariaDAO.sol";
import "../interfaces/IProposalRegistry.sol";

/**
 * @title ZKShariaDAO
 * @notice ZK Sharia DAO Contract
 * @dev Private voting by Sharia council using zero-knowledge proofs
 */
contract ZKShariaDAO is AccessControl, ReentrancyGuard, IZKShariaDAO {
    bytes32 public constant COUNCIL_ROLE = keccak256("COUNCIL_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IProposalRegistry public immutable proposalRegistry;

    // Sharia review storage
    mapping(uint256 => ShariaReview) private _reviews;
    
    // Council members
    address[] private _councilMembers;
    mapping(address => bool) private _isCouncilMember;

    // Minimum council votes required
    uint256 public minCouncilVotes;

    constructor(address _proposalRegistry, uint256 _minCouncilVotes) {
        proposalRegistry = IProposalRegistry(_proposalRegistry);
        minCouncilVotes = _minCouncilVotes;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Submit a Sharia compliance review with ZK proof
     * @param proposalId ID of the proposal to review
     * @param status Review decision
     * @param zkProofHash Hash of the zero-knowledge proof
     * @param justificationURI IPFS URI with justification
     */
    function submitReview(
        uint256 proposalId,
        ReviewStatus status,
        bytes32 zkProofHash,
        string calldata justificationURI
    ) external onlyRole(COUNCIL_ROLE) nonReentrant {
        if (_reviews[proposalId].reviewTimestamp != 0) revert AlreadyReviewed();
        if (zkProofHash == bytes32(0)) revert InvalidProof();

        _reviews[proposalId] = ShariaReview({
            proposalId: proposalId,
            status: status,
            reviewTimestamp: block.timestamp,
            zkProofHash: zkProofHash,
            justificationURI: justificationURI
        });

        // Update proposal status in registry based on review
        if (status == ReviewStatus.Approved) {
            proposalRegistry.updateProposalStatus(proposalId, IProposalRegistry.ProposalStatus.Approved);
        } else if (status == ReviewStatus.Rejected) {
            proposalRegistry.updateProposalStatus(proposalId, IProposalRegistry.ProposalStatus.Rejected);
        }

        emit ReviewSubmitted(proposalId, status, zkProofHash);
    }

    /**
     * @notice Emergency veto power
     * @param proposalId ID of the proposal to veto
     * @param reason Reason for veto
     */
    function emergencyVeto(uint256 proposalId, string calldata reason)
        external
        onlyRole(ADMIN_ROLE)
        nonReentrant
    {
        _reviews[proposalId] = ShariaReview({
            proposalId: proposalId,
            status: ReviewStatus.Vetoed,
            reviewTimestamp: block.timestamp,
            zkProofHash: bytes32(0),
            justificationURI: reason
        });

        proposalRegistry.updateProposalStatus(proposalId, IProposalRegistry.ProposalStatus.Rejected);

        emit EmergencyVeto(proposalId, reason);
    }

    /**
     * @notice Add a council member
     * @param member Address to add
     */
    function addCouncilMember(address member) external onlyRole(ADMIN_ROLE) {
        if (_isCouncilMember[member]) revert AlreadyReviewed();

        _councilMembers.push(member);
        _isCouncilMember[member] = true;
        _grantRole(COUNCIL_ROLE, member);

        emit CouncilMemberAdded(member);
    }

    /**
     * @notice Remove a council member
     * @param member Address to remove
     */
    function removeCouncilMember(address member) external onlyRole(ADMIN_ROLE) {
        if (!_isCouncilMember[member]) revert NotCouncilMember();

        _isCouncilMember[member] = false;
        _revokeRole(COUNCIL_ROLE, member);

        // Remove from array
        for (uint256 i = 0; i < _councilMembers.length; i++) {
            if (_councilMembers[i] == member) {
                _councilMembers[i] = _councilMembers[_councilMembers.length - 1];
                _councilMembers.pop();
                break;
            }
        }

        emit CouncilMemberRemoved(member);
    }

    /**
     * @notice Check if address is a council member
     * @param member Address to check
     */
    function isCouncilMember(address member) external view returns (bool) {
        return _isCouncilMember[member];
    }

    /**
     * @notice Get review for a proposal
     * @param proposalId ID of the proposal
     */
    function getReview(uint256 proposalId) external view returns (ShariaReview memory) {
        return _reviews[proposalId];
    }

    /**
     * @notice Get all council members
     */
    function getCouncilMembers() external view returns (address[] memory) {
        return _councilMembers;
    }

    /**
     * @notice Get council size
     */
    function getCouncilSize() external view returns (uint256) {
        return _councilMembers.length;
    }

    /**
     * @notice Update minimum council votes
     * @param _minCouncilVotes New minimum
     */
    function updateMinCouncilVotes(uint256 _minCouncilVotes) external onlyRole(ADMIN_ROLE) {
        minCouncilVotes = _minCouncilVotes;
    }

    /**
     * @notice Verify ZK proof (simplified - would integrate with actual ZK verification)
     * @param zkProofHash Hash to verify
     */
    function verifyZKProof(bytes32 zkProofHash) external pure returns (bool) {
        // In production, this would verify against an actual ZK proof
        // For now, we just check it's not empty
        return zkProofHash != bytes32(0);
    }
}
