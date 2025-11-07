// SPDX-License-Identifier: MIT

import {
    BaseHealthCheck
} from "@octant-v2-core/src/strategies/periphery/BaseHealthCheck.sol";
import {
    SafeERC20,
    IERC20
} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "src/interfaces/IERC4626.sol";

pragma solidity 0.8.30;

contract SparkStrategy is BaseHealthCheck {
    event Test(address, address);
    using SafeERC20 for IERC20;

    IERC20 public immutable USDC;
    IERC4626 public immutable Spark_USDC;

    constructor(
        address _asset,
        string memory _name,
        address _management,
        address _keeper,
        address _emergencyAdmin,
        address _donationAddress,
        bool _enableBurning,
        address _tokenizedStrategyAddress,
        address _SparkUSDCVault
    )
        BaseHealthCheck(
            _asset,
            _name,
            _management,
            _keeper,
            _emergencyAdmin,
            _donationAddress,
            _enableBurning,
            _tokenizedStrategyAddress
        )
    {
        Spark_USDC = IERC4626(_SparkUSDCVault);
        USDC = IERC20(_asset);
        // Approve Spark vault to spend USDC
        IERC20(_asset).approve(_SparkUSDCVault, type(uint256).max);
    }

    function _deployFunds(uint256 amount) internal override {
        if (amount == 0) return;
        Spark_USDC.deposit(amount, address(this));
    }

    function _harvestAndReport()
        internal
        override
        returns (uint256 _totalAssets)
    {
        _totalAssets = idleUSDCBalance() + balanceOfAssets();
    }

    function _freeFunds(uint256 amount) internal override {
        Spark_USDC.withdraw(amount, address(this), address(this));
    }

    function balanceOfShares() public view returns (uint256) {
        return Spark_USDC.balanceOf(address(this));
    }

    function balanceOfAssets() public view returns (uint256) {
        uint256 shares = balanceOfShares();
        return Spark_USDC.convertToAssets(shares);
    }

    function idleUSDCBalance() public view returns (uint256) {
        return USDC.balanceOf(address(this));
    }
}
