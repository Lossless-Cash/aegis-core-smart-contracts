// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./utils/LosslessDevEnvironment.t.sol";
import "../interfaces/ILosslessAegisCore.sol";

contract LosslessaegisCoreTests is LosslessDevEnvironment {
    mapping(address => uint8) public riskScores;

    modifier zeroFee() {
        evm.prank(securityOwner);
        subscriptionFee = 0;
        aegisCore.setSubscriptionFee(subscriptionFee);
        _;
    }

    /// @notice Generate risk scores and sub
    function setUpStartingPoint(
        address _payer,
        address _sub,
        uint128 _blocks,
        RiskScores[] calldata newScores,
        bool _subbed
    ) public {
        // Set risk scores
        evm.assume(_blocks > 100);
        evm.startPrank(oracle);
        aegisCore.setRiskScores(newScores);
        evm.stopPrank();

        if (_subbed) {
            generateSubscription(_payer, _sub, _blocks);
        }
    }

    /// @notice Test getting risk scores with subscription
    /// @notice should not revert
    function testaegisCoreGetRiskSubActive(
        address _payer,
        address _sub,
        uint128 _blocks,
        RiskScores[] calldata newScores,
        uint256 _getScore
    ) public notZero(_payer) notZero(_sub) {
        evm.assume(newScores.length > 0);
        evm.assume(_blocks > 100);
        evm.assume(_blocks < type(uint128).max - 100);

        setUpStartingPoint(_payer, _sub, _blocks, newScores, true);

        for (uint256 i; i < newScores.length; i++) {
            riskScores[newScores[i].addr] = newScores[i].score;
        }

        evm.roll(5);
        evm.startPrank(_sub);

        for (uint256 i; i < newScores.length; i++) {
            address addressToCheck = newScores[i].addr;
            uint8 riskScore = aegisCore.getRiskScore(addressToCheck);

            assertEq(riskScore, riskScores[addressToCheck]);
        }
        evm.stopPrank();
    }

    /// @notice Test getting risk scores subscription expired
    /// @notice should not revert but return 0
    function testaegisCoreGetRiskSubExpired(
        address _payer,
        address _sub,
        uint128 _blocks,
        RiskScores[] calldata newScores,
        uint256 _getScore
    ) public notZero(_payer) notZero(_sub) {
        evm.assume(_blocks > 100);
        evm.assume(_blocks < type(uint128).max - 100);

        setUpStartingPoint(_payer, _sub, _blocks, newScores, true);

        evm.roll(_blocks + 1);
        evm.startPrank(_sub);

        for (uint256 i; i < newScores.length; i++) {
            uint8 riskScore = aegisCore.getRiskScore(newScores[i].addr);
        }
        evm.stopPrank();
    }

    /// @notice Test adding oracle
    /// @notice should not revert
    function testaegisCoreAddOracle(address _newOracle) public {
        evm.assume(_newOracle != oracle);
        evm.prank(securityOwner);
        aegisCore.addOracle(_newOracle);
    }

    /// @notice Test adding oracle same address
    /// @notice should revert
    function testaegisCoreAddOracleSameAddress() public {
        evm.prank(securityOwner);
        evm.expectRevert("LSS: Cannot set same address");
        aegisCore.addOracle(oracle);
    }

    /// @notice Test removing oracle
    /// @notice should not revert
    function testaegisCoreRemoveOracle() public {
        evm.prank(securityOwner);
        aegisCore.removeOracle(oracle);
    }

    /// @notice Test removing non existing
    /// @notice should revert
    function testaegisCoreRemoveOracleNonExisting(address _newOracle) public {
        evm.assume(_newOracle != oracle);
        evm.prank(securityOwner);
        evm.expectRevert("LSS: Not Oracle");
        aegisCore.removeOracle(_newOracle);
    }

    /// @notice Test adding oracle by non owner
    /// @notice should revert
    function testaegisCoreAddOracleNonOwner(
        address _impersonator,
        address _newOracle
    ) public notOwner(_impersonator) {
        evm.assume(_newOracle != oracle);
        evm.prank(_impersonator);
        evm.expectRevert("Ownable: caller is not the owner");
        aegisCore.addOracle(_newOracle);
    }

    /// @notice Test removing oracle by non owner
    /// @notice should revert
    function testaegisCoreRemoveOracleNonOwner(address _impersonator)
        public
        notOwner(_impersonator)
    {
        evm.prank(_impersonator);
        evm.expectRevert("Ownable: caller is not the owner");
        aegisCore.removeOracle(oracle);
    }

    /// @notice Test getting risk scores without subscription
    /// @notice should revert
    function testaegisCoreGetRiskSubNone(
        address _payer,
        address _sub,
        uint128 _blocks,
        RiskScores[] calldata newScores,
        uint256 _getScore
    ) public notZero(_payer) notZero(_sub) {
        evm.assume(_blocks > 100);
        evm.assume(_blocks < type(uint128).max - 100);

        setUpStartingPoint(_payer, _sub, _blocks, newScores, false);

        evm.roll(5);
        evm.startPrank(_sub);

        for (uint256 i; i < newScores.length; i++) {
            evm.expectRevert("LSS: Must be subscribed");
            uint8 riskScore = aegisCore.getRiskScore(newScores[i].addr);

            assertEq(riskScore, 0);
        }
        evm.stopPrank();
    }

    /// @notice Test Subscription Fee Set up
    /// @dev Should not revert
    function testaegisCorerSetSubscriptionFee(uint256 _newFee) public {
        evm.startPrank(securityOwner);
        aegisCore.setSubscriptionFee(_newFee);
        assertEq(aegisCore.subFee(), _newFee);
        evm.stopPrank();
    }

    /// @notice Test Subscription Fee Set up by non owner
    /// @dev Should revert
    function testaegisCorerSetSubscriptionFeeNonOwner(
        uint256 _newFee,
        address _impersonator
    ) public notOwner(_impersonator) {
        evm.prank(_impersonator);
        evm.expectRevert("Ownable: caller is not the owner");
        aegisCore.setSubscriptionFee(_newFee);
    }

    /// @notice Test Subscription Token Set up
    /// @dev Should not revert
    function testaegisCorerSetSubscriptionToken(address _newToken) public {
        evm.startPrank(securityOwner);
        aegisCore.setSubscriptionToken(IERC20(_newToken));
        assertEq(address(aegisCore.subToken()), _newToken);
        evm.stopPrank();
    }

    /// @notice Test Subscription Token Set up by non owner
    /// @dev Should revert
    function testaegisCorerSetSubscriptionTokenNonOwner(
        address _newToken,
        address _impersonator
    ) public notOwner(_impersonator) {
        evm.prank(_impersonator);
        evm.expectRevert("Ownable: caller is not the owner");
        aegisCore.setSubscriptionToken(IERC20(_newToken));
    }

    /// @notice Test subscription
    /// @dev Should not revert
    function testaegisCorerSubscription(
        address _payer,
        address _sub,
        uint128 _blocks
    ) public notZero(_payer) notZero(_sub) {
        evm.assume(_blocks > 100);
        generateSubscription(_payer, _sub, _blocks);
    }

    /// @notice Test set risk scores
    /// @dev Should not revert
    function testaegisCorerSetRiskScores(RiskScores[] calldata newScores)
        public
        zeroFee
    {
        evm.startPrank(oracle);
        aegisCore.setRiskScores(newScores);

        evm.stopPrank();
    }

    /// @notice Test set risk scores non oracle
    /// @dev Should revert
    function testaegisCorerSetRiskScoresNonOracle(
        RiskScores[] calldata newScores
    ) public {
        evm.startPrank(address(9999));
        evm.expectRevert("LSS: Must be subscribed or Oracle");
        aegisCore.setRiskScores(newScores);
        evm.stopPrank();
    }

    /// @notice Test withdraw one full cycle
    /// @dev Should not revert
    function testaegisCorerWithdraw(
        address _payer,
        address _sub,
        uint128 _blocks
    ) public notZero(_payer) notZero(_sub) notOwner(_payer) {
        evm.assume(_blocks > 100);
        evm.assume(_blocks < type(uint128).max - 100);
        uint256 subAmount = generateSubscription(_payer, _sub, _blocks);

        evm.roll(_blocks + 10);

        evm.prank(securityOwner);
        uint256 withdrawed = aegisCore.withdrawTokens();

        assertEq(erc20Token.balanceOf(securityOwner), subAmount);
        assertEq(withdrawed, subAmount);
    }

    /// @notice Test withdraw middle of a cycle
    /// @dev Should not revert
    function testaegisCorerWithdrawMidCycle(
        address _payer,
        address _sub,
        uint128 _blocks
    ) public notZero(_payer) notZero(_sub) notOwner(_payer) {
        evm.assume(_blocks > 100);
        evm.assume(_blocks < type(uint128).max - 100);
        uint256 subAmount = generateSubscription(_payer, _sub, _blocks);

        evm.roll(_blocks / 2);

        evm.prank(securityOwner);
        uint256 withdrawed = aegisCore.withdrawTokens();

        assertEq(erc20Token.balanceOf(securityOwner), subAmount);
        assertEq(withdrawed, subAmount);
    }

    /// @notice Test subscription extension
    /// @dev Should not revert
    function testaegisCoreExtendSub(
        address _payer,
        address _sub,
        uint128 _blocks,
        uint128 _extension
    ) public notZero(_payer) notZero(_sub) notOwner(_payer) {
        evm.assume(_blocks > 100);
        evm.assume(_blocks < type(uint128).max - 100);
        evm.assume(_extension > 100);
        evm.assume(_extension < type(uint128).max - 100);
        uint256 subAmount = generateSubscription(_payer, _sub, _blocks);

        evm.roll(_blocks + 1);

        extendSubscription(_payer, _sub, _extension);
    }

    /// @notice Test subscription extension by anyone
    /// @dev Should not revert
    function testaegisCoreExtendSubByAnyone(
        address _payer,
        address _sub,
        uint128 _blocks,
        uint128 _extension,
        address _extender
    ) public notZero(_extender) notZero(_payer) notZero(_sub) notOwner(_payer) {
        evm.assume(_extender != _payer);
        evm.assume(_blocks > 100);
        evm.assume(_blocks < type(uint128).max - 100);
        evm.assume(_extension > 100);
        evm.assume(_extension < type(uint128).max - 100);
        uint256 subAmount = generateSubscription(_payer, _sub, _blocks);

        evm.roll(_blocks + 1);

        extendSubscription(_extender, _sub, _extension);
    }

    /// @notice Test subscription extension multiple times
    /// @dev Should not revert
    function testaegisCoreExtendSubMultiple(
        address _payer,
        address _sub,
        uint128 _blocks,
        uint128 _extension
    ) public notZero(_payer) notZero(_sub) notOwner(_payer) {
        evm.assume(_blocks > 100);
        evm.assume(_blocks < type(uint128).max / 2 - 100);
        evm.assume(_extension > 100);
        evm.assume(_extension < type(uint128).max / 2 - 100);
        uint256 subAmount = generateSubscription(_payer, _sub, _blocks);

        evm.roll(_blocks + 1);

        extendSubscription(_payer, _sub, _extension);

        evm.roll(_blocks + _extension + 100);
        extendSubscription(_payer, _sub, _extension);
    }

    /// @notice Test withdraw before and after extension
    /// @dev Should not revert
    function testaegisCoreExtendSubWithdrawing(
        address _payer,
        address _sub,
        uint128 _blocks,
        uint128 _extension
    ) public notZero(_payer) notZero(_sub) notOwner(_payer) {
        evm.assume(_blocks > 100);
        evm.assume(_blocks < type(uint128).max - 100);
        evm.assume(_extension > 100);
        evm.assume(_extension < type(uint128).max - 100);

        uint256 subAmount = generateSubscription(_payer, _sub, _blocks);

        evm.prank(securityOwner);
        uint256 withdrawed = aegisCore.withdrawTokens();

        assertEq(erc20Token.balanceOf(securityOwner), subAmount);
        assertEq(withdrawed, subAmount);

        evm.roll(_blocks + 1);

        uint256 extendAmount = generateSubscription(_payer, _sub, _extension);

        evm.prank(securityOwner);
        uint256 withdrawedExt = aegisCore.withdrawTokens();

        assertEq(erc20Token.balanceOf(securityOwner), subAmount + extendAmount);
        assertEq(withdrawedExt, extendAmount);
    }

    /// @notice Test withdraw before and after extension with fee change
    /// @dev Should not revert
    function testaegisCoreExtendSubWithdrawing(
        address _payer,
        address _sub,
        uint128 _blocks,
        uint128 _extension,
        uint128 _newFee
    ) public notZero(_payer) notZero(_sub) notOwner(_payer) {
        evm.assume(_blocks > 100);
        evm.assume(_blocks < type(uint128).max - 100);
        evm.assume(_extension > 100);
        evm.assume(_extension < type(uint128).max - 100);
        evm.assume(_newFee != subscriptionFee);
        evm.assume(_newFee > 0);

        uint256 subAmount = generateSubscription(_payer, _sub, _blocks);

        evm.prank(securityOwner);
        uint256 withdrawed = aegisCore.withdrawTokens();

        assertEq(erc20Token.balanceOf(securityOwner), subAmount);
        assertEq(withdrawed, subAmount);

        subscriptionFee = _newFee;
        evm.prank(securityOwner);
        aegisCore.setSubscriptionFee(subscriptionFee);

        evm.roll(_blocks + 1);

        uint256 extendAmount = extendSubscription(_payer, _sub, _extension);

        evm.prank(securityOwner);
        uint256 withdrawedExt = aegisCore.withdrawTokens();

        assertEq(erc20Token.balanceOf(securityOwner), subAmount + extendAmount);
        assertEq(withdrawedExt, extendAmount);
    }

    /// @notice Test subscription with zero fee
    /// @dev Should not revert
    function testaegisCorerSubscriptionZeroFee(
        address _payer,
        address _sub,
        uint128 _blocks
    ) public notZero(_payer) notZero(_sub) zeroFee {
        evm.assume(_blocks > 100);
        generateSubscription(_payer, _sub, _blocks);
    }

    /// @notice Test subscription extension with zero fee
    /// @dev Should not revert
    function testaegisCoreExtendSubZeroFee(
        address _payer,
        address _sub,
        uint128 _blocks,
        uint128 _extension
    ) public notZero(_payer) notZero(_sub) notOwner(_payer) zeroFee {
        evm.assume(_blocks > 100);
        evm.assume(_blocks < type(uint128).max - 100);
        evm.assume(_extension > 100);
        evm.assume(_extension < type(uint128).max - 100);
        generateSubscription(_payer, _sub, _blocks);

        evm.roll(_blocks + 1);

        extendSubscription(_payer, _sub, _extension);
    }

    /// @notice Test subscription extension by anyone with zero fee
    /// @dev Should not revert
    function testaegisCoreExtendSubByAnyoneZeroFee(
        address _payer,
        address _sub,
        uint128 _blocks,
        uint128 _extension,
        address _extender
    )
        public
        notZero(_extender)
        notZero(_payer)
        notZero(_sub)
        notOwner(_payer)
        zeroFee
    {
        evm.assume(_extender != _payer);
        evm.assume(_blocks > 100);
        evm.assume(_blocks < type(uint128).max / 2 - 100);
        evm.assume(_extension > 100);
        evm.assume(_extension < type(uint128).max / 2 - 100);
        generateSubscription(_payer, _sub, _blocks);

        evm.roll(_blocks + 1);

        extendSubscription(_extender, _sub, _extension);
    }

    /// @notice Test subscription extension multiple times with zero fee
    /// @dev Should not revert
    function testaegisCoreExtendSubMultipleZeroFee(
        address _payer,
        address _sub,
        uint128 _blocks,
        uint128 _extension
    ) public notZero(_payer) notZero(_sub) notOwner(_payer) zeroFee {
        evm.assume(_blocks > 100);
        evm.assume(_blocks < type(uint128).max / 2 - 100);
        evm.assume(_extension > 100);
        evm.assume(_extension < type(uint128).max / 2 - 100);
        generateSubscription(_payer, _sub, _blocks);

        evm.roll(_blocks + 1);

        extendSubscription(_payer, _sub, _extension);

        evm.roll(_blocks + _extension + 100);
        extendSubscription(_payer, _sub, _extension);
    }
}
