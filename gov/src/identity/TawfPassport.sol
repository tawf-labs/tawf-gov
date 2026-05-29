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
        _burn(tokenId);
        emit PassportRevoked(holder, tokenId);
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
