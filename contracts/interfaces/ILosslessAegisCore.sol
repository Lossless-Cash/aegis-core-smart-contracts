// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct RiskScores {
    address addr;
    uint8 score;
}

interface ILssAegisCore {
    function setSubscriptionFee(uint256 _sub) external;

    function setSubscriptionToken(IERC20 _token) external;

    function addOracle(address _oracle) external;

    function removeOracle(address _oracle) external;

    function setRiskScores(RiskScores[] calldata newScores) external;

    function withdrawTokens() external returns (uint256);

    function subscribe(address _address, uint256 _blocks) external;

    function getRiskScore(address _address) external returns (uint8);

    event NewAegisCore(ILssAegisCore indexed _aegisCore);
    event NewSubscriptionFee(uint256 indexed _subFee);
    event NewSubscriptionToken(IERC20 indexed _subToken);
    event NewSubscription(address indexed _address, uint256 indexed _blocks);
    event NewSubscriptionExtension(
        address indexed _address,
        uint256 indexed _blocks
    );
    event NewWithdrawal(uint256 indexed _withdrawPool);
    event NewRiskScore(
        address indexed _updatedAddress,
        uint8 indexed _updatedScore
    );
}
