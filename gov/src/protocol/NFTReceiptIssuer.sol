// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/INFTReceiptIssuer.sol";

/**
 * @title NFTReceiptIssuer
 * @notice NFT Receipt Issuer Contract
 * @dev Issues NFT receipts for contributions and transactions
 */
contract NFTReceiptIssuer is ERC721, AccessControl, INFTReceiptIssuer {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 private _tokenIdCounter;

    // Receipt storage
    mapping(uint256 => Receipt) private _receipts;
    
    // Mapping from owner to their receipt token IDs
    mapping(address => uint256[]) private _ownerReceipts;

    constructor() ERC721("Tawf Receipt", "TRCPT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ISSUER_ROLE, msg.sender);
    }

    /**
     * @notice Issue a receipt NFT
     * @param recipient Address to receive the NFT
     * @param campaignId Related campaign ID
     * @param amount Contribution amount
     * @param metadataURI IPFS URI with receipt details
     */
    function issueReceipt(address recipient, uint256 campaignId, uint256 amount, string calldata metadataURI)
        external
        onlyRole(ISSUER_ROLE)
        returns (uint256 tokenId)
    {
        _tokenIdCounter++;
        tokenId = _tokenIdCounter;

        _safeMint(recipient, tokenId);

        _receipts[tokenId] = Receipt({
            tokenId: tokenId,
            recipient: recipient,
            campaignId: campaignId,
            amount: amount,
            timestamp: block.timestamp,
            metadataURI: metadataURI
        });

        _ownerReceipts[recipient].push(tokenId);

        emit ReceiptIssued(tokenId, recipient, campaignId, amount);
    }

    /**
     * @notice Update receipt metadata
     * @param tokenId Token ID of the receipt
     * @param newMetadataURI New IPFS URI
     */
    function updateReceiptMetadata(uint256 tokenId, string calldata newMetadataURI)
        external
        onlyRole(ADMIN_ROLE)
    {
        if (_receipts[tokenId].tokenId == 0) revert ReceiptNotFound();

        _receipts[tokenId].metadataURI = newMetadataURI;
        emit ReceiptMetadataUpdated(tokenId, newMetadataURI);
    }

    /**
     * @notice Get receipt details
     * @param tokenId Token ID of the receipt
     */
    function getReceipt(uint256 tokenId) external view returns (Receipt memory) {
        if (_receipts[tokenId].tokenId == 0) revert ReceiptNotFound();
        return _receipts[tokenId];
    }

    /**
     * @notice Get all receipts for an address
     * @param owner Address to check
     */
    function getReceiptsByOwner(address owner) external view returns (uint256[] memory) {
        return _ownerReceipts[owner];
    }

    /**
     * @notice Get token URI
     * @param tokenId Token ID
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_receipts[tokenId].tokenId == 0) revert ReceiptNotFound();
        return _receipts[tokenId].metadataURI;
    }

    /**
     * @notice Get total receipts issued
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @notice Override transfer to track ownership
     */
    function _update(address to, uint256 tokenId, address auth)
        internal
        override
        returns (address)
    {
        address from = _ownerOf(tokenId);
        
        // Update owner receipts tracking on transfer
        if (from != address(0) && to != address(0)) {
            // Remove from old owner
            uint256[] storage fromReceipts = _ownerReceipts[from];
            for (uint256 i = 0; i < fromReceipts.length; i++) {
                if (fromReceipts[i] == tokenId) {
                    fromReceipts[i] = fromReceipts[fromReceipts.length - 1];
                    fromReceipts.pop();
                    break;
                }
            }

            // Add to new owner
            _ownerReceipts[to].push(tokenId);
        }
        
        return super._update(to, tokenId, auth);
    }

    /**
     * @notice Check interface support
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
