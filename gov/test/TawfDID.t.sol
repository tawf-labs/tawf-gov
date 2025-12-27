// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/identity/TawfDID.sol";

contract TawfDIDTest is Test {
    TawfDID public didContract;
    
    address public admin = address(0x1);
    address public issuer = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);

    event DIDIssued(address indexed holder, uint256 indexed tokenId, string metadataURI);
    event DIDRevoked(address indexed holder, uint256 indexed tokenId);
    event DIDUpdated(address indexed holder, uint256 indexed tokenId, string newMetadataURI);
    event VerificationStatusChanged(address indexed holder, bool verified);

    function setUp() public {
        vm.startPrank(admin);
        didContract = new TawfDID();
        didContract.grantRole(didContract.ISSUER_ROLE(), issuer);
        vm.stopPrank();
    }

    function test_IssueDID() public {
        vm.startPrank(issuer);
        
        string memory metadataURI = "ipfs://QmTest123";
        
        vm.expectEmit(true, true, false, true);
        emit DIDIssued(user1, 1, metadataURI);
        
        uint256 tokenId = didContract.issueDID(user1, metadataURI);
        
        assertEq(tokenId, 1);
        assertTrue(didContract.hasDID(user1));
        assertEq(didContract.getDIDTokenId(user1), tokenId);
        assertEq(didContract.tokenURI(tokenId), metadataURI);
        assertEq(didContract.ownerOf(tokenId), user1);
        
        vm.stopPrank();
    }

    function test_RevertWhen_DIDAlreadyExists() public {
        vm.startPrank(issuer);
        
        didContract.issueDID(user1, "ipfs://QmTest1");
        
        vm.expectRevert(ITawfDID.DIDAlreadyExists.selector);
        didContract.issueDID(user1, "ipfs://QmTest2");
        
        vm.stopPrank();
    }

    function test_RevokeDID() public {
        vm.prank(issuer);
        uint256 tokenId = didContract.issueDID(user1, "ipfs://QmTest");
        
        vm.startPrank(admin);
        
        vm.expectEmit(true, true, false, false);
        emit DIDRevoked(user1, tokenId);
        
        didContract.revokeDID(tokenId);
        
        assertFalse(didContract.hasDID(user1));
        assertFalse(didContract.isVerified(user1));
        
        vm.stopPrank();
    }

    function test_UpdateMetadata() public {
        vm.prank(issuer);
        uint256 tokenId = didContract.issueDID(user1, "ipfs://QmTest1");
        
        vm.startPrank(user1);
        
        string memory newURI = "ipfs://QmTest2";
        
        vm.expectEmit(true, true, false, true);
        emit DIDUpdated(user1, tokenId, newURI);
        
        didContract.updateMetadata(tokenId, newURI);
        
        assertEq(didContract.tokenURI(tokenId), newURI);
        
        vm.stopPrank();
    }

    function test_SetVerified() public {
        vm.prank(issuer);
        didContract.issueDID(user1, "ipfs://QmTest");
        
        vm.startPrank(admin);
        
        vm.expectEmit(true, false, false, true);
        emit VerificationStatusChanged(user1, true);
        
        didContract.setVerified(user1, true);
        
        assertTrue(didContract.isVerified(user1));
        
        vm.stopPrank();
    }

    function test_RevertWhen_TransferSoulbound() public {
        vm.prank(issuer);
        uint256 tokenId = didContract.issueDID(user1, "ipfs://QmTest");
        
        vm.startPrank(user1);
        
        vm.expectRevert(ITawfDID.Soulbound.selector);
        didContract.transferFrom(user1, user2, tokenId);
        
        vm.stopPrank();
    }

    function test_RevertWhen_UnauthorizedUpdate() public {
        vm.prank(issuer);
        uint256 tokenId = didContract.issueDID(user1, "ipfs://QmTest");
        
        vm.startPrank(user2);
        
        vm.expectRevert(ITawfDID.Unauthorized.selector);
        didContract.updateMetadata(tokenId, "ipfs://QmTest2");
        
        vm.stopPrank();
    }

    function test_MultipleUsers() public {
        vm.startPrank(issuer);
        
        uint256 tokenId1 = didContract.issueDID(user1, "ipfs://QmUser1");
        uint256 tokenId2 = didContract.issueDID(user2, "ipfs://QmUser2");
        
        assertEq(tokenId1, 1);
        assertEq(tokenId2, 2);
        assertTrue(didContract.hasDID(user1));
        assertTrue(didContract.hasDID(user2));
        
        vm.stopPrank();
    }
}
