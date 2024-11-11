// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title WrappedSongToken
 * @notice This contract manages the tokenization of songs and their revenue distribution
 * @dev Main features:
 * 1. Users can hold tokens representing song ownership
 * 2. Revenue is distributed based on token holdings
 * 3. Users can transfer tokens
 * 4. Users can claim their earnings
 */
contract WrappedSongToken is ERC20, Ownable {
    // Struct to track distribution events
    struct Distribution {
        uint256 timestamp;
        uint256 amount;
        uint256 remainingAmount;
    }

    // Struct to track user claims
    struct UserClaim {
        uint256 amount;
        uint256 lastClaimTimestamp;
    }

    // Array of all distribution events
    Distribution[] public distributions;

    // Mapping of user address to their claim info
    mapping(address => UserClaim) public userClaims;

    // Mapping to track token acquisition timestamps
    mapping(address => mapping(uint256 => uint256))
        public tokenAcquisitionTimestamps;

    uint256 public constant PRECISION = 10000;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
     * @notice Distributes new revenue to token holders
     * @param amount Amount of USDC to distribute
     */
    function distributeRevenue(uint256 amount) external onlyOwner {
        distributions.push(
            Distribution({
                timestamp: block.timestamp,
                amount: amount,
                remainingAmount: amount
            })
        );
    }

    /**
     * @notice Allows users to claim their earned revenue
     * @dev Calculates earnings based on token holdings during each distribution period
     * @return claimedAmount The amount claimed
     */
    function claimEarnings() external returns (uint256 claimedAmount) {
        UserClaim storage userClaim = userClaims[msg.sender];
        uint256 userBalance = balanceOf(msg.sender);

        for (uint256 i = 0; i < distributions.length; i++) {
            Distribution storage dist = distributions[i];

            // Skip if distribution is before last claim
            if (dist.timestamp <= userClaim.lastClaimTimestamp) continue;
            if (dist.remainingAmount == 0) continue;

            // Calculate user's share of this distribution
            uint256 userShare = (userBalance * dist.amount) /
                (totalSupply() * PRECISION);
            claimedAmount += userShare;
            dist.remainingAmount -= userShare;
        }

        require(claimedAmount > 0, "No earnings to claim");

        userClaim.amount += claimedAmount;
        userClaim.lastClaimTimestamp = block.timestamp;

        // Here you would typically transfer USDC to the user
        // Requires USDC integration
    }

    /**
     * @notice Override of ERC20 transfer to track token acquisition timestamps
     * @param to Recipient address
     * @param amount Amount of tokens to transfer
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(to != address(0), "Cannot transfer to zero address");
        require(to != msg.sender, "Cannot transfer to self");

        // Update token acquisition timestamp for recipient
        tokenAcquisitionTimestamps[to][block.timestamp] = amount;

        return super.transfer(to, amount);
    }

    /**
     * @notice Mints initial tokens to users
     * @param user Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mintInitialTokens(
        address user,
        uint256 amount
    ) external onlyOwner {
        _mint(user, amount);
        tokenAcquisitionTimestamps[user][block.timestamp] = amount;
    }

    /**
     * @notice Gets all distributions
     * @return Distribution[] Array of all distribution events
     */
    function getDistributions() external view returns (Distribution[] memory) {
        return distributions;
    }

    /**
     * @notice Gets user's claim info
     * @param user Address of user
     * @return UserClaim struct containing user's claim info
     */
    function getUserClaim(
        address user
    ) external view returns (UserClaim memory) {
        return userClaims[user];
    }
}
