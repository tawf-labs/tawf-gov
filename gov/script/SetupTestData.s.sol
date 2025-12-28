// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Script.sol";
import "../src/identity/TawfDID.sol";
import "../src/identity/TawfReputation.sol";
import "../src/protocol/VendorRegistry.sol";

/**
 * @title SetupTestData
 * @notice Script to setup test data for the Tawf system
 */
contract SetupTestData is Script {
    // Contract addresses (should match deployment)
    TawfDID public didContract;
    TawfReputation public reputationContract;
    VendorRegistry public vendorRegistry;

    // User lists
    address[] public users;
    address[] public vendors;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Load deployed contract addresses
        address didAddress = vm.envAddress("DID_CONTRACT");
        address reputationAddress = vm.envAddress("REPUTATION_CONTRACT");
        address vendorRegistryAddress = vm.envAddress("VENDOR_REGISTRY");

        didContract = TawfDID(didAddress);
        reputationContract = TawfReputation(reputationAddress);
        vendorRegistry = VendorRegistry(vendorRegistryAddress);

        console.log("Setting up test data...");

        vm.startBroadcast(deployerPrivateKey);

        // Create test users
        for (uint256 i = 0; i < 5; i++) {
            address user = address(uint160(uint256(keccak256(abi.encodePacked("user", i)))));
            users.push(user);

            // Issue DID
            string memory metadataURI = string(abi.encodePacked("ipfs://did/user", vm.toString(i)));
            didContract.issueDID(user, metadataURI);
            
            // Set verified
            didContract.setVerified(user, true);

            // Give reputation
            reputationContract.increaseReputation(user, 500 + (i * 100), "Initial reputation");

            console.log("Created test user:", user);
        }

        // Create test vendors
        for (uint256 i = 0; i < 3; i++) {
            address vendor = address(uint160(uint256(keccak256(abi.encodePacked("vendor", i)))));
            vendors.push(vendor);

            // Issue DID
            string memory metadataURI = string(abi.encodePacked("ipfs://did/vendor", vm.toString(i)));
            didContract.issueDID(vendor, metadataURI);
            
            // Set verified
            didContract.setVerified(vendor, true);

            console.log("Created test vendor:", vendor);
        }

        vm.stopBroadcast();

        console.log("\n=== Test Data Setup Complete ===");
        console.log("Test Users:", users.length);
        console.log("Test Vendors:", vendors.length);
    }
}
