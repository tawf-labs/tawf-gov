// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TawfLabsMultisig
 * @notice Tawf Labs Multisig Wallet
 * @dev Simple multisig for protocol operations with threshold-based execution
 */
contract TawfLabsMultisig is AccessControl, ReentrancyGuard {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    // Transaction structure
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 timestamp;
    }

    // Events
    event TransactionSubmitted(uint256 indexed txId, address indexed to, uint256 value, bytes data);
    event TransactionConfirmed(uint256 indexed txId, address indexed signer);
    event TransactionRevoked(uint256 indexed txId, address indexed signer);
    event TransactionExecuted(uint256 indexed txId);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);
    event ThresholdChanged(uint256 newThreshold);

    // Errors
    error TransactionNotFound();
    error AlreadyExecuted();
    error AlreadyConfirmed();
    error NotConfirmed();
    error InsufficientConfirmations();
    error ExecutionFailed();
    error InvalidThreshold();
    error InvalidSigner();

    // State variables
    address[] public signers;
    mapping(address => bool) public isSigner;
    uint256 public threshold;

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    constructor(address[] memory _signers, uint256 _threshold) {
        if (_threshold == 0 || _threshold > _signers.length) revert InvalidThreshold();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            if (signer == address(0) || isSigner[signer]) revert InvalidSigner();

            isSigner[signer] = true;
            signers.push(signer);
            _grantRole(SIGNER_ROLE, signer);
        }

        threshold = _threshold;
    }

    /**
     * @notice Submit a new transaction
     * @param to Target address
     * @param value ETH value
     * @param data Call data
     */
    function submitTransaction(address to, uint256 value, bytes calldata data)
        external
        onlyRole(SIGNER_ROLE)
        returns (uint256 txId)
    {
        txId = transactions.length;

        transactions.push(
            Transaction({
                to: to,
                value: value,
                data: data,
                executed: false,
                confirmations: 0,
                timestamp: block.timestamp
            })
        );

        emit TransactionSubmitted(txId, to, value, data);
    }

    /**
     * @notice Confirm a transaction
     * @param txId Transaction ID
     */
    function confirmTransaction(uint256 txId) external onlyRole(SIGNER_ROLE) {
        if (txId >= transactions.length) revert TransactionNotFound();
        if (transactions[txId].executed) revert AlreadyExecuted();
        if (confirmations[txId][msg.sender]) revert AlreadyConfirmed();

        confirmations[txId][msg.sender] = true;
        transactions[txId].confirmations++;

        emit TransactionConfirmed(txId, msg.sender);
    }

    /**
     * @notice Revoke confirmation
     * @param txId Transaction ID
     */
    function revokeConfirmation(uint256 txId) external onlyRole(SIGNER_ROLE) {
        if (txId >= transactions.length) revert TransactionNotFound();
        if (transactions[txId].executed) revert AlreadyExecuted();
        if (!confirmations[txId][msg.sender]) revert NotConfirmed();

        confirmations[txId][msg.sender] = false;
        transactions[txId].confirmations--;

        emit TransactionRevoked(txId, msg.sender);
    }

    /**
     * @notice Execute a transaction
     * @param txId Transaction ID
     */
    function executeTransaction(uint256 txId) external nonReentrant {
        if (txId >= transactions.length) revert TransactionNotFound();
        
        Transaction storage txn = transactions[txId];
        
        if (txn.executed) revert AlreadyExecuted();
        if (txn.confirmations < threshold) revert InsufficientConfirmations();

        txn.executed = true;

        (bool success,) = txn.to.call{value: txn.value}(txn.data);
        if (!success) revert ExecutionFailed();

        emit TransactionExecuted(txId);
    }

    /**
     * @notice Add a new signer
     * @param signer Address to add
     */
    function addSigner(address signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (signer == address(0) || isSigner[signer]) revert InvalidSigner();

        isSigner[signer] = true;
        signers.push(signer);
        _grantRole(SIGNER_ROLE, signer);

        emit SignerAdded(signer);
    }

    /**
     * @notice Remove a signer
     * @param signer Address to remove
     */
    function removeSigner(address signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!isSigner[signer]) revert InvalidSigner();
        if (signers.length - 1 < threshold) revert InvalidThreshold();

        isSigner[signer] = false;
        _revokeRole(SIGNER_ROLE, signer);

        // Remove from array
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }

        emit SignerRemoved(signer);
    }

    /**
     * @notice Update threshold
     * @param _threshold New threshold
     */
    function updateThreshold(uint256 _threshold) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_threshold == 0 || _threshold > signers.length) revert InvalidThreshold();

        threshold = _threshold;
        emit ThresholdChanged(_threshold);
    }

    /**
     * @notice Get transaction count
     */
    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    /**
     * @notice Get signer count
     */
    function getSignerCount() external view returns (uint256) {
        return signers.length;
    }

    /**
     * @notice Get all signers
     */
    function getSigners() external view returns (address[] memory) {
        return signers;
    }

    /**
     * @notice Check if transaction is confirmed by signer
     * @param txId Transaction ID
     * @param signer Signer address
     */
    function isConfirmed(uint256 txId, address signer) external view returns (bool) {
        return confirmations[txId][signer];
    }

    /**
     * @notice Get transaction details
     * @param txId Transaction ID
     */
    function getTransaction(uint256 txId)
        external
        view
        returns (address to, uint256 value, bytes memory data, bool executed, uint256 confirmationCount)
    {
        if (txId >= transactions.length) revert TransactionNotFound();
        
        Transaction storage txn = transactions[txId];
        return (txn.to, txn.value, txn.data, txn.executed, txn.confirmations);
    }

    /**
     * @notice Receive ETH
     */
    receive() external payable {}
}
