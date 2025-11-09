// SPDX-License-Identifier: MIT

import {DataTypes} from "src/types/DataTypes.sol";
import {SparkStrategy, IERC4626} from "src/YDS/SparkStrategy.sol";
import {ISubmissionManager} from "src/interfaces/ISubmissionManager.sol";
import {ITaskManager} from "src/interfaces/ITaskManager.sol";
import {
    SafeERC20,
    IERC20
} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    YieldDonatingTokenizedStrategy
} from "@octant-v2-core/src/strategies/yieldDonating/YieldDonatingTokenizedStrategy.sol";
import {
    ITokenizedStrategy
} from "@octant-v2-core/src/core/interfaces/ITokenizedStrategy.sol";

pragma solidity 0.8.30;

contract VaultFactory {
    SparkStrategy public strategy;
    YieldDonatingTokenizedStrategy public implementation;
    ITokenizedStrategy public vault;

    address immutable USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address immutable SPARK_USDC_VAULT =
        0x28B3a8fb53B741A8Fd78c0fb9A6B2393d896a43d;

    function createVault(
        DataTypes.ProjectReg memory RG
    ) external returns (address, address) {
        implementation = new YieldDonatingTokenizedStrategy();
        strategy = new SparkStrategy(
            USDC,
            string.concat(RG.Name, "Vault"),
            msg.sender,
            msg.sender,
            RG.adminAccount,
            msg.sender,
            false,
            address(implementation),
            SPARK_USDC_VAULT
        );

        return (address(implementation), address(strategy));
    }
}
