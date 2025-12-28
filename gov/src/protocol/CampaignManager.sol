// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../interfaces/ICampaignManager.sol";
import "../interfaces/IVendorRegistry.sol";
import "../interfaces/INFTReceiptIssuer.sol";

/**
 * @title CampaignManager
 * @notice Campaign Management Contract
 * @dev Manages fundraising campaigns and contributions
 */
contract CampaignManager is AccessControl, ReentrancyGuard, Pausable, ICampaignManager {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    IVendorRegistry public immutable vendorRegistry;
    INFTReceiptIssuer public immutable receiptIssuer;

    // Campaign storage
    mapping(uint256 => Campaign) private _campaigns;
    mapping(uint256 => mapping(address => Contribution)) private _contributions;
    mapping(uint256 => address[]) private _campaignContributors;
    
    uint256 private _campaignCount;

    // Minimum campaign duration
    uint256 public constant MIN_DURATION = 1 days;
    uint256 public constant MAX_DURATION = 365 days;

    constructor(address _vendorRegistry, address _receiptIssuer) {
        vendorRegistry = IVendorRegistry(_vendorRegistry);
        receiptIssuer = INFTReceiptIssuer(_receiptIssuer);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(VERIFIER_ROLE, msg.sender);
    }

    /**
     * @notice Create a new campaign
     * @param title Campaign title
     * @param descriptionURI IPFS URI with campaign details
     * @param goal Fundraising goal
     * @param duration Duration in seconds
     */
    function createCampaign(string calldata title, string calldata descriptionURI, uint256 goal, uint256 duration)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 id)
    {
        // Check vendor is verified
        if (!vendorRegistry.isVerified(msg.sender)) revert Unauthorized();
        if (goal == 0) revert InvalidAmount();
        if (duration < MIN_DURATION || duration > MAX_DURATION) revert InvalidAmount();

        _campaignCount++;
        id = _campaignCount;

        _campaigns[id] = Campaign({
            id: id,
            organizer: msg.sender,
            title: title,
            descriptionURI: descriptionURI,
            goal: goal,
            raised: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            status: CampaignStatus.Active,
            verified: false
        });

        // Add campaign to vendor's record
        vendorRegistry.addCampaign(msg.sender, id);

        emit CampaignCreated(id, msg.sender, title, goal, block.timestamp + duration);
    }

    /**
     * @notice Contribute to a campaign
     * @param campaignId ID of the campaign
     */
    function contribute(uint256 campaignId) external payable whenNotPaused nonReentrant {
        if (campaignId == 0 || campaignId > _campaignCount) revert CampaignNotFound();
        if (msg.value == 0) revert InvalidAmount();

        Campaign storage campaign = _campaigns[campaignId];

        if (campaign.status != CampaignStatus.Active) revert CampaignNotActive();
        if (block.timestamp > campaign.endTime) revert CampaignNotActive();
        if (campaign.raised >= campaign.goal) revert GoalReached();

        // Update contribution
        Contribution storage contribution = _contributions[campaignId][msg.sender];
        
        if (contribution.amount == 0) {
            _campaignContributors[campaignId].push(msg.sender);
        }

        contribution.campaignId = campaignId;
        contribution.contributor = msg.sender;
        contribution.amount += msg.value;
        contribution.timestamp = block.timestamp;

        // Update campaign
        campaign.raised += msg.value;

        // Issue receipt NFT
        string memory receiptURI = string(
            abi.encodePacked("ipfs://receipt/", _uint2str(campaignId), "/", _addressToString(msg.sender))
        );
        
        uint256 receiptTokenId = receiptIssuer.issueReceipt(msg.sender, campaignId, msg.value, receiptURI);
        contribution.receiptTokenId = receiptTokenId;

        // Check if goal reached
        if (campaign.raised >= campaign.goal) {
            campaign.status = CampaignStatus.Completed;
            emit CampaignStatusChanged(campaignId, CampaignStatus.Completed);
        }

        emit ContributionMade(campaignId, msg.sender, msg.value, receiptTokenId);
    }

    /**
     * @notice Verify a campaign (by admin)
     * @param campaignId ID of the campaign
     */
    function verifyCampaign(uint256 campaignId) external onlyRole(VERIFIER_ROLE) {
        if (campaignId == 0 || campaignId > _campaignCount) revert CampaignNotFound();

        Campaign storage campaign = _campaigns[campaignId];
        campaign.verified = true;

        emit CampaignVerified(campaignId);
    }

    /**
     * @notice Update campaign status
     * @param campaignId ID of the campaign
     * @param status New status
     */
    function updateCampaignStatus(uint256 campaignId, CampaignStatus status)
        external
        onlyRole(ADMIN_ROLE)
    {
        if (campaignId == 0 || campaignId > _campaignCount) revert CampaignNotFound();

        _campaigns[campaignId].status = status;
        emit CampaignStatusChanged(campaignId, status);
    }

    /**
     * @notice Withdraw funds from completed campaign
     * @param campaignId ID of the campaign
     */
    function withdrawFunds(uint256 campaignId) external nonReentrant {
        if (campaignId == 0 || campaignId > _campaignCount) revert CampaignNotFound();

        Campaign storage campaign = _campaigns[campaignId];

        if (msg.sender != campaign.organizer) revert Unauthorized();
        if (campaign.status != CampaignStatus.Completed) revert CampaignNotActive();
        if (campaign.raised == 0) revert InvalidAmount();

        uint256 amount = campaign.raised;
        campaign.raised = 0;

        (bool success,) = campaign.organizer.call{value: amount}("");
        if (!success) revert InvalidAmount();
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Get campaign details
     * @param campaignId ID of the campaign
     */
    function getCampaign(uint256 campaignId) external view returns (Campaign memory) {
        if (campaignId == 0 || campaignId > _campaignCount) revert CampaignNotFound();
        return _campaigns[campaignId];
    }

    /**
     * @notice Get contribution details
     * @param campaignId ID of the campaign
     * @param contributor Address of contributor
     */
    function getContribution(uint256 campaignId, address contributor)
        external
        view
        returns (Contribution memory)
    {
        return _contributions[campaignId][contributor];
    }

    /**
     * @notice Get campaign contributors
     * @param campaignId ID of the campaign
     */
    function getCampaignContributors(uint256 campaignId) external view returns (address[] memory) {
        return _campaignContributors[campaignId];
    }

    /**
     * @notice Get total campaign count
     */
    function getCampaignCount() external view returns (uint256) {
        return _campaignCount;
    }

    // Helper functions
    function _uint2str(uint256 _i) private pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _addressToString(address _addr) private pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}
