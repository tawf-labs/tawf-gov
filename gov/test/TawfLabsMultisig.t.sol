// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/admin/TawfLabsMultisig.sol";

contract TawfLabsMultisigTest is Test {
    TawfLabsMultisig public multisig;
    
    address public signer1 = address(0x1);
    address public signer2 = address(0x2);
    address public signer3 = address(0x3);
    address public nonSigner = address(0x4);
    address public target = address(0x5);

    address[] public signers;

    function setUp() public {
        signers.push(signer1);
        signers.push(signer2);
        signers.push(signer3);

        multisig = new TawfLabsMultisig(signers, 2);
    }

    function test_SubmitTransaction() public {
        vm.prank(signer1);
        
        uint256 txId = multisig.submitTransaction(target, 1 ether, "");
        
        assertEq(txId, 0);
        assertEq(multisig.getTransactionCount(), 1);
    }

    function test_ConfirmTransaction() public {
        vm.prank(signer1);
        uint256 txId = multisig.submitTransaction(target, 1 ether, "");

        vm.prank(signer2);
        multisig.confirmTransaction(txId);

        assertTrue(multisig.isConfirmed(txId, signer2));
    }

    function test_ExecuteTransaction() public {
        vm.deal(address(multisig), 10 ether);

        vm.prank(signer1);
        uint256 txId = multisig.submitTransaction(target, 1 ether, "");

        vm.prank(signer1);
        multisig.confirmTransaction(txId);

        vm.prank(signer2);
        multisig.confirmTransaction(txId);

        uint256 balanceBefore = target.balance;

        vm.prank(signer1);
        multisig.executeTransaction(txId);

        assertEq(target.balance, balanceBefore + 1 ether);
    }

    function test_RevertWhen_InsufficientConfirmations() public {
        vm.prank(signer1);
        uint256 txId = multisig.submitTransaction(target, 1 ether, "");

        vm.prank(signer1);
        multisig.confirmTransaction(txId);

        vm.expectRevert(TawfLabsMultisig.InsufficientConfirmations.selector);
        multisig.executeTransaction(txId);
    }

    function test_RevokeConfirmation() public {
        vm.prank(signer1);
        uint256 txId = multisig.submitTransaction(target, 1 ether, "");

        vm.prank(signer2);
        multisig.confirmTransaction(txId);

        assertTrue(multisig.isConfirmed(txId, signer2));

        vm.prank(signer2);
        multisig.revokeConfirmation(txId);

        assertFalse(multisig.isConfirmed(txId, signer2));
    }

    function test_RevertWhen_NonSignerSubmits() public {
        vm.prank(nonSigner);
        
        vm.expectRevert();
        multisig.submitTransaction(target, 1 ether, "");
    }

    function test_RevertWhen_AlreadyExecuted() public {
        vm.deal(address(multisig), 10 ether);

        vm.prank(signer1);
        uint256 txId = multisig.submitTransaction(target, 1 ether, "");

        vm.prank(signer1);
        multisig.confirmTransaction(txId);

        vm.prank(signer2);
        multisig.confirmTransaction(txId);

        vm.prank(signer1);
        multisig.executeTransaction(txId);

        vm.expectRevert(TawfLabsMultisig.AlreadyExecuted.selector);
        multisig.executeTransaction(txId);
    }

    function test_AddSigner() public {
        address newSigner = address(0x6);

        multisig.addSigner(newSigner);

        assertTrue(multisig.isSigner(newSigner));
        assertEq(multisig.getSignerCount(), 4);
    }

    function test_RemoveSigner() public {
        multisig.removeSigner(signer3);

        assertFalse(multisig.isSigner(signer3));
        assertEq(multisig.getSignerCount(), 2);
    }

    function test_UpdateThreshold() public {
        multisig.updateThreshold(3);
        
        assertEq(multisig.threshold(), 3);
    }

    function test_RevertWhen_InvalidThreshold() public {
        vm.expectRevert(TawfLabsMultisig.InvalidThreshold.selector);
        multisig.updateThreshold(5); // More than signer count
    }

    function test_MultipleTransactions() public {
        vm.deal(address(multisig), 10 ether);

        vm.startPrank(signer1);
        uint256 tx1 = multisig.submitTransaction(target, 1 ether, "");
        uint256 tx2 = multisig.submitTransaction(target, 2 ether, "");
        vm.stopPrank();

        assertEq(tx1, 0);
        assertEq(tx2, 1);
        assertEq(multisig.getTransactionCount(), 2);
    }
}
