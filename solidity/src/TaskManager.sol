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
    event TaskRateChanged(uint64 taskID, uint256 newAmount);

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

        emit TaskRemoved(_projectID, _taskID);
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

        emit SubmissionCreated(_taskID, submissionID);
    }

    function _acceptSubmission(uint64 _taskID, uint64 _submissionId) internal {
        DataTypes.SubmissionCreation memory SC = SubmissionRegistry[
            _submissionId
        ];
        DataTypes.TaskCreation memory TC = TaskRegistry[_taskID];

        if (TC.amount > 0 && SC.user != address(0x0)) {
            IERC20(USDC).safeTransfer(SC.user, TC.amount);
        }

        DataTypes.TaskCreation memory TSC = TaskRegistry[_taskID];

        TSC.taskClosed = true;

        emit SubmissionAccepted(_taskID, _submissionId);
    }

    function _rejectSubmission(uint64 _taskID, uint64 _submissionId) internal {
        DataTypes.SubmissionCreation storage SC = SubmissionRegistry[
            _submissionId
        ];
        SC.SubmissionRejected = true;

        emit SubmissionDenied(_taskID, _submissionId);
    }

    function _changeTaskPayRate(uint64 _taskID, uint256 _amount) internal {
        DataTypes.TaskCreation storage TC = TaskRegistry[_taskID];
        TC.amount = _amount;

        emit TaskRateChanged(_taskID, _amount);
    }

    function getTask(
        uint64 _taskID
    ) public view returns (DataTypes.TaskCreation memory TC) {
        return TaskRegistry[_taskID];
    }

    function getSubmission(
        uint64 _submissionID
    ) public view returns (DataTypes.SubmissionCreation memory TC) {
        return SubmissionRegistry[_submissionID];
    }
}
