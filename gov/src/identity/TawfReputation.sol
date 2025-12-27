// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/ITawfReputation.sol";
import "../interfaces/ITawfDID.sol";

/**
 * @title TawfReputation
 * @notice Tawf Reputation System
 * @dev Tracks reputation scores based on community participation
 */
contract TawfReputation is AccessControl, ITawfReputation {
    bytes32 public constant REPUTATION_MANAGER_ROLE = keccak256("REPUTATION_MANAGER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    ITawfDID public immutable didContract;

    // Mapping from address to reputation score
    mapping(address => uint256) private _reputation;
    
    // Mapping to track reputation history
    mapping(address => ReputationChange[]) private _reputationHistory;

    struct ReputationChange {
        uint256 amount;
        bool isIncrease;
        string reason;
        uint256 timestamp;
    }

    // Events for reputation history
    event ReputationHistoryRecorded(
        address indexed user, uint256 amount, bool isIncrease, string reason, uint256 timestamp
    );

    constructor(address _didContract) {
        didContract = ITawfDID(_didContract);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(REPUTATION_MANAGER_ROLE, msg.sender);
    }

    /**
     * @notice Increase reputation for a user
     * @param user Address of the user
     * @param amount Amount to increase
     * @param reason Reason for the increase
     */
    function increaseReputation(address user, uint256 amount, string calldata reason)
        external
        onlyRole(REPUTATION_MANAGER_ROLE)
    {
        if (amount == 0) revert InvalidAmount();
        if (!didContract.hasDID(user)) revert Unauthorized();

        _reputation[user] += amount;
        _recordHistory(user, amount, true, reason);

        emit ReputationIncreased(user, amount, reason);
    }

    /**
     * @notice Decrease reputation for a user
     * @param user Address of the user
     * @param amount Amount to decrease
     * @param reason Reason for the decrease
     */
    function decreaseReputation(address user, uint256 amount, string calldata reason)
        external
        onlyRole(REPUTATION_MANAGER_ROLE)
    {
        if (amount == 0) revert InvalidAmount();
        if (_reputation[user] < amount) revert InsufficientReputation();

        _reputation[user] -= amount;
        _recordHistory(user, amount, false, reason);

        emit ReputationDecreased(user, amount, reason);
    }

    /**
     * @notice Slash reputation (penalty)
     * @param user Address of the user
     * @param amount Amount to slash
     * @param reason Reason for the slash
     */
    function slashReputation(address user, uint256 amount, string calldata reason)
        external
        onlyRole(ADMIN_ROLE)
    {
        if (amount == 0) revert InvalidAmount();

        uint256 currentReputation = _reputation[user];
        uint256 slashAmount = amount > currentReputation ? currentReputation : amount;

        _reputation[user] -= slashAmount;
        _recordHistory(user, slashAmount, false, reason);

        emit ReputationSlashed(user, slashAmount, reason);
    }

    /**
     * @notice Get reputation score for a user
     * @param user Address to check
     */
    function getReputation(address user) external view returns (uint256) {
        return _reputation[user];
    }

    /**
     * @notice Check if user has minimum reputation
     * @param user Address to check
     * @param minReputation Minimum reputation required
     */
    function hasMinimumReputation(address user, uint256 minReputation) external view returns (bool) {
        return _reputation[user] >= minReputation;
    }

    /**
     * @notice Get reputation history for a user
     * @param user Address to check
     */
    function getReputationHistory(address user) external view returns (ReputationChange[] memory) {
        return _reputationHistory[user];
    }

    /**
     * @notice Record reputation change in history
     * @param user Address of the user
     * @param amount Amount changed
     * @param isIncrease Whether it's an increase
     * @param reason Reason for change
     */
    function _recordHistory(address user, uint256 amount, bool isIncrease, string memory reason) private {
        _reputationHistory[user].push(
            ReputationChange({amount: amount, isIncrease: isIncrease, reason: reason, timestamp: block.timestamp})
        );

        emit ReputationHistoryRecorded(user, amount, isIncrease, reason, block.timestamp);
    }
}
