// SPDX-License-Identifier: MIT

import {TaskManager} from "src/TaskManager.sol";
import {DataTypes} from "src/types/DataTypes.sol";

import {
    SafeERC20,
    IERC20
} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity 0.8.30;

contract Registry is TaskManager {
    using SafeERC20 for IERC20;

    uint64 projectID;
    bytes32 empty = keccak256(abi.encode(""));

    event ProjectRegistered(
        string projectName,
        string projectDescription,
        uint64 projectId
    );

    mapping(uint64 projectid => DataTypes.ProjectReg) ProjectRegi;
    mapping(uint64 projectId => address vault) ProjectVault;

    function registerAsProject(DataTypes.ProjectReg memory RG) external {
        if (RG.vault) {
            require(RG.token == USDC);
            // we need to create and deploy some contracts.
        }
        projectID++;
        RG.registered = true;
        ProjectRegi[projectID] = RG;

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

        if (RG.vault) {
            // check if it has enough money or not..
            // and send it to here.
            // @Add Vault Logic here..
        } else if (RG.depositAmount > 0) {
            IERC20(USDC).safeTransferFrom(
                msg.sender,
                address(this),
                RG.depositAmount
            );
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

    function _adminCheck(uint64 _projectID) internal {
        DataTypes.ProjectReg memory PR = ProjectRegi[_projectID];
        // @Add signature logic later on.
        require(PR.adminAccount == msg.sender);
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
