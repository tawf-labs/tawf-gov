// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {IERC5192} from "../identity/IERC5192.sol";

enum PassportType { Muzakki, Mustahik, Organization, ShariaCouncil }

interface ITawfPassport is IERC5192 {
    event PassportIssued(address indexed holder, uint256 indexed tokenId, PassportType passportType, string metadataURI);
    event PassportRevoked(address indexed holder, uint256 indexed tokenId);
    event PassportMetadataUpdated(address indexed holder, uint256 indexed tokenId, string newMetadataURI);
    event PassportVerified(address indexed holder, bool verified);
    event IssuerDIDSet(string issuerDID);
    event CredentialIssued(address indexed holder, uint256 indexed tokenId, bytes32 credentialHash, string vcIPFSUri);
    event CredentialRevoked(address indexed holder, uint256 indexed tokenId, bytes32 credentialHash);

    error PassportAlreadyExists();
    error PassportNotFound();
    error Unauthorized();
    error CredentialNotFound();

    function issuePassport(address holder, PassportType passportType, string calldata metadataURI) external returns (uint256 tokenId);
    function revokePassport(uint256 tokenId) external;
    function renouncePassport() external;
    function updateMetadata(uint256 tokenId, string calldata newMetadataURI) external;
    function setVerified(address holder, bool verified) external;

    function setIssuerDID(string calldata did) external;
    function issueCredential(address holder, bytes32 credentialHash, string calldata vcIPFSUri) external;
    function revokeCredential(address holder, bytes32 credentialHash) external;

    function hasPassport(address holder) external view returns (bool);
    function isVerified(address holder) external view returns (bool);
    function getPassportTokenId(address holder) external view returns (uint256);
    function getPassportType(address holder) external view returns (PassportType);
    function getIssuerDID() external view returns (string memory);
    function getCredentialHash(address holder, uint256 index) external view returns (bytes32);
    function getCredentialCount(address holder) external view returns (uint256);
    function getVcIPFSUri(address holder, bytes32 credentialHash) external view returns (string memory);
    function isCredentialValid(address holder, bytes32 credentialHash) external view returns (bool);
}
