// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/**
 * @title IWakafTreasury
 * @notice Interface for Wakaf (Endowment) Treasury
 * @dev Manages community funds and allocations
 */
interface IWakafTreasury {
    struct Allocation {
        uint256 id;
        address recipient;
        uint256 amount;
        string purpose;
        bool executed;
        uint256 timestamp;
    }

    // Events
    event Deposited(address indexed from, uint256 amount);
    event AllocationCreated(uint256 indexed id, address indexed recipient, uint256 amount, string purpose);
    event AllocationExecuted(uint256 indexed id);
    event EmergencyWithdrawal(address indexed to, uint256 amount);

    // Errors
    error InsufficientBalance();
    error AllocationNotFound();
    error AlreadyExecuted();
    error Unauthorized();
    error ContractPaused();

    /**
     * @notice Deposit funds to treasury
     */
    function deposit() external payable;

    /**
     * @notice Create an allocation
     * @param recipient Address to receive funds
     * @param amount Amount to allocate
     * @param purpose Purpose of allocation
     */
    function createAllocation(address recipient, uint256 amount, string calldata purpose)
        external
        returns (uint256 id);

    /**
     * @notice Execute an allocation
     * @param allocationId ID of the allocation
     */
    function executeAllocation(uint256 allocationId) external;

    /**
     * @notice Emergency withdrawal by admin
     * @param to Address to send funds
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address to, uint256 amount) external;

    /**
     * @notice Get treasury balance
     */
    function getBalance() external view returns (uint256);

    /**
     * @notice Get allocation details
     * @param allocationId ID of the allocation
     */
    function getAllocation(uint256 allocationId) external view returns (Allocation memory);
}
