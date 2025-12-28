// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/**
 * @title IVendorRegistry
 * @notice Interface for Vendor Registry
 * @dev Manages verified vendors and organizers
 */
interface IVendorRegistry {
    enum VendorStatus {
        Pending,
        Verified,
        Suspended,
        Revoked
    }

    struct Vendor {
        address vendorAddress;
        string name;
        string metadataURI;
        VendorStatus status;
        uint256 registrationTime;
        uint256 reputationScore;
        uint256[] campaignIds;
    }

    // Events
    event VendorRegistered(address indexed vendor, string name);
    event VendorVerified(address indexed vendor);
    event VendorStatusChanged(address indexed vendor, VendorStatus status);
    event VendorReputationUpdated(address indexed vendor, uint256 newScore);

    // Errors
    error VendorAlreadyRegistered();
    error VendorNotFound();
    error NotVerified();
    error Unauthorized();

    /**
     * @notice Register as a vendor
     * @param name Vendor name
     * @param metadataURI IPFS URI with vendor details
     */
    function registerVendor(string calldata name, string calldata metadataURI) external;

    /**
     * @notice Verify a vendor (by admin)
     * @param vendor Address of the vendor
     */
    function verifyVendor(address vendor) external;

    /**
     * @notice Update vendor status
     * @param vendor Address of the vendor
     * @param status New status
     */
    function updateVendorStatus(address vendor, VendorStatus status) external;

    /**
     * @notice Update vendor reputation
     * @param vendor Address of the vendor
     * @param newScore New reputation score
     */
    function updateReputation(address vendor, uint256 newScore) external;

    /**
     * @notice Add campaign to vendor's record
     * @param vendor Address of the vendor
     * @param campaignId Campaign ID
     */
    function addCampaign(address vendor, uint256 campaignId) external;

    /**
     * @notice Check if vendor is verified
     * @param vendor Address to check
     */
    function isVerified(address vendor) external view returns (bool);

    /**
     * @notice Get vendor details
     * @param vendor Address of the vendor
     */
    function getVendor(address vendor) external view returns (Vendor memory);
}
