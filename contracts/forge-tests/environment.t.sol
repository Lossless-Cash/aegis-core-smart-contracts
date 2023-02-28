// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./utils/LosslessDevEnvironment.t.sol";

contract EnvironmentTests is LosslessDevEnvironment {
    /// @notice Test deployed Random ERC20 Token
    function testERC20TokenDeploy() public {
        assertEq(erc20Token.totalSupply(), totalSupply);
        assertEq(erc20Token.name(), "ERC20 Token");
        assertEq(erc20Token.symbol(), "ERC20");
        assertEq(erc20Token.owner(), erc20Admin);
    }

    /// @notice Test deployed AegisCore
    function testAegisCoreSetUp() public {
        assertEq(securityOwner, aegisCore.owner());
        assertEq(aegisCore.subFee(), subscriptionFee);
        assertEq(address(aegisCore.subToken()), address(erc20Token));
    }
}
