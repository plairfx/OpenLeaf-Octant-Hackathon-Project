// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {DataTypes} from "src/types/DataTypes.sol";
import {Registry} from "src/Registry.sol";
import {TaskManager} from "src/TaskManager.sol";
import {SubmissionManager} from "src/SubmissionManager.sol";

import {USDC} from "test/Mocks/USDC.sol";
import {
    SafeERC20,
    IERC20
} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    ITokenizedStrategy
} from "@octant-v2-core/src/core/interfaces/ITokenizedStrategy.sol";
import {SparkStrategy, IERC4626} from "src/YDS/SparkStrategy.sol";
import {VaultFactory} from "src/VaultFactory.sol";

pragma solidity 0.8.30;

contract RegistryTest is Test {
    Registry public registry;
    ITokenizedStrategy public vault;
    SparkStrategy public immutable Spark_USDC;
    SubmissionManager public SM;
    TaskManager public TM;
    VaultFactory public VF;

    address admin = makeAddr("admin");
    address alice = makeAddr("alice");
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    address public constant USDC_WHALE =
        0x46340b20830761efd32832A74d7169B29FEB9758;

    address immutable SPARK_USDC_VAULT =
        0x28B3a8fb53B741A8Fd78c0fb9A6B2393d896a43d;

    function setUp() external {
        uint256 forkId = vm.createSelectFork(MAINNET_RPC_URL);

        SM = new SubmissionManager();
        TM = new TaskManager();
        VF = new VaultFactory();
        registry = new Registry(address(TM), address(SM), address(VF));

        SM.setRegistry(address(registry));
        TM.setRegistry(address(registry));
    }

    modifier PRAndTaskCreated() {
        vm.startPrank(admin);
        DataTypes.ProjectReg memory PR = DataTypes.ProjectReg(
            "Ethereum Foundation",
            "We are the ethereum Foundation!", // will be IPFS hash on the frontend.
            admin,
            0,
            address(0x0),
            false,
            false
        );

        console.log(address(registry));
        registry.registerAsProject(PR);

        DataTypes.TaskCreation memory TC = DataTypes.TaskCreation(
            1,
            "Ethereum",
            "Create Contract",
            "Create SMC",
            address(0x0),
            0,
            false
        );

        registry.createTask(1, TC);
        _;
    }

    modifier ProjectWithVault() {
        vm.startPrank(USDC_WHALE);
        IERC20(USDC).transfer(admin, 1000e6);
        console.log("balance of", IERC20(USDC).balanceOf(admin));
        vm.startPrank(admin);
        DataTypes.ProjectReg memory PR = DataTypes.ProjectReg(
            "Ethereum Foundation",
            "We are the ethereum Foundation!", // will be IPFS hash on the frontend.
            admin,
            1000e6,
            address(USDC),
            true,
            false
        );

        IERC20(USDC).approve(address(registry), 1000e6);

        registry.registerAsProject(PR);
        address _vault = registry.getVault(1);
        vault = ITokenizedStrategy(_vault);

        _;
    }

    modifier SubmissionCreated() {
        vm.startPrank(admin);
        DataTypes.ProjectReg memory PR = DataTypes.ProjectReg(
            "Ethereum Foundation",
            "We are the ethereum Foundation!", // will be IPFS hash on the frontend.
            admin,
            0,
            address(0x0),
            false,
            false
        );

        registry.registerAsProject(PR);

        DataTypes.TaskCreation memory TC = DataTypes.TaskCreation(
            1,
            "Ethereum",
            "Create Contract",
            "Create SMC",
            address(0x0),
            0,
            false
        );

        registry.createTask(1, TC);

        DataTypes.SubmissionCreation memory SC5 = DataTypes.SubmissionCreation(
            1,
            "Test",
            alice,
            "Test",
            "Test",
            true
        );

        registry.createSubmission(1, SC5);
        _;
    }

    modifier SubmissionCreatedWithTaskPrize() {
        // project..
        vm.startPrank(USDC_WHALE);
        IERC20(USDC).transfer(admin, 1000e6);
        vm.startPrank(admin);
        DataTypes.ProjectReg memory PR = DataTypes.ProjectReg(
            "Ethereum Foundation",
            "We are the ethereum Foundation!", // will be IPFS hash on the frontend.
            admin,
            1000e6,
            address(USDC),
            true,
            false
        );

        IERC20(USDC).approve(address(registry), 1000e6);

        registry.registerAsProject(PR);
        address _vault = registry.getVault(1);
        vault = ITokenizedStrategy(_vault);
        console.log(IERC20(USDC).balanceOf(address(registry)));

        //
        DataTypes.TaskCreation memory TC = DataTypes.TaskCreation(
            1,
            "Ethereum",
            "Create Contract",
            "Create SMC",
            USDC,
            3e6,
            false
        );

        skip(30 days);
        vm.roll(block.number + 30 days);
        // address _vault = registry.getVault(1);
        uint256 USDCBalanceBefore = IERC20(USDC).balanceOf(address(registry));
        uint256 SharebalanceAdminBeforeCreatingTask = vault.balanceOf(
            address(registry)
        );

        // vault = ITokenizedStrategy(_vault);

        vm.startPrank(address(admin));
        registry.createTask(1, TC);
        console.log(IERC20(USDC).balanceOf(address(registry)));
        vm.startPrank(alice);

        DataTypes.SubmissionCreation memory SC5 = DataTypes.SubmissionCreation(
            1,
            "Test",
            alice,
            "Test",
            "Test",
            true
        );

        registry.createSubmission(1, SC5);

        _;
    }

    function test_RegisterAsProject() public {
        DataTypes.ProjectReg memory PR = DataTypes.ProjectReg(
            "Ethereum Foundation",
            "We are the ethereum Foundation!", // will be IPFS hash on the frontend.
            admin,
            0,
            address(0x0),
            false,
            false
        );
        vm.expectEmit(true, true, true, true);
        // @ We dont have a public counter yet,  but it is one.
        emit Registry.ProjectRegistered(
            "Ethereum Foundation",
            "We are the ethereum Foundation!",
            1
        );
        registry.registerAsProject(PR);
    }

    // ============================================================
    // ||                    Tasks                               ||
    // ============================================================

    function test_createTask() public {
        // no project..
        DataTypes.TaskCreation memory TC = DataTypes.TaskCreation(
            1,
            "Ethereum",
            "Create Contract",
            "Create SMC",
            address(0x0),
            0,
            false
        );

        vm.startPrank(admin);
        vm.expectRevert();
        registry.createTask(1, TC);

        // creating project..

        DataTypes.ProjectReg memory PR = DataTypes.ProjectReg(
            "Ethereum Foundation",
            "We are the ethereum Foundation!", // will be IPFS hash on the frontend.
            admin,
            0,
            address(0x0),
            false,
            false
        );

        vm.expectEmit(true, true, true, true);
        // @ We dont have a public counter yet,  but it is one.
        emit Registry.ProjectRegistered(
            "Ethereum Foundation",
            "We are the ethereum Foundation!",
            1
        );
        registry.registerAsProject(PR);
        // vm.expectEmit(true, true, true, true);
        // emit TaskManager.TaskCreated(1, 1);
        // creating task registry.createTask(1, TC);
        registry.createTask(1, TC);
    }

    function test_RemoveTask() public PRAndTaskCreated {
        vm.startPrank(alice);
        vm.expectRevert();
        registry.removeTask(1, 1);

        vm.startPrank(admin);
        // vm.expectEmit(true, true, true, true);
        // emit TaskManager.TaskRemoved(1, 1);
        registry.removeTask(1, 1);
    }

    function test_createTaskWithYieldProiftMroeThanAmount()
        public
        ProjectWithVault
    {
        DataTypes.TaskCreation memory TC = DataTypes.TaskCreation(
            1,
            "Ethereum",
            "Create Contract",
            "Create SMC",
            USDC,
            3e6,
            false
        );

        skip(30 days);
        vm.roll(block.number + 30 days);
        address _vault = registry.getVault(1);
        uint256 USDCBalanceBefore = IERC20(USDC).balanceOf(address(registry));
        // uint256 SharebalanceAdminBeforeCreatingTask = vault.balanceOf(
        //     address(registry)
        // );

        vault = ITokenizedStrategy(_vault);

        uint256 vBProjectStratBeforeReport = IERC4626(SPARK_USDC_VAULT)
            .balanceOf(address(vault));

        vm.startPrank(address(admin));
        registry.createTask(1, TC);

        // uint256 SharebalanceAdminAfterCreatingTask = vault.balanceOf(
        //     address(registry)
        // );

        uint256 vBProjectStratAfterReport = IERC4626(SPARK_USDC_VAULT)
            .balanceOf(address(vault));

        assertGt(IERC20(USDC).balanceOf(address(registry)), USDCBalanceBefore);
        console.log("Test1");
        assertGt(vBProjectStratBeforeReport, vBProjectStratAfterReport);
        console.log("Test1");
    }

    function test_createTaskWithYieldProfitLessThanAmount()
        public
        ProjectWithVault
    {
        vm.startPrank(USDC_WHALE);
        IERC20(USDC).transfer(admin, 10e6);

        DataTypes.TaskCreation memory TC = DataTypes.TaskCreation(
            1,
            "Ethereum",
            "Create Contract",
            "Create SMC",
            USDC,
            3e6,
            false
        );

        skip(15 days);
        vm.roll(block.number + 15 days);
        address _vault = registry.getVault(1);
        uint256 USDCBalanceBefore = IERC20(USDC).balanceOf(address(registry));
        uint256 SharebalanceAdminBeforeCreatingTask = vault.balanceOf(
            address(registry)
        );
        uint256 adminBalanceBeforeCreatingTask = IERC20(USDC).balanceOf(admin);

        vault = ITokenizedStrategy(_vault);

        uint256 vBProjectStratBeforeReport = IERC4626(SPARK_USDC_VAULT)
            .balanceOf(address(vault));

        vm.startPrank(address(admin));

        // @IMPORTANT: make a getter functino for this later.
        IERC20(USDC).approve(address(registry), 1288058);

        registry.createTask(1, TC);
        uint256 adminBalanceAfterCreatingTask = IERC20(USDC).balanceOf(admin);

        uint256 SharebalanceAdminAfterCreatingTask = vault.balanceOf(
            address(registry)
        );

        uint256 vBProjectStratAfterReport = IERC4626(SPARK_USDC_VAULT)
            .balanceOf(address(vault));

        assertGt(IERC20(USDC).balanceOf(address(registry)), USDCBalanceBefore);
        console.log("Test1");
        assertGt(vBProjectStratBeforeReport, vBProjectStratAfterReport);
        console.log("Test1");
        assertGt(
            SharebalanceAdminAfterCreatingTask,
            SharebalanceAdminBeforeCreatingTask
        );
        assertGt(adminBalanceBeforeCreatingTask, adminBalanceAfterCreatingTask);
        console.log("Test1");
    }

    // ============================================================
    // ||                    SUBMISSIONS                         ||
    // ============================================================

    function test_CreateSubmission() public PRAndTaskCreated {
        vm.startPrank(alice);

        DataTypes.SubmissionCreation memory SC = DataTypes.SubmissionCreation(
            0,
            "",
            alice,
            "",
            "",
            true
        );

        vm.expectRevert();

        registry.createSubmission(0, SC);

        DataTypes.SubmissionCreation memory SC2 = DataTypes.SubmissionCreation(
            1,
            "",
            alice,
            "",
            "",
            true
        );

        vm.expectRevert("Submission Name/Description/Link cannot be empty!");

        registry.createSubmission(1, SC2);

        DataTypes.SubmissionCreation memory SC3 = DataTypes.SubmissionCreation(
            1,
            "Test",
            alice,
            "",
            "",
            true
        );

        vm.expectRevert("Submission Name/Description/Link cannot be empty!");

        registry.createSubmission(1, SC3);

        DataTypes.SubmissionCreation memory SC4 = DataTypes.SubmissionCreation(
            1,
            "Test",
            alice,
            "Test",
            "",
            true
        );

        vm.expectRevert("Submission Name/Description/Link cannot be empty!");

        registry.createSubmission(1, SC4);

        DataTypes.SubmissionCreation memory SC5 = DataTypes.SubmissionCreation(
            1,
            "Test",
            alice,
            "Test",
            "Test",
            true
        );

        // vm.expectEmit(true, true, true, true);

        // emit TaskManager.SubmissionCreated(1, 1);
        registry.createSubmission(1, SC5);

        DataTypes.SubmissionCreation memory returnSC = SM.getSubmission(1);

        assertEq(keccak256(abi.encode(returnSC)), keccak256(abi.encode(SC5)));
    }

    function test_acceptSubmission() public SubmissionCreated {
        vm.startPrank(alice);
        vm.expectRevert("Must be admin");
        registry.acceptSubmission(1, 1, 1);

        vm.startPrank(admin);
        // vm.expectEmit(true, true, true, true);
        // emit TM.SubmissionAccepted(1, 1);
        registry.acceptSubmission(1, 1, 1);
    }

    function test_submissionUserReceivesUSDC()
        public
        SubmissionCreatedWithTaskPrize
    {
        uint256 aliceBalanceBefore = IERC20(USDC).balanceOf(alice);
        vm.startPrank(admin);
        console.log(IERC20(USDC).balanceOf(address(registry)));
        registry.acceptSubmission(1, 1, 1);

        assertEq(IERC20(USDC).balanceOf(alice), aliceBalanceBefore + 3e6);
    }

    function test_rejectSubmission() public SubmissionCreated {
        vm.startPrank(alice);
        vm.expectRevert();
        registry.rejectSubmission(1, 1, 1);

        vm.startPrank(admin);
        // vm.expectEmit(true, true, true, true);
        // emit TM.SubmissionDenied(1, 1);
        registry.rejectSubmission(1, 1, 1);
    }

    // ============================================================
    // ||                    ADMIN FUNCTIONS                     ||
    // ============================================================

    function test_adminChangeTaskPayRate() public SubmissionCreated {
        DataTypes.TaskCreation memory beforeChange = TM.getTask(1);

        assertEq(beforeChange.amount, 0);

        vm.startPrank(admin);
        registry.changeTaskPayRate(1, 1, 1e6);
        DataTypes.TaskCreation memory afterChange = TM.getTask(1);
        assertEq(afterChange.amount, 1e6);
    }

    function test_WithdrawYield() public ProjectWithVault {
        skip(15 days);
        vm.roll(block.number + 15 days);
        uint256 adminBalanceBefore = IERC20(USDC).balanceOf(admin);

        vm.startPrank(admin);

        registry.withdrawYield(1);

        uint256 adminBalanceAfter = IERC20(USDC).balanceOf(admin);

        assertGt(adminBalanceAfter, adminBalanceBefore);
    }
}
