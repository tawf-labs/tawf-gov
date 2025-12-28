// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/**
 * @title ITawfDID
 * @notice Interface for Tawf Decentralized Identity (Soulbound NFT)
 * @dev Non-transferable identity tokens with IPFS metadata
 */
interface ITawfDID {
    // Events
    event DIDIssued(address indexed holder, uint256 indexed tokenId, string metadataURI);
    event DIDRevoked(address indexed holder, uint256 indexed tokenId);
    event DIDUpdated(address indexed holder, uint256 indexed tokenId, string newMetadataURI);
    event VerificationStatusChanged(address indexed holder, bool verified);

    // Errors
    error DIDAlreadyExists();
    error DIDNotFound();
    error Soulbound();
    error Unauthorized();
    error AlreadyVerified();
    error NotVerified();

    /**
     * @notice Issue a new DID to an address
     * @param holder Address receiving the DID
     * @param metadataURI IPFS URI containing identity metadata
     */
    function issueDID(address holder, string calldata metadataURI) external returns (uint256 tokenId);

    /**
     * @notice Revoke a DID
     * @param tokenId The token ID to revoke
     */
    function revokeDID(uint256 tokenId) external;

    /**
     * @notice Update DID metadata
     * @param tokenId The token ID to update
     * @param newMetadataURI New IPFS URI
     */
    function updateMetadata(uint256 tokenId, string calldata newMetadataURI) external;

    /**
     * @notice Mark a DID as verified
     * @param holder Address of the DID holder
     */
    function setVerified(address holder, bool verified) external;

    /**
     * @notice Check if an address has a DID
     * @param holder Address to check
     */
    function hasDID(address holder) external view returns (bool);

    /**
     * @notice Check if a DID is verified
     * @param holder Address to check
     */
    function isVerified(address holder) external view returns (bool);

    /**
     * @notice Get DID token ID for an address
     * @param holder Address to check
     */
    function getDIDTokenId(address holder) external view returns (uint256);
}
