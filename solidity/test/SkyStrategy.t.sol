// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {DataTypes} from "src/types/DataTypes.sol";
import {Registry, TaskManager} from "src/Registry.sol";
import {SparkStrategy, IERC4626} from "src/YDS/SparkStrategy.sol";
import {USDC} from "test/Mocks/USDC.sol";
import {
    ITokenizedStrategy
} from "@octant-v2-core/src/core/interfaces/ITokenizedStrategy.sol";
import {
    YieldDonatingTokenizedStrategy
} from "@octant-v2-core/src/strategies/yieldDonating/YieldDonatingTokenizedStrategy.sol";
import {
    SafeERC20,
    IERC20
} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity 0.8.30;

contract SkyStrategy is Test {
    SparkStrategy public strategy;
    ITokenizedStrategy public vault;
    YieldDonatingTokenizedStrategy public implementation;

    address public management;
    address public keeper;
    address public emergencyAdmin;
    address public donationAddress;
    address public user = address(0x1234);
    string MAINNET_RPC_URL =
        "https://mainnet.infura.io/v3/6290668924f04f289deefdc0c3af5c15";
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address sUSDC = 0x28B3a8fb53B741A8Fd78c0fb9A6B2393d896a43d;
    address public constant USDC_WHALE =
        0x46340b20830761efd32832A74d7169B29FEB9758;

    function setUp() public {
        uint256 forkId = vm.createSelectFork(MAINNET_RPC_URL);
        // Deploy implementation
        implementation = new YieldDonatingTokenizedStrategy{
            salt: keccak256("SPARK_YIELD_DONATING_V1")
        }();

        // Set up addresses
        management = address(0x1);
        keeper = address(0x2);
        emergencyAdmin = address(0x3);
        donationAddress = address(0x4);

        console.log("HELLO");

        vm.startPrank(management);
        strategy = new SparkStrategy(
            USDC,
            "Spark sUSDC Yield Donating Vault",
            management,
            keeper,
            emergencyAdmin,
            donationAddress,
            false,
            address(implementation),
            sUSDC
        );
        vm.stopPrank();

        console.log(address(strategy), address(vault));

        vault = ITokenizedStrategy(address(strategy));

        vm.label(address(strategy), "SparkStrategy");
        vm.label(USDC, "USDC");
        vm.label(sUSDC, "Spark sUSDC");
        vm.label(management, "Management");
        vm.label(keeper, "Keeper");
        vm.label(user, "Test User");
        vm.label(USDC_WHALE, "USDC Whale");

        // Get USDC from whale
        vm.prank(USDC_WHALE);
        IERC20(USDC).transfer(user, 100e6);

        // User approves strategy
        vm.startPrank(user);
        IERC20(USDC).approve(address(strategy), type(uint256).max);
        vm.stopPrank();
    }

    function test_initWorks() public {
        assertEq(vault.asset(), USDC);
        assertEq(IERC20(USDC).balanceOf(user), 100e6);
    }

    function test_depositWorks() public {
        uint256 depositAmount = 100e6;

        uint256 initialUserBalance = IERC20(USDC).balanceOf(user);

        // Deposit
        vm.startPrank(user);
        uint256 sharesReceived = vault.deposit(depositAmount, user);
        vm.stopPrank();

        // Verify balances
        assertEq(
            IERC20(USDC).balanceOf(user),
            initialUserBalance - depositAmount,
            "User balance not reduced"
        );
        assertGt(
            IERC4626(sUSDC).balanceOf(address(strategy)),
            0,
            "Nothing staked in Spark"
        );
        assertGt(sharesReceived, 0, "No shares received");

        console.log("Deposited:", depositAmount);
        console.log("Shares received:", sharesReceived);
        console.log("Staked in Spark:", vault.balanceOf(address(strategy)));
    }

    function test_withdrawWorks() public {
        uint256 depositAmount = 100e6;
        uint256 initialUserBalance = IERC20(USDC).balanceOf(user);
        uint256 shareBalanceBefore = IERC4626(sUSDC).balanceOf(
            address(strategy)
        );

        // Deposit
        vm.startPrank(user);
        uint256 sharesReceived = vault.deposit(depositAmount, user);
        vm.stopPrank();

        assertEq(
            IERC20(USDC).balanceOf(user),
            initialUserBalance - depositAmount
        );
        assertGt(
            IERC4626(sUSDC).balanceOf(address(strategy)),
            shareBalanceBefore
        );
    }

    function test_reportWorks() public {
        uint256 depositAmount = 90e6;
        uint256 donationWalletBalance = vault.balanceOf(donationAddress);
        uint256 initialUserBalance = IERC20(USDC).balanceOf(user);
        console.log(initialUserBalance);
        uint256 shareBalanceBefore = IERC4626(sUSDC).balanceOf(
            address(strategy)
        );

        // Deposit
        vm.startPrank(user);
        uint256 sharesReceived = vault.deposit(depositAmount, user);
        uint256 sharesReceived2 = vault.deposit(10e6, user);
        vm.stopPrank();

        skip(30 days);
        vm.roll(block.number + 30 days);

        vm.startPrank(keeper);
        (uint256 profit, uint256 loss) = vault.report();

        console.log(profit, loss);

        assertGt(vault.balanceOf(donationAddress), donationWalletBalance);
        console.log(vault.balanceOf(donationAddress));
    }

    // we will test in a second if the profit is righ tor not.
}
