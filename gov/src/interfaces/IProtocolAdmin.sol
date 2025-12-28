// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/**
 * @title IProtocolAdmin
 * @notice Interface for Protocol Admin and Emergency Controls
 * @dev Provides pause/unpause functionality and emergency controls
 */
interface IProtocolAdmin {
    // Events
    event Paused(address indexed admin, address indexed target);
    event Unpaused(address indexed admin, address indexed target);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event EmergencyAction(address indexed admin, address indexed target, bytes data);

    // Errors
    error NotAdmin();
    error AlreadyPaused();
    error NotPaused();
    error InvalidTarget();

    /**
     * @notice Pause a contract
     * @param target Address of contract to pause
     */
    function pause(address target) external;

    /**
     * @notice Unpause a contract
     * @param target Address of contract to unpause
     */
    function unpause(address target) external;

    /**
     * @notice Execute emergency action
     * @param target Target contract
     * @param data Call data
     */
    function executeEmergencyAction(address target, bytes calldata data) external;

    /**
     * @notice Add an admin
     * @param admin Address to add
     */
    function addAdmin(address admin) external;

    /**
     * @notice Remove an admin
     * @param admin Address to remove
     */
    function removeAdmin(address admin) external;

    /**
     * @notice Check if address is admin
     * @param admin Address to check
     */
    function isAdmin(address admin) external view returns (bool);

    /**
     * @notice Check if contract is paused
     * @param target Contract to check
     */
    function isPaused(address target) external view returns (bool);
}
