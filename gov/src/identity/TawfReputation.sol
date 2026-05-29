// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/ITawfReputation.sol";
import "../interfaces/ITawfPassport.sol";

contract TawfReputation is AccessControl, ITawfReputation {
    bytes32 public constant REPUTATION_MANAGER_ROLE = keccak256("REPUTATION_MANAGER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    ITawfPassport public immutable passportContract;

    mapping(address => uint256) private _reputation;
    mapping(address => ReputationChange[]) private _reputationHistory;

    struct ReputationChange {
        uint256 amount;
        bool isIncrease;
        string reason;
        uint256 timestamp;
    }

    event ReputationHistoryRecorded(
        address indexed user, uint256 amount, bool isIncrease, string reason, uint256 timestamp
    );

    constructor(address _passportContract) {
        passportContract = ITawfPassport(_passportContract);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(REPUTATION_MANAGER_ROLE, msg.sender);
    }

    function increaseReputation(address user, uint256 amount, string calldata reason)
        external
        onlyRole(REPUTATION_MANAGER_ROLE)
    {
        if (amount == 0) revert InvalidAmount();
        if (!passportContract.hasPassport(user)) revert Unauthorized();

        _reputation[user] += amount;
        _recordHistory(user, amount, true, reason);

        emit ReputationIncreased(user, amount, reason);
    }

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

    function getReputation(address user) external view returns (uint256) {
        return _reputation[user];
    }

    function hasMinimumReputation(address user, uint256 minReputation) external view returns (bool) {
        return _reputation[user] >= minReputation;
    }

    function getReputationHistory(address user) external view returns (ReputationChange[] memory) {
        return _reputationHistory[user];
    }

    function _recordHistory(address user, uint256 amount, bool isIncrease, string memory reason) private {
        _reputationHistory[user].push(
            ReputationChange({amount: amount, isIncrease: isIncrease, reason: reason, timestamp: block.timestamp})
        );

        emit ReputationHistoryRecorded(user, amount, isIncrease, reason, block.timestamp);
    }
}
