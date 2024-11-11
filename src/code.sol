// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract WrappedSongDistributor is Ownable, ReentrancyGuard {
    struct Distribution {
        uint256 timestamp;
        uint256 amount;
        uint256 remainingAmount;
    }

    struct UserToken {
        uint256 amount;
        uint256 timestamp;
    }

    struct UserClaim {
        uint256 amount;
        uint256 lastClaimTimestamp;
    }

    // Song ID => User Address => UserToken[]
    mapping(bytes32 => mapping(address => UserToken[])) public userTokens;

    // Song ID => User Address => UserClaim
    mapping(bytes32 => mapping(address => UserClaim)) public userClaims;

    // Array to store all distributions
    Distribution[] public distributions;

    // Total earnings in the contract
    uint256 public totalEarnings;

    // USDC token contract
    IERC20 public usdcToken;

    event TokensTransferred(
        bytes32 songId,
        address from,
        address to,
        uint256 amount
    );
    event EarningsClaimed(bytes32 songId, address user, uint256 amount);
    event DistributionAdded(uint256 timestamp, uint256 amount);

    constructor(address _usdcToken) {
        usdcToken = IERC20(_usdcToken);
    }

    function addDistribution(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(
            usdcToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        distributions.push(
            Distribution({
                timestamp: block.timestamp,
                amount: amount,
                remainingAmount: amount
            })
        );

        totalEarnings += amount;

        emit DistributionAdded(block.timestamp, amount);
    }

    function claimEarnings(bytes32 songId) external nonReentrant {
        UserToken[] storage tokens = userTokens[songId][msg.sender];
        require(tokens.length > 0, "No tokens owned");

        uint256 earnings = 0;
        uint256 lastClaimTimestamp = userClaims[songId][msg.sender]
            .lastClaimTimestamp;

        // Calculate earnings from each distribution
        for (uint256 i = 0; i < distributions.length; i++) {
            Distribution storage dist = distributions[i];
            if (dist.timestamp > lastClaimTimestamp) {
                // Calculate earnings for each token based on timestamp
                for (uint256 j = 0; j < tokens.length; j++) {
                    if (tokens[j].timestamp <= dist.timestamp) {
                        uint256 share = (tokens[j].amount * 1e18) / 10000; // Convert to 18 decimals
                        uint256 earning = (share * dist.amount) / 1e18;
                        earnings += earning;
                        dist.remainingAmount -= earning;
                    }
                }
            }
        }

        require(earnings > 0, "No earnings to claim");

        // Update user claim record
        userClaims[songId][msg.sender].amount += earnings;
        userClaims[songId][msg.sender].lastClaimTimestamp = block.timestamp;

        // Consolidate tokens into a single token with updated timestamp
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            totalAmount += tokens[i].amount;
        }

        delete userTokens[songId][msg.sender];
        userTokens[songId][msg.sender].push(
            UserToken({amount: totalAmount, timestamp: block.timestamp})
        );

        // Transfer USDC to user
        require(usdcToken.transfer(msg.sender, earnings), "Transfer failed");
        totalEarnings -= earnings;

        emit EarningsClaimed(songId, msg.sender, earnings);
    }

    function transferTokens(
        bytes32 songId,
        address recipient,
        uint256 amount
    ) external {
        require(recipient != msg.sender, "Cannot transfer to self");
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");

        UserToken[] storage senderTokens = userTokens[songId][msg.sender];
        require(senderTokens.length > 0, "No tokens owned");

        uint256 senderTotal = 0;
        for (uint256 i = 0; i < senderTokens.length; i++) {
            senderTotal += senderTokens[i].amount;
        }
        require(senderTotal >= amount, "Insufficient tokens");

        // Transfer tokens
        userTokens[songId][recipient].push(
            UserToken({amount: amount, timestamp: block.timestamp})
        );

        // Update sender's tokens
        senderTokens[0].amount -= amount;

        emit TokensTransferred(songId, msg.sender, recipient, amount);
    }
}
