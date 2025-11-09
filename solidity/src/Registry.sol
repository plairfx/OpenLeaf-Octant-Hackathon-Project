// SPDX-License-Identifier: MIT

import {DataTypes} from "src/types/DataTypes.sol";
import {SparkStrategy} from "src/YDS/SparkStrategy.sol";
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

import {IVaultFactory} from "src/interfaces/IVaultFactory.sol";

pragma solidity 0.8.30;

contract Registry {
    using SafeERC20 for IERC20;

    SparkStrategy public strategy;
    YieldDonatingTokenizedStrategy public implementation;
    ITokenizedStrategy public vault;
    ISubmissionManager public SM;
    ITaskManager public TM;
    IVaultFactory public VaultFactory;

    address immutable USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint64 projectID;
    bytes32 empty = keccak256(abi.encode(""));

    event ProjectRegistered(
        string projectName,
        string projectDescription,
        uint64 projectId
    );

    event VaultCreated(address vault);

    mapping(uint64 projectid => DataTypes.ProjectReg) ProjectRegi;
    mapping(uint64 projectId => address vault) ProjectVault;

    constructor(address _TM, address _SM, address _vaultFactory) {
        TM = ITaskManager(_TM);
        SM = ISubmissionManager(_SM);
        VaultFactory = IVaultFactory(_vaultFactory);
    }

    function registerAsProject(DataTypes.ProjectReg memory RG) external {
        if (RG.vault) {
            require(RG.token == USDC);

            (address implementation, address strategy) = VaultFactory
                .createVault(RG);

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

                    IERC20(USDC).safeTransfer(
                        RG.adminAccount,
                        profit - TC.amount
                    );
                } else {
                    TC.amount = TC.amount - profit;
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
        TM.createTask(_projectID, TC);
    }

    function removeTask(uint64 _projectID, uint64 _taskID) external {
        _adminCheck(_projectID);
        TM.removeTask(_projectID, _taskID);
    }

    function createSubmission(
        uint64 _projectID,
        DataTypes.SubmissionCreation memory SC
    ) external {
        DataTypes.TaskCreation memory TC = TM.getTask(SC.TaskID);

        require(TC.ProjectId == _projectID);
        require(
            keccak256(abi.encode(SC.SubmissionDescription)) != empty &&
                keccak256(abi.encode(SC.SubmissionName)) != empty &&
                keccak256(abi.encode(SC.SubmissionLink)) != empty,
            "Submission Name/Description/Link cannot be empty!"
        );
        SM.createSubmission(SC.TaskID, SC, TC);
    }

    function acceptSubmission(
        uint64 _projectID,
        uint64 _taskID,
        uint64 _submissionID
    ) external {
        DataTypes.ProjectReg memory PR = ProjectRegi[_projectID];
        DataTypes.TaskCreation memory TC = TM.getTask(_taskID);
        require(PR.adminAccount == msg.sender, "Must be admin");

        SM.acceptSubmission(_taskID, _submissionID, TC);
        DataTypes.SubmissionCreation memory SC = SM.getSubmission(
            _submissionID
        );

        if (TC.amount > 0 && SC.user != address(0x0)) {
            IERC20(USDC).safeTransfer(SC.user, TC.amount);
        }
        TM.closeTask(_taskID, _submissionID);
    }

    function rejectSubmission(
        uint64 _projectID,
        uint64 _taskID,
        uint64 _submissionID
    ) public {
        _adminCheck(_projectID);
        SM.rejectSubmission(_taskID, _submissionID);
    }

    function changeTaskPayRate(
        uint64 _projectID,
        uint64 _taskID,
        uint256 _amount
    ) external {
        _adminCheck(_projectID);
        TM.changeTaskPayRate(_taskID, _amount);
    }

    function getVault(uint64 projectID) public view returns (address vault) {
        return ProjectVault[projectID];
    }

    function _adminCheck(uint64 _projectID) internal {
        DataTypes.ProjectReg memory PR = ProjectRegi[_projectID];
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
}
