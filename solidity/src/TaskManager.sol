// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {DataTypes} from "src/types/DataTypes.sol";

import {SafeERC20, IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract TaskManager {
    using SafeERC20 for IERC20;

    mapping(uint64 taskId => DataTypes.TaskCreation) TaskRegistry;
    mapping(uint64 submissionID => DataTypes.SubmissionCreation) SubmissionRegistry;

    address USDC;
    uint64 taskID;
    uint64 submissionID;

    event TaskCreated(uint64 projectId, uint64 taskID);
    event TaskRemoved(uint64 projectId, uint64 taskID);

    event SubmissionCreated(uint64 taskId, uint64 submissionId);
    event SubmissionAccepted(uint64 taskId, uint64 submissionId);
    event SubmissionDenied(uint64 taskId, uint64 submissionId);

    function _createTask(
        uint64 _projectId,
        DataTypes.TaskCreation memory TC
    ) internal {
        taskID++;
        TC.ProjectId = _projectId;
        TaskRegistry[taskID] = TC;

        emit TaskCreated(_projectId, taskID);
    }

    function _removeTask(uint64 _projectID, uint64 _taskID) internal {
        DataTypes.TaskCreation memory TC = TaskRegistry[_taskID];
        require(TC.ProjectId != 0);
        TC.taskClosed = true;

        emit TaskRemoved(_projectID, taskID);
    }

    function _createSubmission(
        uint64 _taskID,
        DataTypes.SubmissionCreation memory SC
    ) internal {
        DataTypes.TaskCreation memory TC = TaskRegistry[_taskID];
        require(TC.ProjectId != 0);

        // depositFee.(To migitate the DOS);
        // check if tasks is stll open.
        // intiialize the struct and store it!.
        submissionID++;
        SubmissionRegistry[submissionID] = SC;

        emit SubmissionCreated(taskID, submissionID);
    }

    // if lets say the admin fucks up and rejects an submissin,
    // he can still accept it by paying it to the user.
    function _acceptSubmission(uint64 taskID, uint64 submissionId) internal {
        // check if submission exists or not..
        DataTypes.SubmissionCreation memory SC = SubmissionRegistry[
            submissionId
        ];
        DataTypes.TaskCreation memory TC = TaskRegistry[taskID];

        if (TC.amount > 0) {
            IERC20(USDC).safeTransfer(SC.user, TC.amount);
        }

        emit SubmissionAccepted(taskID, submissionId);
    }

    function _rejectSubmission(uint64 taskID, uint64 submissionId) internal {
        // check if submission exists or not..
         emit SubmissionDenied(taskID, submissionId);
    }

    function changeTaskPayRate(uint64 taskID) external {
        // @admin check ,but that will happen in registry contract..
    }
}
