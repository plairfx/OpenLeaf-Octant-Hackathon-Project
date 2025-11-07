// SPDX-License-Identifier: MIT

import {Test} from "forge-std/Test.sol";
import {DataTypes} from "src/types/DataTypes.sol";
import {Registry, TaskManager} from "src/Registry.sol";
import {USDC} from "test/Mocks/USDC.sol";

pragma solidity 0.8.30;

contract RegistryTest is Test {
    Registry public registry;
    USDC public usdc;

    address admin = makeAddr("admin");
    address alice = makeAddr("alice");

    function setUp() external {
        registry = new Registry();
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
        vm.expectEmit(true, true, true, true);
        emit TaskManager.TaskCreated(1, 1);
        // creating task registry.createTask(1, TC);
        registry.createTask(1, TC);
    }

    function test_RemoveTask() public PRAndTaskCreated {
        vm.startPrank(alice);
        vm.expectRevert();
        registry.removeTask(1, 1);

        vm.startPrank(admin);
        vm.expectEmit(true, true, true, true);
        emit TaskManager.TaskRemoved(1, 1);
        registry.removeTask(1, 1);
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

        vm.expectEmit(true, true, true, true);

        emit TaskManager.SubmissionCreated(1, 1);
        registry.createSubmission(1, SC5);

        DataTypes.SubmissionCreation memory returnSC = registry.getSubmission(
            1
        );

        assertEq(keccak256(abi.encode(returnSC)), keccak256(abi.encode(SC5)));
    }

    function test_acceptSubmission() public SubmissionCreated {
        vm.startPrank(alice);
        vm.expectRevert("Must be admin");
        registry.acceptSubmission(1, 1, 1);

        vm.startPrank(admin);
        vm.expectEmit(true, true, true, true);
        emit TaskManager.SubmissionAccepted(1, 1);
        registry.acceptSubmission(1, 1, 1);
    }

    function test_rejectSubmission() public SubmissionCreated {
        vm.startPrank(alice);
        vm.expectRevert();
        registry.rejectSubmission(1, 1, 1);

        vm.startPrank(admin);
        vm.expectEmit(true, true, true, true);
        emit TaskManager.SubmissionDenied(1, 1);
        registry.rejectSubmission(1, 1, 1);
    }

    // ============================================================
    // ||                    ADMIN FUNCTIONS                     ||
    // ============================================================

    function test_adminChangeTaskPayRate() public SubmissionCreated {
        DataTypes.TaskCreation memory beforeChange = registry.getTask(1);

        assertEq(beforeChange.amount, 0);

        vm.startPrank(admin);

        registry.changeTaskPayRate(1, 1, 1e6);

        DataTypes.TaskCreation memory afterChange = registry.getTask(1);

        assertEq(afterChange.amount, 1e6);
    }
}
