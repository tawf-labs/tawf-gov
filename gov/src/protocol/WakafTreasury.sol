// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../interfaces/IWakafTreasury.sol";

/**
 * @title WakafTreasury
 * @notice Wakaf (Endowment) Treasury Contract
 * @dev Manages community funds and allocations
 */
contract WakafTreasury is AccessControl, ReentrancyGuard, Pausable, IWakafTreasury {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ALLOCATOR_ROLE = keccak256("ALLOCATOR_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    // Allocation storage
    mapping(uint256 => Allocation) private _allocations;
    uint256 private _allocationCount;

    // Total allocated but not executed
    uint256 public totalPendingAllocations;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ALLOCATOR_ROLE, msg.sender);
        _grantRole(EXECUTOR_ROLE, msg.sender);
    }

    /**
     * @notice Deposit funds to treasury
     */
    function deposit() external payable {
        if (msg.value == 0) revert InsufficientBalance();
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Create an allocation
     * @param recipient Address to receive funds
     * @param amount Amount to allocate
     * @param purpose Purpose of allocation
     */
    function createAllocation(address recipient, uint256 amount, string calldata purpose)
        external
        onlyRole(ALLOCATOR_ROLE)
        whenNotPaused
        nonReentrant
        returns (uint256 id)
    {
        if (amount == 0) revert InsufficientBalance();
        if (getBalance() < totalPendingAllocations + amount) revert InsufficientBalance();

        _allocationCount++;
        id = _allocationCount;

        _allocations[id] = Allocation({
            id: id,
            recipient: recipient,
            amount: amount,
            purpose: purpose,
            executed: false,
            timestamp: block.timestamp
        });

        totalPendingAllocations += amount;

        emit AllocationCreated(id, recipient, amount, purpose);
    }

    /**
     * @notice Execute an allocation
     * @param allocationId ID of the allocation
     */
    function executeAllocation(uint256 allocationId)
        external
        onlyRole(EXECUTOR_ROLE)
        whenNotPaused
        nonReentrant
    {
        if (allocationId == 0 || allocationId > _allocationCount) revert AllocationNotFound();

        Allocation storage allocation = _allocations[allocationId];
        
        if (allocation.executed) revert AlreadyExecuted();
        if (address(this).balance < allocation.amount) revert InsufficientBalance();

        allocation.executed = true;
        totalPendingAllocations -= allocation.amount;

        (bool success,) = allocation.recipient.call{value: allocation.amount}("");
        if (!success) revert InsufficientBalance();

        emit AllocationExecuted(allocationId);
    }

    /**
     * @notice Emergency withdrawal by admin
     * @param to Address to send funds
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address to, uint256 amount)
        external
        onlyRole(ADMIN_ROLE)
        nonReentrant
    {
        if (amount == 0) revert InsufficientBalance();
        if (address(this).balance < amount) revert InsufficientBalance();

        (bool success,) = to.call{value: amount}("");
        if (!success) revert InsufficientBalance();

        emit EmergencyWithdrawal(to, amount);
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Get treasury balance
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Get available balance (total - pending)
     */
    function getAvailableBalance() external view returns (uint256) {
        uint256 balance = getBalance();
        return balance > totalPendingAllocations ? balance - totalPendingAllocations : 0;
    }

    /**
     * @notice Get allocation details
     * @param allocationId ID of the allocation
     */
    function getAllocation(uint256 allocationId) external view returns (Allocation memory) {
        if (allocationId == 0 || allocationId > _allocationCount) revert AllocationNotFound();
        return _allocations[allocationId];
    }

    /**
     * @notice Get total allocation count
     */
    function getAllocationCount() external view returns (uint256) {
        return _allocationCount;
    }

    /**
     * @notice Receive ETH
     */
    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }
}
