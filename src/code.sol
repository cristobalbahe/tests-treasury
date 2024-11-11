// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MusicRoyaltyDistributor is Ownable {
    IERC20 public usdcToken;

    struct TokenInfo {
        uint256 amount;
        uint256 timestamp;
    }

    struct Distribution {
        uint256 timestamp;
        uint256 amount;
        uint256 remainingAmount;
    }

    // wrappedSongId => userId => TokenInfo[]
    mapping(bytes32 => mapping(address => TokenInfo[])) public userTokens;

    // wrappedSongId => userId => claimed amount
    mapping(bytes32 => mapping(address => uint256)) public userClaimed;

    // Array to store all distributions
    Distribution[] public distributions;

    // Total earnings in the contract
    uint256 public totalEarnings;

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

    function mintInitialTokens(
        bytes32 songId,
        address user,
        uint256 amount
    ) external onlyOwner {
        TokenInfo[] storage tokens = userTokens[songId][user];
        tokens.push(TokenInfo({amount: amount, timestamp: block.timestamp}));
    }

    function transferTokens(
        bytes32 songId,
        address recipient,
        uint256 transferAmount
    ) external {
        require(recipient != msg.sender, "Cannot transfer to self");
        require(recipient != address(0), "Invalid recipient");

        TokenInfo[] storage senderTokens = userTokens[songId][msg.sender];
        uint256 remainingAmount = transferAmount;

        // Temporary array to store new recipient tokens
        TokenInfo[] memory newRecipientTokens = new TokenInfo[](
            senderTokens.length
        );
        uint256 newTokensCount = 0;

        // Process transfer maintaining timestamp order
        for (
            uint256 i = 0;
            i < senderTokens.length && remainingAmount > 0;
            i++
        ) {
            uint256 available = senderTokens[i].amount;
            uint256 amountToDeduct = remainingAmount < available
                ? remainingAmount
                : available;

            if (amountToDeduct > 0) {
                // Add to recipient's tokens
                newRecipientTokens[newTokensCount] = TokenInfo({
                    amount: amountToDeduct,
                    timestamp: senderTokens[i].timestamp
                });
                newTokensCount++;

                // Deduct from sender's tokens
                senderTokens[i].amount -= amountToDeduct;
                remainingAmount -= amountToDeduct;
            }
        }

        require(remainingAmount == 0, "Insufficient tokens");

        // Add new tokens to recipient
        for (uint256 i = 0; i < newTokensCount; i++) {
            userTokens[songId][recipient].push(newRecipientTokens[i]);
        }

        // Clean up empty token entries from sender
        _cleanupEmptyTokens(songId, msg.sender);

        emit TokensTransferred(songId, msg.sender, recipient, transferAmount);
    }

    function addDistribution(uint256 amount) external onlyOwner {
        require(
            usdcToken.transferFrom(msg.sender, address(this), amount),
            "USDC transfer failed"
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

    function claimEarnings(bytes32 songId) external {
        TokenInfo[] storage tokens = userTokens[songId][msg.sender];
        require(tokens.length > 0, "No tokens owned");

        uint256 earnings = 0;
        uint256 earliestTimestamp = type(uint256).max;

        // Find earliest timestamp
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i].timestamp < earliestTimestamp) {
                earliestTimestamp = tokens[i].timestamp;
            }
        }

        // Calculate earnings from each distribution
        for (uint256 i = 0; i < distributions.length; i++) {
            Distribution storage dist = distributions[i];
            if (
                dist.timestamp > earliestTimestamp && dist.remainingAmount > 0
            ) {
                uint256 userShare = _calculateUserShare(
                    songId,
                    msg.sender,
                    dist.timestamp
                );
                uint256 userEarnings = (dist.amount * userShare) / 10000;

                if (userEarnings > 0) {
                    earnings += userEarnings;
                    dist.remainingAmount -= userEarnings;
                }
            }
        }

        require(earnings > 0, "No earnings to claim");

        // Update user's claimed amount
        userClaimed[songId][msg.sender] += earnings;

        // Consolidate tokens with new timestamp
        uint256 totalTokens = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            totalTokens += tokens[i].amount;
        }

        delete userTokens[songId][msg.sender];
        tokens.push(
            TokenInfo({amount: totalTokens, timestamp: block.timestamp})
        );

        // Transfer USDC to user
        require(
            usdcToken.transfer(msg.sender, earnings),
            "USDC transfer failed"
        );
        totalEarnings -= earnings;

        emit EarningsClaimed(songId, msg.sender, earnings);
    }

    function _calculateUserShare(
        bytes32 songId,
        address user,
        uint256 distributionTimestamp
    ) internal view returns (uint256) {
        TokenInfo[] storage tokens = userTokens[songId][user];
        uint256 share = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i].timestamp <= distributionTimestamp) {
                share += tokens[i].amount;
            }
        }

        return share;
    }

    function _cleanupEmptyTokens(bytes32 songId, address user) internal {
        TokenInfo[] storage tokens = userTokens[songId][user];
        uint256 validTokens = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i].amount > 0) {
                if (i != validTokens) {
                    tokens[validTokens] = tokens[i];
                }
                validTokens++;
            }
        }

        while (tokens.length > validTokens) {
            tokens.pop();
        }
    }
}
