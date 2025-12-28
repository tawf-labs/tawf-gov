// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/ICommunityDAO.sol";
import "../interfaces/ITawfDID.sol";
import "../interfaces/ITawfReputation.sol";

/**
 * @title CommunityDAO
 * @notice Community DAO Governance Contract
 * @dev Allows community members to create and vote on proposals
 */
contract CommunityDAO is AccessControl, ReentrancyGuard, ICommunityDAO {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    ITawfDID public immutable didContract;
    ITawfReputation public immutable reputationContract;

    // Governance parameters
    uint256 public proposalThreshold; // Minimum reputation to propose
    uint256 public votingDelay; // Delay before voting starts (in blocks)
    uint256 public votingPeriod; // Voting period (in blocks)
    uint256 public quorumVotes; // Minimum votes for quorum

    // Proposal storage
    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => mapping(address => bool)) private _hasVoted;
    mapping(uint256 => mapping(address => uint256)) private _voteWeight;
    
    uint256 private _proposalCount;

    constructor(
        address _didContract,
        address _reputationContract,
        uint256 _proposalThreshold,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _quorumVotes
    ) {
        didContract = ITawfDID(_didContract);
        reputationContract = ITawfReputation(_reputationContract);
        proposalThreshold = _proposalThreshold;
        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        quorumVotes = _quorumVotes;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Create a new proposal
     * @param title Proposal title
     * @param description Proposal description
     * @param callData Encoded call data for execution
     */
    function propose(string calldata title, string calldata description, bytes calldata callData)
        external
        nonReentrant
        returns (uint256 proposalId)
    {
        // Check proposer has DID
        if (!didContract.hasDID(msg.sender)) revert Unauthorized();

        // Check proposer meets reputation threshold
        if (!reputationContract.hasMinimumReputation(msg.sender, proposalThreshold)) {
            revert InsufficientReputation();
        }

        _proposalCount++;
        proposalId = _proposalCount;

        uint256 startBlock = block.number + votingDelay;
        uint256 endBlock = startBlock + votingPeriod;

        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            title: title,
            description: description,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            startBlock: startBlock,
            endBlock: endBlock,
            state: ProposalState.Pending,
            callData: callData
        });

        emit ProposalCreated(proposalId, msg.sender, title, startBlock, endBlock);
    }

    /**
     * @notice Cast a vote on a proposal
     * @param proposalId ID of the proposal
     * @param support 0 = Against, 1 = For, 2 = Abstain
     */
    function castVote(uint256 proposalId, uint8 support) external nonReentrant {
        if (proposalId == 0 || proposalId > _proposalCount) revert InvalidProposal();
        if (!didContract.hasDID(msg.sender)) revert Unauthorized();
        if (state(proposalId) != ProposalState.Active) revert ProposalNotActive();
        if (_hasVoted[proposalId][msg.sender]) revert AlreadyVoted();

        Proposal storage proposal = _proposals[proposalId];
        uint256 weight = reputationContract.getReputation(msg.sender);

        _hasVoted[proposalId][msg.sender] = true;
        _voteWeight[proposalId][msg.sender] = weight;

        if (support == 0) {
            proposal.againstVotes += weight;
        } else if (support == 1) {
            proposal.forVotes += weight;
        } else if (support == 2) {
            proposal.abstainVotes += weight;
        } else {
            revert InvalidProposal();
        }

        emit VoteCast(msg.sender, proposalId, support, weight);
    }

    /**
     * @notice Execute a proposal
     * @param proposalId ID of the proposal
     */
    function execute(uint256 proposalId) external onlyRole(ADMIN_ROLE) nonReentrant {
        if (state(proposalId) != ProposalState.Succeeded) revert InvalidProposal();

        Proposal storage proposal = _proposals[proposalId];
        proposal.state = ProposalState.Executed;

        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Cancel a proposal
     * @param proposalId ID of the proposal
     */
    function cancel(uint256 proposalId) external {
        if (proposalId == 0 || proposalId > _proposalCount) revert InvalidProposal();
        
        Proposal storage proposal = _proposals[proposalId];
        
        if (msg.sender != proposal.proposer && !hasRole(ADMIN_ROLE, msg.sender)) {
            revert Unauthorized();
        }

        proposal.state = ProposalState.Canceled;
        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice Get proposal details
     * @param proposalId ID of the proposal
     */
    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        if (proposalId == 0 || proposalId > _proposalCount) revert InvalidProposal();
        return _proposals[proposalId];
    }

    /**
     * @notice Get proposal state
     * @param proposalId ID of the proposal
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        if (proposalId == 0 || proposalId > _proposalCount) revert InvalidProposal();

        Proposal storage proposal = _proposals[proposalId];

        if (proposal.state == ProposalState.Canceled) return ProposalState.Canceled;
        if (proposal.state == ProposalState.Executed) return ProposalState.Executed;
        if (proposal.state == ProposalState.Queued) return ProposalState.Queued;

        if (block.number < proposal.startBlock) return ProposalState.Pending;
        if (block.number <= proposal.endBlock) return ProposalState.Active;

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        
        if (totalVotes < quorumVotes) return ProposalState.Defeated;
        if (proposal.forVotes > proposal.againstVotes) return ProposalState.Succeeded;
        
        return ProposalState.Defeated;
    }

    /**
     * @notice Check if an address has voted
     * @param proposalId ID of the proposal
     * @param voter Address to check
     */
    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        return _hasVoted[proposalId][voter];
    }

    /**
     * @notice Update governance parameters
     */
    function updateParameters(
        uint256 _proposalThreshold,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _quorumVotes
    ) external onlyRole(ADMIN_ROLE) {
        proposalThreshold = _proposalThreshold;
        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        quorumVotes = _quorumVotes;
    }
}
