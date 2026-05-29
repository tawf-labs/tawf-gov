// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {IERC5192} from "../identity/IERC5192.sol";

enum PassportType { Muzakki, Mustahik, Organization, ShariaCouncil }

interface ITawfPassport is IERC5192 {
    event PassportIssued(address indexed holder, uint256 indexed tokenId, PassportType passportType, string metadataURI);
    event PassportRevoked(address indexed holder, uint256 indexed tokenId);
    event PassportMetadataUpdated(address indexed holder, uint256 indexed tokenId, string newMetadataURI);
    event PassportVerified(address indexed holder, bool verified);

    error PassportAlreadyExists();
    error PassportNotFound();
    error Unauthorized();

    function issuePassport(address holder, PassportType passportType, string calldata metadataURI) external returns (uint256 tokenId);
    function revokePassport(uint256 tokenId) external;
    function renouncePassport() external;
    function updateMetadata(uint256 tokenId, string calldata newMetadataURI) external;
    function setVerified(address holder, bool verified) external;

    function hasPassport(address holder) external view returns (bool);
    function isVerified(address holder) external view returns (bool);
    function getPassportTokenId(address holder) external view returns (uint256);
    function getPassportType(address holder) external view returns (PassportType);
}
