// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IVendorRegistry.sol";
import "../interfaces/ITawfDID.sol";

/**
 * @title VendorRegistry
 * @notice Vendor Registry Contract
 * @dev Manages verified vendors and organizers
 */
contract VendorRegistry is AccessControl, ReentrancyGuard, IVendorRegistry {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    ITawfDID public immutable didContract;

    // Vendor storage
    mapping(address => Vendor) private _vendors;
    address[] private _vendorList;

    constructor(address _didContract) {
        didContract = ITawfDID(_didContract);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(VERIFIER_ROLE, msg.sender);
    }

    /**
     * @notice Register as a vendor
     * @param name Vendor name
     * @param metadataURI IPFS URI with vendor details
     */
    function registerVendor(string calldata name, string calldata metadataURI) external nonReentrant {
        // Must have DID to register
        if (!didContract.hasDID(msg.sender)) revert Unauthorized();
        if (_vendors[msg.sender].registrationTime != 0) revert VendorAlreadyRegistered();

        _vendors[msg.sender] = Vendor({
            vendorAddress: msg.sender,
            name: name,
            metadataURI: metadataURI,
            status: VendorStatus.Pending,
            registrationTime: block.timestamp,
            reputationScore: 0,
            campaignIds: new uint256[](0)
        });

        _vendorList.push(msg.sender);

        emit VendorRegistered(msg.sender, name);
    }

    /**
     * @notice Verify a vendor (by admin)
     * @param vendor Address of the vendor
     */
    function verifyVendor(address vendor) external onlyRole(VERIFIER_ROLE) {
        if (_vendors[vendor].registrationTime == 0) revert VendorNotFound();

        _vendors[vendor].status = VendorStatus.Verified;
        _vendors[vendor].reputationScore = 100; // Initial reputation

        emit VendorVerified(vendor);
    }

    /**
     * @notice Update vendor status
     * @param vendor Address of the vendor
     * @param status New status
     */
    function updateVendorStatus(address vendor, VendorStatus status) external onlyRole(ADMIN_ROLE) {
        if (_vendors[vendor].registrationTime == 0) revert VendorNotFound();

        _vendors[vendor].status = status;
        emit VendorStatusChanged(vendor, status);
    }

    /**
     * @notice Update vendor reputation
     * @param vendor Address of the vendor
     * @param newScore New reputation score
     */
    function updateReputation(address vendor, uint256 newScore) external onlyRole(ADMIN_ROLE) {
        if (_vendors[vendor].registrationTime == 0) revert VendorNotFound();

        _vendors[vendor].reputationScore = newScore;
        emit VendorReputationUpdated(vendor, newScore);
    }

    /**
     * @notice Add campaign to vendor's record
     * @param vendor Address of the vendor
     * @param campaignId Campaign ID
     */
    function addCampaign(address vendor, uint256 campaignId) external {
        if (_vendors[vendor].registrationTime == 0) revert VendorNotFound();
        if (msg.sender != vendor && !hasRole(ADMIN_ROLE, msg.sender)) revert Unauthorized();

        _vendors[vendor].campaignIds.push(campaignId);
    }

    /**
     * @notice Check if vendor is verified
     * @param vendor Address to check
     */
    function isVerified(address vendor) external view returns (bool) {
        return _vendors[vendor].status == VendorStatus.Verified;
    }

    /**
     * @notice Get vendor details
     * @param vendor Address of the vendor
     */
    function getVendor(address vendor) external view returns (Vendor memory) {
        if (_vendors[vendor].registrationTime == 0) revert VendorNotFound();
        return _vendors[vendor];
    }

    /**
     * @notice Get all vendors
     */
    function getAllVendors() external view returns (address[] memory) {
        return _vendorList;
    }

    /**
     * @notice Get verified vendors
     */
    function getVerifiedVendors() external view returns (address[] memory) {
        uint256 count = 0;
        
        // Count verified vendors
        for (uint256 i = 0; i < _vendorList.length; i++) {
            if (_vendors[_vendorList[i]].status == VendorStatus.Verified) {
                count++;
            }
        }

        // Create array of verified vendors
        address[] memory verified = new address[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < _vendorList.length; i++) {
            if (_vendors[_vendorList[i]].status == VendorStatus.Verified) {
                verified[index] = _vendorList[i];
                index++;
            }
        }

        return verified;
    }

    /**
     * @notice Get vendor campaign count
     * @param vendor Address of the vendor
     */
    function getVendorCampaignCount(address vendor) external view returns (uint256) {
        if (_vendors[vendor].registrationTime == 0) return 0;
        return _vendors[vendor].campaignIds.length;
    }
}
