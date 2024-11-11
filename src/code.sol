// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WrappedSongDistributor is Ownable {
    struct DistributorTimestamp {
        uint256 timestamp;
        uint256 amount;
        uint256 remainingAmount;
    }

    struct UserToken {
        uint256 amount;
        uint256 timestamp;
        uint256 value;
    }

    struct UserClaim {
        uint256 amount;
        uint256 timestamp;
    }

    // USDC token contract
    IERC20 public usdcToken;

    // Total earnings in the contract
    uint256 public totalEarnings;

    // Array to store distribution events
    DistributorTimestamp[] public distributorTimestamps;

    // Mapping: songId => userId => UserToken[]
    mapping(bytes32 => mapping(address => UserToken[])) public userTokens;

    // Mapping: songId => userId => UserClaim
    mapping(bytes32 => mapping(address => UserClaim)) public userClaims;

    // Constants
    uint256 private constant PRECISION = 10000;

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
        require(
            usdcToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        distributorTimestamps.push(
            DistributorTimestamp({
                timestamp: block.timestamp,
                amount: amount,
                remainingAmount: amount
            })
        );

        totalEarnings += amount;

        emit DistributionAdded(block.timestamp, amount);
    }

    function claimEarnings(bytes32 songId) external {
        UserClaim storage userClaim = userClaims[songId][msg.sender];
        UserToken[] storage tokens = userTokens[songId][msg.sender];

        uint256 earnings = 0;

        // Calculate earnings from each distribution timestamp
        for (uint256 i = 0; i < distributorTimestamps.length; i++) {
            DistributorTimestamp storage dt = distributorTimestamps[i];

            if (dt.timestamp <= userClaim.timestamp) continue;

            // Calculate earnings for each token
            for (uint256 j = 0; j < tokens.length; j++) {
                UserToken storage token = tokens[j];
                if (token.timestamp <= dt.timestamp) {
                    uint256 tokenEarnings = (token.amount * dt.amount) /
                        PRECISION;
                    earnings += tokenEarnings;
                    dt.remainingAmount -= tokenEarnings;
                }
            }
        }

        require(earnings > 0, "No earnings to claim");

        // Update user claim
        userClaim.amount += earnings;
        userClaim.timestamp = block.timestamp;

        // Consolidate tokens into a single token
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            totalAmount += tokens[i].amount;
        }

        delete userTokens[songId][msg.sender];
        userTokens[songId][msg.sender].push(
            UserToken({
                amount: totalAmount,
                timestamp: block.timestamp,
                value: 0
            })
        );

        // Transfer USDC to user
        require(usdcToken.transfer(msg.sender, earnings), "Transfer failed");

        emit EarningsClaimed(songId, msg.sender, earnings);
    }

    function transferTokens(
        bytes32 songId,
        address recipient,
        uint256 amount
    ) external {
        require(recipient != msg.sender, "Cannot transfer to self");
        require(recipient != address(0), "Invalid recipient");

        UserToken[] storage senderTokens = userTokens[songId][msg.sender];

        uint256 totalSenderTokens = 0;
        for (uint256 i = 0; i < senderTokens.length; i++) {
            totalSenderTokens += senderTokens[i].amount;
        }

        require(totalSenderTokens >= amount, "Insufficient tokens");

        // Create new token for recipient
        userTokens[songId][recipient].push(
            UserToken({amount: amount, timestamp: block.timestamp, value: 0})
        );

        // Update sender's tokens
        senderTokens[0].amount -= amount;

        emit TokensTransferred(songId, msg.sender, recipient, amount);
    }
}
