// SPDX-License-Identifier: MIT

import {TaskManager} from "src/TaskManager.sol";
import {DataTypes} from "src/types/DataTypes.sol";
import {SparkStrategy, IERC4626} from "src/YDS/SparkStrategy.sol";
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

contract Registry is TaskManager {
    using SafeERC20 for IERC20;

    event Test(uint256, uint256);
    IERC4626 public immutable Spark_USDC;
    SparkStrategy public strategy;
    YieldDonatingTokenizedStrategy public implementation;
    ITokenizedStrategy public vault;

    uint64 projectID;
    bytes32 empty = keccak256(abi.encode(""));
    address immutable SPARK_USDC_VAULT =
        0x28B3a8fb53B741A8Fd78c0fb9A6B2393d896a43d;

    event ProjectRegistered(
        string projectName,
        string projectDescription,
        uint64 projectId
    );

    event VaultCreated(address vault);

    mapping(uint64 projectid => DataTypes.ProjectReg) ProjectRegi;
    mapping(uint64 projectId => address vault) ProjectVault;

    function registerAsProject(DataTypes.ProjectReg memory RG) external {
        if (RG.vault) {
            require(RG.token == USDC);
            implementation = new YieldDonatingTokenizedStrategy();
            strategy = new SparkStrategy(
                USDC,
                string.concat(RG.Name, "Vault"),
                address(this),
                address(this),
                RG.adminAccount,
                address(this),
                false,
                address(implementation),
                SPARK_USDC_VAULT
            );

            emit VaultCreated(address(strategy));

            if (RG.depositAmount > 0) {
                IERC20(USDC).safeTransferFrom(
                    msg.sender,
                    address(this),
                    RG.depositAmount
                );
                vault = ITokenizedStrategy(address(strategy));

                IERC20(USDC).approve(address(vault), RG.depositAmount);

                vault.deposit(RG.depositAmount, RG.adminAccount);
            }
        }
        projectID++;
        RG.registered = true;
        ProjectRegi[projectID] = RG;
        ProjectVault[projectID] = address(vault);

        emit ProjectRegistered(RG.Name, RG.Description, projectID);
    }

    function createTask(
        uint64 _projectID,
        DataTypes.TaskCreation memory TC
    ) external {
        _adminCheck(_projectID);

        DataTypes.ProjectReg memory RG = ProjectRegi[_projectID];

        require(
            keccak256(abi.encode(TC.TaskDescription)) != empty &&
                keccak256(abi.encode(TC.TaskName)) != empty
        );

        if (RG.vault && ProjectVault[_projectID] != address(0x0)) {
            vault = ITokenizedStrategy(ProjectVault[_projectID]);

            (uint256 profit, ) = vault.report();

            if (profit > 0) {
                if (profit >= TC.amount) {
                    uint256 _amount = vault.convertToShares(profit);

                    vault.withdraw(_amount, address(this), address(this), 0);

                    // 3.4 USDC - 3 USDC = 0.4 USDC
                    IERC20(USDC).safeTransfer(
                        RG.adminAccount,
                        profit - TC.amount // 0.4 USDC
                    );
                } else {
                    emit Test(TC.amount, profit);
                    TC.amount = TC.amount - profit;
                    emit Test(IERC20(USDC).balanceOf(msg.sender), TC.amount);
                    uint256 _amount = vault.convertToShares(TC.amount);
                    vault.withdraw(_amount, address(this), address(this), 0);

                    IERC20(USDC).safeTransferFrom(
                        msg.sender,
                        address(this),
                        TC.amount
                    );
                }
            }
        } else if (TC.amount > 0) {
            IERC20(USDC).safeTransferFrom(msg.sender, address(this), TC.amount);
        }
        _createTask(_projectID, TC);
    }

    function removeTask(uint64 _projectID, uint64 _taskID) external {
        _adminCheck(_projectID);
        _removeTask(_projectID, _taskID);
    }

    function createSubmission(
        uint64 _projectID,
        DataTypes.SubmissionCreation memory SC
    ) external {
        DataTypes.TaskCreation memory TC = TaskRegistry[SC.TaskID];

        require(TC.ProjectId == _projectID);
        require(
            keccak256(abi.encode(SC.SubmissionDescription)) != empty &&
                keccak256(abi.encode(SC.SubmissionName)) != empty &&
                keccak256(abi.encode(SC.SubmissionLink)) != empty,
            "Submission Name/Description/Link cannot be empty!"
        );
        _createSubmission(SC.TaskID, SC);
    }

    function acceptSubmission(
        uint64 _projectID,
        uint64 _taskID,
        uint64 _submissionID
    ) external {
        DataTypes.ProjectReg memory PR = ProjectRegi[_projectID];
        DataTypes.TaskCreation memory TC = TaskRegistry[_taskID];
        require(PR.adminAccount == msg.sender, "Must be admin");

        _acceptSubmission(_taskID, _submissionID);
    }

    function rejectSubmission(
        uint64 _projectID,
        uint64 _taskID,
        uint64 _submissionID
    ) public {
        _adminCheck(_projectID);
        _rejectSubmission(_taskID, _submissionID);
    }

    function changeTaskPayRate(
        uint64 _projectID,
        uint64 _taskID,
        uint256 _amount
    ) external {
        _adminCheck(_projectID);
        _changeTaskPayRate(_taskID, _amount);
    }

    // function getProjectInfo() public {}

    function getVault(uint64 projectID) public view returns (address vault) {
        return ProjectVault[projectID];
    }

    function _adminCheck(uint64 _projectID) internal {
        DataTypes.ProjectReg memory PR = ProjectRegi[_projectID];
        // @Add signature logic later on.
        require(PR.adminAccount == msg.sender);
    }

    function withdrawYield(uint64 _projectID) external {
        DataTypes.ProjectReg memory RG = ProjectRegi[_projectID];
        require(RG.adminAccount == msg.sender, "Must be admin");

        vault = ITokenizedStrategy(ProjectVault[_projectID]);

        (uint256 profit, ) = vault.report();

        uint256 _amount = vault.convertToShares(profit);

        vault.withdraw(_amount, address(this), address(this), 0);

        IERC20(USDC).transfer(RG.adminAccount, profit);
    }

    // AddContractToMonitor:
    // Allows the admin to add an address they want to add for transparency, For example:  Project has a new treasury address.

    // Emits  ContractMonitored()

    // RemoveContractToMonitor:
    // Allows the admin to Remove an address they want to  remove, For example:  Project has a new treasury address.

    // Emits  RemoveContractMonitored()

    // SubmitInformationAboutATransaction:
    // Add a information about a transaction,  this also allows them to edit.

    // Emits  InformationSubmitted()
}
