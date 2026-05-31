// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC5192} from "./ERC5192.sol";
import {ITawfPassport, PassportType} from "../interfaces/ITawfPassport.sol";

contract TawfPassport is ERC5192, AccessControl, ITawfPassport {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 private _tokenIdCounter;

    mapping(address => uint256) private _holderToTokenId;
    mapping(uint256 => PassportType) private _passportType;
    mapping(uint256 => string) private _metadataURI;
    mapping(address => bool) private _verified;

    string private _issuerDID;
    mapping(address => bytes32[]) private _credentialHashes;
    mapping(address => mapping(bytes32 => string)) private _vcIPFSUri;
    mapping(address => mapping(bytes32 => bool)) private _credentialValid;

    constructor() ERC5192("Tawf Passport", "TPASS", true) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ISSUER_ROLE, msg.sender);
    }

    function issuePassport(address holder, PassportType passportType, string calldata metadataURI)
        external
        onlyRole(ISSUER_ROLE)
        returns (uint256 tokenId)
    {
        if (hasPassport(holder)) revert PassportAlreadyExists();

        _tokenIdCounter++;
        tokenId = _tokenIdCounter;

        _safeMint(holder, tokenId);
        _holderToTokenId[holder] = tokenId;
        _passportType[tokenId] = passportType;
        _metadataURI[tokenId] = metadataURI;

        emit Locked(tokenId);
        emit PassportIssued(holder, tokenId, passportType, metadataURI);
    }

    function renouncePassport() external {
        uint256 tokenId = _holderToTokenId[msg.sender];
        if (tokenId == 0) revert PassportNotFound();
        _burnPassport(tokenId, msg.sender);
    }

    function revokePassport(uint256 tokenId) external onlyRole(ADMIN_ROLE) {
        address holder = _ownerOf(tokenId);
        if (holder == address(0)) revert PassportNotFound();
        _burnPassport(tokenId, holder);
    }

    function _burnPassport(uint256 tokenId, address holder) internal {
        delete _holderToTokenId[holder];
        delete _passportType[tokenId];
        delete _metadataURI[tokenId];
        delete _verified[holder];
        _invalidateAllCredentials(holder);
        _burn(tokenId);
        emit PassportRevoked(holder, tokenId);
    }

    function _invalidateAllCredentials(address holder) private {
        bytes32[] storage hashes = _credentialHashes[holder];
        for (uint256 i = 0; i < hashes.length; i++) {
            bytes32 h = hashes[i];
            _credentialValid[holder][h] = false;
            emit CredentialRevoked(holder, _holderToTokenId[holder], h);
        }
        delete _credentialHashes[holder];
    }

    function updateMetadata(uint256 tokenId, string calldata newMetadataURI) external {
        address holder = _ownerOf(tokenId);
        if (holder == address(0)) revert PassportNotFound();
        if (msg.sender != holder && !hasRole(ADMIN_ROLE, msg.sender)) revert Unauthorized();

        _metadataURI[tokenId] = newMetadataURI;
        emit PassportMetadataUpdated(holder, tokenId, newMetadataURI);
    }

    function setVerified(address holder, bool verified) external onlyRole(ADMIN_ROLE) {
        if (!hasPassport(holder)) revert PassportNotFound();
        _verified[holder] = verified;
        emit PassportVerified(holder, verified);
    }

    function setIssuerDID(string calldata did) external onlyRole(ADMIN_ROLE) {
        _issuerDID = did;
        emit IssuerDIDSet(did);
    }

    function issueCredential(address holder, bytes32 credentialHash, string calldata vcIPFSUri)
        external
        onlyRole(ISSUER_ROLE)
    {
        uint256 tokenId = _holderToTokenId[holder];
        if (tokenId == 0) revert PassportNotFound();

        _credentialHashes[holder].push(credentialHash);
        _vcIPFSUri[holder][credentialHash] = vcIPFSUri;
        _credentialValid[holder][credentialHash] = true;

        emit CredentialIssued(holder, tokenId, credentialHash, vcIPFSUri);
    }

    function revokeCredential(address holder, bytes32 credentialHash) external onlyRole(ADMIN_ROLE) {
        if (!hasPassport(holder)) revert PassportNotFound();
        if (!_credentialValid[holder][credentialHash]) revert CredentialNotFound();

        _credentialValid[holder][credentialHash] = false;

        uint256 tokenId = _holderToTokenId[holder];
        emit CredentialRevoked(holder, tokenId, credentialHash);
    }

    function hasPassport(address holder) public view returns (bool) {
        return _holderToTokenId[holder] != 0;
    }

    function isVerified(address holder) external view returns (bool) {
        return _verified[holder];
    }

    function getPassportTokenId(address holder) external view returns (uint256) {
        if (!hasPassport(holder)) revert PassportNotFound();
        return _holderToTokenId[holder];
    }

    function getPassportType(address holder) external view returns (PassportType) {
        if (!hasPassport(holder)) revert PassportNotFound();
        return _passportType[_holderToTokenId[holder]];
    }

    function getIssuerDID() external view returns (string memory) {
        return _issuerDID;
    }

    function getCredentialHash(address holder, uint256 index) external view returns (bytes32) {
        return _credentialHashes[holder][index];
    }

    function getCredentialCount(address holder) external view returns (uint256) {
        return _credentialHashes[holder].length;
    }

    function getVcIPFSUri(address holder, bytes32 credentialHash) external view returns (string memory) {
        return _vcIPFSUri[holder][credentialHash];
    }

    function isCredentialValid(address holder, bytes32 credentialHash) external view returns (bool) {
        return _credentialValid[holder][credentialHash];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) revert PassportNotFound();
        return _metadataURI[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC5192, AccessControl)
        returns (bool)
    {
        return interfaceId == type(ITawfPassport).interfaceId
            || ERC5192.supportsInterface(interfaceId)
            || AccessControl.supportsInterface(interfaceId);
    }
}
