// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ITawfReputation
 * @notice Interface for Tawf Reputation System
 * @dev Tracks reputation scores based on community participation
 */
interface ITawfReputation {
    // Events
    event ReputationIncreased(address indexed user, uint256 amount, string reason);
    event ReputationDecreased(address indexed user, uint256 amount, string reason);
    event ReputationSlashed(address indexed user, uint256 amount, string reason);

    // Errors
    error InsufficientReputation();
    error Unauthorized();
    error InvalidAmount();

    /**
     * @notice Increase reputation for a user
     * @param user Address of the user
     * @param amount Amount to increase
     * @param reason Reason for the increase
     */
    function increaseReputation(address user, uint256 amount, string calldata reason) external;

    /**
     * @notice Decrease reputation for a user
     * @param user Address of the user
     * @param amount Amount to decrease
     * @param reason Reason for the decrease
     */
    function decreaseReputation(address user, uint256 amount, string calldata reason) external;

    /**
     * @notice Slash reputation (penalty)
     * @param user Address of the user
     * @param amount Amount to slash
     * @param reason Reason for the slash
     */
    function slashReputation(address user, uint256 amount, string calldata reason) external;

    /**
     * @notice Get reputation score for a user
     * @param user Address to check
     */
    function getReputation(address user) external view returns (uint256);

    /**
     * @notice Check if user has minimum reputation
     * @param user Address to check
     * @param minReputation Minimum reputation required
     */
    function hasMinimumReputation(address user, uint256 minReputation) external view returns (bool);
}
