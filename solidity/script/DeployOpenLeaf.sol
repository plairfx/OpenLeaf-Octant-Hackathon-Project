 // // SPDX-License-Identifier: MIT

// import {Script} from "forge-std/Script.sol";
// import {Test, console} from "forge-std/Test.sol";
// import {DataTypes} from "src/types/DataTypes.sol";
// import {Registry, TaskManager} from "src/Registry.sol";
// import {USDC} from "test/Mocks/USDC.sol";
// import {
//     SafeERC20,
//     IERC20
// } from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
// import {
//     ITokenizedStrategy
// } from "@octant-v2-core/src/core/interfaces/ITokenizedStrategy.sol";
// import {SparkStrategy, IERC4626} from "src/YDS/SparkStrategy.sol";

// pragma solidity 0.8.30;

// contract DeployOpenLeaf is Script {
//     Registry public registry;
//     ITokenizedStrategy public vault;
//     SparkStrategy public immutable Spark_USDC;
//     // USDC public usdc;
//     address admin = makeAddr("admin");
//     address alice = makeAddr("alice");
//     address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
//     string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
//     address public constant USDC_WHALE =
//         0x46340b20830761efd32832A74d7169B29FEB9758;
//     address immutable SPARK_USDC_VAULT =
//         0x28B3a8fb53B741A8Fd78c0fb9A6B2393d896a43d;

//     address mock_address = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

//     function run() external {
//         vm.startBroadcast();
//         registry = new Registry();
//         console.log(address(registry));
//         vm.stopBroadcast();

//         vm.startPrank(USDC_WHALE);
//         IERC20(USDC).transfer(mock_address, 100e6);
//         vm.stopPrank();

//         console.log(IERC20(USDC).balanceOf(mock_address));
//     }
// }
