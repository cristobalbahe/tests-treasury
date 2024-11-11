// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title WrappedSongToken
 * @notice This contract manages the tokenization of songs and their revenue distribution
 */
contract WrappedSongToken is ERC20, Ownable {
    // Struct to track distribution events
    struct Distribution {
        uint256 timestamp;
        uint256 amount;
        uint256 remainingAmount;
    }

    // Struct to track user token holdings with timestamps
    struct TokenHolding {
        uint256 amount;
        uint256 timestamp;
    }

    // Mapping of user address to their token holdings
    mapping(address => TokenHolding[]) public userTokens;

    // Array to store all distribution events
    Distribution[] public distributions;

    // Mapping to track claimed amounts per user
    mapping(address => uint256) public claimedAmounts;

    // Total earnings in the contract
    uint256 public totalEarnings;

    constructor() ERC20("WrappedSongToken", "WST") {}

    /**
     * @notice Adds a new revenue distribution
     * @param amount The amount of USDC to distribute
     */
    function addDistribution(uint256 amount) external onlyOwner {
        distributions.push(
            Distribution({
                timestamp: block.timestamp,
                amount: amount,
                remainingAmount: amount
            })
        );
        totalEarnings += amount;
    }

    /**
     * @notice Allows users to claim their earnings based on token holdings
     */
    function claimEarnings() external {
        uint256 earnings = 0;
        address user = msg.sender;

        // Calculate earnings for each distribution event
        for (uint i = 0; i < distributions.length; i++) {
            Distribution storage dist = distributions[i];

            // Skip if distribution is fully claimed
            if (dist.remainingAmount == 0) continue;

            // Calculate user's share for this distribution
            for (uint j = 0; j < userTokens[user].length; j++) {
                TokenHolding storage holding = userTokens[user][j];

                if (holding.timestamp <= dist.timestamp) {
                    // Calculate proportional earnings (similar to React implementation)
                    uint256 share = (holding.amount * dist.amount) / 10000;
                    earnings += share;
                    dist.remainingAmount -= share;
                }
            }
        }

        require(earnings > 0, "No earnings to claim");

        // Update claimed amounts
        claimedAmounts[user] += earnings;

        // Reset user's token timestamp to current
        uint256 totalTokens = balanceOf(user);
        delete userTokens[user];
        userTokens[user].push(
            TokenHolding({amount: totalTokens, timestamp: block.timestamp})
        );

        // Transfer earnings (assuming USDC integration)
        // This would require actual USDC contract integration
        // USDC.transfer(user, earnings);
    }

    /**
     * @notice Allows users to transfer tokens while maintaining timestamp data
     * @param to Recipient address
     * @param amount Amount of tokens to transfer
     */
    function transferWithTimestamp(address to, uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        // Transfer tokens
        _transfer(msg.sender, to, amount);

        // Update sender's token holdings
        uint256 senderTotal = balanceOf(msg.sender);
        delete userTokens[msg.sender];
        userTokens[msg.sender].push(
            TokenHolding({amount: senderTotal, timestamp: block.timestamp})
        );

        // Update recipient's token holdings
        userTokens[to].push(
            TokenHolding({amount: amount, timestamp: block.timestamp})
        );
    }

    // Additional helper functions would be needed for:
    // - Viewing unclaimed earnings
    // - Getting user token history
    // - USDC integration
    // - Emergency functions
}
