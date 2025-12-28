// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IProtocolAdmin.sol";

/**
 * @title ProtocolAdmin
 * @notice Protocol Admin and Emergency Controls Contract
 * @dev Provides pause/unpause functionality and emergency controls
 */
contract ProtocolAdmin is AccessControl, ReentrancyGuard, IProtocolAdmin {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    // Pause status for each contract
    mapping(address => bool) private _pausedContracts;
    
    // Admin list
    address[] private _adminList;
    mapping(address => bool) private _isAdmin;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(EMERGENCY_ROLE, msg.sender);
        
        _adminList.push(msg.sender);
        _isAdmin[msg.sender] = true;
    }

    /**
     * @notice Pause a contract
     * @param target Address of contract to pause
     */
    function pause(address target) external onlyRole(ADMIN_ROLE) {
        if (target == address(0)) revert InvalidTarget();
        if (_pausedContracts[target]) revert AlreadyPaused();

        _pausedContracts[target] = true;

        // Call pause function on target if it has one
        (bool success,) = target.call(abi.encodeWithSignature("pause()"));
        if (!success) revert InvalidTarget();

        emit Paused(msg.sender, target);
    }

    /**
     * @notice Unpause a contract
     * @param target Address of contract to unpause
     */
    function unpause(address target) external onlyRole(ADMIN_ROLE) {
        if (target == address(0)) revert InvalidTarget();
        if (!_pausedContracts[target]) revert NotPaused();

        _pausedContracts[target] = false;

        // Call unpause function on target if it has one
        (bool success,) = target.call(abi.encodeWithSignature("unpause()"));
        if (!success) revert InvalidTarget();

        emit Unpaused(msg.sender, target);
    }

    /**
     * @notice Execute emergency action
     * @param target Target contract
     * @param data Call data
     */
    function executeEmergencyAction(address target, bytes calldata data)
        external
        onlyRole(EMERGENCY_ROLE)
        nonReentrant
    {
        if (target == address(0)) revert InvalidTarget();

        (bool success,) = target.call(data);
        if (!success) revert InvalidTarget();

        emit EmergencyAction(msg.sender, target, data);
    }

    /**
     * @notice Add an admin
     * @param admin Address to add
     */
    function addAdmin(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_isAdmin[admin]) revert AlreadyPaused(); // Reusing error for "already admin"

        _grantRole(ADMIN_ROLE, admin);
        _adminList.push(admin);
        _isAdmin[admin] = true;

        emit AdminAdded(admin);
    }

    /**
     * @notice Remove an admin
     * @param admin Address to remove
     */
    function removeAdmin(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!_isAdmin[admin]) revert NotAdmin();

        _revokeRole(ADMIN_ROLE, admin);
        _isAdmin[admin] = false;

        // Remove from list
        for (uint256 i = 0; i < _adminList.length; i++) {
            if (_adminList[i] == admin) {
                _adminList[i] = _adminList[_adminList.length - 1];
                _adminList.pop();
                break;
            }
        }

        emit AdminRemoved(admin);
    }

    /**
     * @notice Check if address is admin
     * @param admin Address to check
     */
    function isAdmin(address admin) external view returns (bool) {
        return _isAdmin[admin];
    }

    /**
     * @notice Check if contract is paused
     * @param target Contract to check
     */
    function isPaused(address target) external view returns (bool) {
        return _pausedContracts[target];
    }

    /**
     * @notice Get all admins
     */
    function getAdmins() external view returns (address[] memory) {
        return _adminList;
    }

    /**
     * @notice Grant emergency role
     * @param account Address to grant emergency role
     */
    function grantEmergencyRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(EMERGENCY_ROLE, account);
    }

    /**
     * @notice Revoke emergency role
     * @param account Address to revoke emergency role from
     */
    function revokeEmergencyRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(EMERGENCY_ROLE, account);
    }
}
