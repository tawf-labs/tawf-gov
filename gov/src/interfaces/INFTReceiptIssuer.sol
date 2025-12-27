// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title INFTReceiptIssuer
 * @notice Interface for NFT Receipt Issuer
 * @dev Issues NFT receipts for contributions and transactions
 */
interface INFTReceiptIssuer {
    struct Receipt {
        uint256 tokenId;
        address recipient;
        uint256 campaignId;
        uint256 amount;
        uint256 timestamp;
        string metadataURI;
    }

    // Events
    event ReceiptIssued(
        uint256 indexed tokenId, address indexed recipient, uint256 indexed campaignId, uint256 amount
    );
    event ReceiptMetadataUpdated(uint256 indexed tokenId, string newMetadataURI);

    // Errors
    error Unauthorized();
    error InvalidReceipt();
    error ReceiptNotFound();

    /**
     * @notice Issue a receipt NFT
     * @param recipient Address to receive the NFT
     * @param campaignId Related campaign ID
     * @param amount Contribution amount
     * @param metadataURI IPFS URI with receipt details
     */
    function issueReceipt(address recipient, uint256 campaignId, uint256 amount, string calldata metadataURI)
        external
        returns (uint256 tokenId);

    /**
     * @notice Update receipt metadata
     * @param tokenId Token ID of the receipt
     * @param newMetadataURI New IPFS URI
     */
    function updateReceiptMetadata(uint256 tokenId, string calldata newMetadataURI) external;

    /**
     * @notice Get receipt details
     * @param tokenId Token ID of the receipt
     */
    function getReceipt(uint256 tokenId) external view returns (Receipt memory);

    /**
     * @notice Get all receipts for an address
     * @param owner Address to check
     */
    function getReceiptsByOwner(address owner) external view returns (uint256[] memory);
}
