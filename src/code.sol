// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MusicRoyaltyDistributor {
    struct Distribution {
        uint256 timestamp;
        uint256 amount;
        uint256 remainingAmount;
    }

    struct TokenHolder {
        uint256 amount;
        uint256 timestamp;
        uint256 value;
        uint256 correspondingEarnings;
    }

    struct ClaimInfo {
        uint256 amount;
        uint256 timestamp;
    }

    // Main state variables
    mapping(bytes32 => mapping(address => TokenHolder[])) public songUserTokens;
    mapping(bytes32 => mapping(address => ClaimInfo)) public songUserClaims;
    Distribution[] public distributions;
    uint256 public totalEarnings;

    event TokensTransferred(
        bytes32 songId,
        address from,
        address to,
        uint256 amount
    );
    event EarningsClaimed(bytes32 songId, address user, uint256 amount);
    event DistributionAdded(uint256 timestamp, uint256 amount);

    function addDistribution(uint256 amount) external {
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
        ClaimInfo storage userClaim = songUserClaims[songId][msg.sender];
        TokenHolder[] storage userTokens = songUserTokens[songId][msg.sender];

        uint256 totalClaim = 0;

        // Calculate earnings from each distribution period
        for (uint256 i = 0; i < distributions.length; i++) {
            Distribution storage dist = distributions[i];
            if (dist.timestamp > userClaim.timestamp) {
                uint256 periodEarnings = 0;

                // Calculate earnings for each token holding
                for (uint256 j = 0; j < userTokens.length; j++) {
                    TokenHolder storage token = userTokens[j];
                    if (token.timestamp <= dist.timestamp) {
                        uint256 share = (token.amount * 1e18) / 10000; // Convert to 18 decimals
                        uint256 earning = (share * dist.amount) / 1e18;
                        periodEarnings += earning;
                    }
                }

                dist.remainingAmount -= periodEarnings;
                totalClaim += periodEarnings;
            }
        }

        require(totalClaim > 0, "No earnings to claim");

        // Update claim info
        userClaim.amount += totalClaim;
        userClaim.timestamp = block.timestamp;

        // Consolidate tokens into a single holding
        uint256 totalTokens = 0;
        for (uint256 i = 0; i < userTokens.length; i++) {
            totalTokens += userTokens[i].amount;
        }

        delete songUserTokens[songId][msg.sender];
        songUserTokens[songId][msg.sender].push(
            TokenHolder({
                amount: totalTokens,
                timestamp: block.timestamp,
                value: 0,
                correspondingEarnings: 0
            })
        );

        totalEarnings -= totalClaim;

        // Transfer earnings to user (implementation depends on token type)
        // payable(msg.sender).transfer(totalClaim);

        emit EarningsClaimed(songId, msg.sender, totalClaim);
    }

    function transferTokens(
        bytes32 songId,
        address recipient,
        uint256 amount
    ) external {
        require(recipient != msg.sender, "Cannot send tokens to yourself");
        require(recipient != address(0), "Invalid recipient");

        TokenHolder[] storage senderTokens = songUserTokens[songId][msg.sender];
        uint256 senderTotal = 0;
        for (uint256 i = 0; i < senderTokens.length; i++) {
            senderTotal += senderTokens[i].amount;
        }
        require(senderTotal >= amount, "Insufficient tokens");

        // Create new token holding for recipient
        songUserTokens[songId][recipient].push(
            TokenHolder({
                amount: amount,
                timestamp: block.timestamp,
                value: 0,
                correspondingEarnings: 0
            })
        );

        // Reduce sender's tokens
        senderTokens[0].amount -= amount;

        emit TokensTransferred(songId, msg.sender, recipient, amount);
    }
}
