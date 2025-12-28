// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/**
 * @title ICampaignManager
 * @notice Interface for Campaign Management
 * @dev Manages fundraising campaigns and contributions
 */
interface ICampaignManager {
    enum CampaignStatus {
        Active,
        Completed,
        Canceled,
        Paused
    }

    struct Campaign {
        uint256 id;
        address organizer;
        string title;
        string descriptionURI;
        uint256 goal;
        uint256 raised;
        uint256 startTime;
        uint256 endTime;
        CampaignStatus status;
        bool verified;
    }

    struct Contribution {
        uint256 campaignId;
        address contributor;
        uint256 amount;
        uint256 timestamp;
        uint256 receiptTokenId;
    }

    // Events
    event CampaignCreated(
        uint256 indexed id, address indexed organizer, string title, uint256 goal, uint256 endTime
    );
    event ContributionMade(
        uint256 indexed campaignId, address indexed contributor, uint256 amount, uint256 receiptTokenId
    );
    event CampaignStatusChanged(uint256 indexed id, CampaignStatus status);
    event CampaignVerified(uint256 indexed id);

    // Errors
    error CampaignNotActive();
    error CampaignNotFound();
    error GoalReached();
    error InvalidAmount();
    error Unauthorized();
    error ContractPaused();

    /**
     * @notice Create a new campaign
     * @param title Campaign title
     * @param descriptionURI IPFS URI with campaign details
     * @param goal Fundraising goal
     * @param duration Duration in seconds
     */
    function createCampaign(string calldata title, string calldata descriptionURI, uint256 goal, uint256 duration)
        external
        returns (uint256 id);

    /**
     * @notice Contribute to a campaign
     * @param campaignId ID of the campaign
     */
    function contribute(uint256 campaignId) external payable;

    /**
     * @notice Verify a campaign (by admin)
     * @param campaignId ID of the campaign
     */
    function verifyCampaign(uint256 campaignId) external;

    /**
     * @notice Update campaign status
     * @param campaignId ID of the campaign
     * @param status New status
     */
    function updateCampaignStatus(uint256 campaignId, CampaignStatus status) external;

    /**
     * @notice Get campaign details
     * @param campaignId ID of the campaign
     */
    function getCampaign(uint256 campaignId) external view returns (Campaign memory);

    /**
     * @notice Get contribution details
     * @param campaignId ID of the campaign
     * @param contributor Address of contributor
     */
    function getContribution(uint256 campaignId, address contributor)
        external
        view
        returns (Contribution memory);
}
