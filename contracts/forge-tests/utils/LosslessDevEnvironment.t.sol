// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../LosslessAegisCore.sol";
import "../../utils/ERC20.sol";

import "./IEvm.sol";
import "ds-test/test.sol";

contract LosslessDevEnvironment is DSTest {
    Evm public evm = Evm(HEVM_ADDRESS);

    LosslessAegisCore public aegisCore;

    ERC20 public erc20Token;

    address public securityOwner = address(1);
    address public oracle = address(2);
    address public erc20Admin = address(3);

    uint256 public subscriptionFee = 1;

    uint256 public totalSupply = type(uint256).max;

    function setUp() public {
        evm.prank(erc20Admin);
        erc20Token = new ERC20("ERC20 Token", "ERC20", totalSupply);

        setUpaegisCore();
    }

    /// ----- Helpers ------

    /// @notice Discard test where fuzzing address equals owner
    modifier notOwner(address _impersonator) {
        evm.assume(_impersonator != securityOwner);
        _;
    }

    /// @notice Discard test where fuzzing address equals zero address
    modifier notZero(address _address) {
        evm.assume(_address != address(0));
        _;
    }

    /// @notice Sets up Lossless Aegis Core
    function setUpaegisCore() public {
        evm.startPrank(securityOwner);
        aegisCore = new LosslessAegisCore();
        aegisCore.initialize(oracle, subscriptionFee, erc20Token);
        evm.stopPrank();
    }

    /// @notice Generates a subscription
    function generateSubscription(
        address _payer,
        address _sub,
        uint128 _blocks
    ) public returns (uint256) {
        uint256 subAmount = _blocks * subscriptionFee;
        evm.assume(_blocks > 100);
        evm.prank(erc20Admin);
        erc20Token.transfer(_payer, subAmount);

        evm.startPrank(_payer);
        erc20Token.approve(address(aegisCore), subAmount);

        if (_sub == address(0)) {
            evm.expectRevert("LSS: Cannot sub zero address");
        }
        aegisCore.subscribe(_sub, _blocks);

        evm.stopPrank();

        return subAmount;
    }

    /// @notice Generates a subscription
    function extendSubscription(
        address _payer,
        address _sub,
        uint128 _blocks
    ) public returns (uint256) {
        uint256 extendAmount = _blocks * subscriptionFee;
        evm.assume(_blocks > 100);

        evm.prank(erc20Admin);
        erc20Token.transfer(_payer, extendAmount);

        evm.startPrank(_payer);
        erc20Token.approve(address(aegisCore), extendAmount);

        aegisCore.subscribe(_sub, _blocks);

        evm.stopPrank();

        return extendAmount;
    }
}
