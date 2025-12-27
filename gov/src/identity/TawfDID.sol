// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/ITawfDID.sol";

/**
 * @title TawfDID
 * @notice Tawf Decentralized Identity - Soulbound NFT
 * @dev Non-transferable identity tokens with IPFS metadata
 */
contract TawfDID is ERC721, AccessControl, ITawfDID {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 private _tokenIdCounter;

    // Mapping from address to token ID
    mapping(address => uint256) private _holderToTokenId;
    
    // Mapping from token ID to holder
    mapping(uint256 => address) private _tokenIdToHolder;
    
    // Mapping from token ID to metadata URI
    mapping(uint256 => string) private _tokenMetadata;
    
    // Mapping from address to verification status
    mapping(address => bool) private _verified;
    
    // Mapping to track if token exists
    mapping(uint256 => bool) private _exists;

    constructor() ERC721("Tawf DID", "TDID") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ISSUER_ROLE, msg.sender);
    }

    /**
     * @notice Issue a new DID to an address
     * @param holder Address receiving the DID
     * @param metadataURI IPFS URI containing identity metadata
     */
    function issueDID(address holder, string calldata metadataURI)
        external
        onlyRole(ISSUER_ROLE)
        returns (uint256 tokenId)
    {
        if (hasDID(holder)) revert DIDAlreadyExists();

        _tokenIdCounter++;
        tokenId = _tokenIdCounter;

        _safeMint(holder, tokenId);
        _holderToTokenId[holder] = tokenId;
        _tokenIdToHolder[tokenId] = holder;
        _tokenMetadata[tokenId] = metadataURI;
        _exists[tokenId] = true;

        emit DIDIssued(holder, tokenId, metadataURI);
    }

    /**
     * @notice Revoke a DID
     * @param tokenId The token ID to revoke
     */
    function revokeDID(uint256 tokenId) external onlyRole(ADMIN_ROLE) {
        if (!_exists[tokenId]) revert DIDNotFound();

        address holder = _tokenIdToHolder[tokenId];
        
        _burn(tokenId);
        delete _holderToTokenId[holder];
        delete _tokenIdToHolder[tokenId];
        delete _tokenMetadata[tokenId];
        delete _verified[holder];
        _exists[tokenId] = false;

        emit DIDRevoked(holder, tokenId);
    }

    /**
     * @notice Update DID metadata
     * @param tokenId The token ID to update
     * @param newMetadataURI New IPFS URI
     */
    function updateMetadata(uint256 tokenId, string calldata newMetadataURI) external {
        if (!_exists[tokenId]) revert DIDNotFound();
        
        address holder = _tokenIdToHolder[tokenId];
        if (msg.sender != holder && !hasRole(ADMIN_ROLE, msg.sender)) {
            revert Unauthorized();
        }

        _tokenMetadata[tokenId] = newMetadataURI;
        emit DIDUpdated(holder, tokenId, newMetadataURI);
    }

    /**
     * @notice Mark a DID as verified
     * @param holder Address of the DID holder
     */
    function setVerified(address holder, bool verified) external onlyRole(ADMIN_ROLE) {
        if (!hasDID(holder)) revert DIDNotFound();
        
        _verified[holder] = verified;
        emit VerificationStatusChanged(holder, verified);
    }

    /**
     * @notice Check if an address has a DID
     * @param holder Address to check
     */
    function hasDID(address holder) public view returns (bool) {
        return _holderToTokenId[holder] != 0;
    }

    /**
     * @notice Check if a DID is verified
     * @param holder Address to check
     */
    function isVerified(address holder) external view returns (bool) {
        return _verified[holder];
    }

    /**
     * @notice Get DID token ID for an address
     * @param holder Address to check
     */
    function getDIDTokenId(address holder) external view returns (uint256) {
        if (!hasDID(holder)) revert DIDNotFound();
        return _holderToTokenId[holder];
    }

    /**
     * @notice Get token URI
     * @param tokenId Token ID
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists[tokenId]) revert DIDNotFound();
        return _tokenMetadata[tokenId];
    }

    /**
     * @notice Override transfer to make soulbound
     * @dev Prevents all transfers except minting
     */
    function _update(address to, uint256 tokenId, address auth)
        internal
        override
        returns (address)
    {
        address from = _ownerOf(tokenId);
        // Only allow minting (from == address(0)) and burning (to == address(0))
        if (from != address(0) && to != address(0)) {
            revert Soulbound();
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
