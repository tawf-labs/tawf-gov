// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IZKShariaDAO
 * @notice Interface for ZK Sharia DAO
 * @dev Private voting by Sharia council using zero-knowledge proofs
 */
interface IZKShariaDAO {
    enum ReviewStatus {
        Pending,
        UnderReview,
        Approved,
        Rejected,
        Vetoed
    }

    struct ShariaReview {
        uint256 proposalId;
        ReviewStatus status;
        uint256 reviewTimestamp;
        bytes32 zkProofHash;
        string justificationURI;
    }

    // Events
    event ReviewSubmitted(uint256 indexed proposalId, ReviewStatus status, bytes32 zkProofHash);
    event CouncilMemberAdded(address indexed member);
    event CouncilMemberRemoved(address indexed member);
    event EmergencyVeto(uint256 indexed proposalId, string reason);

    // Errors
    error NotCouncilMember();
    error InvalidProof();
    error AlreadyReviewed();
    error Unauthorized();

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
    ) external;

    /**
     * @notice Emergency veto power
     * @param proposalId ID of the proposal to veto
     * @param reason Reason for veto
     */
    function emergencyVeto(uint256 proposalId, string calldata reason) external;

    /**
     * @notice Add a council member
     * @param member Address to add
     */
    function addCouncilMember(address member) external;

    /**
     * @notice Remove a council member
     * @param member Address to remove
     */
    function removeCouncilMember(address member) external;

    /**
     * @notice Check if address is a council member
     * @param member Address to check
     */
    function isCouncilMember(address member) external view returns (bool);

    /**
     * @notice Get review for a proposal
     * @param proposalId ID of the proposal
     */
    function getReview(uint256 proposalId) external view returns (ShariaReview memory);
}
