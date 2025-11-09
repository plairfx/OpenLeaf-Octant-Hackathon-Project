// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {DataTypes} from "src/types/DataTypes.sol";

/// @title OpenLeaf's TaskManager
/// @author Plairfx
/// @notice You can use this contract for only the most basic simulation
/// @dev This contracts manages Tasks on the OpenLeaf platform..
contract TaskManager {
    mapping(uint64 taskId => DataTypes.TaskCreation) TaskRegistry;

    uint64 taskID;

    event TaskCreated(uint64 projectId, uint64 taskID);
    event TaskRemoved(uint64 projectId, uint64 taskID);
    event TaskRateChanged(uint64 taskID, uint256 newAmount);
    event TaskCompleted(uint64 taskID, uint64 submissionID);

    address registry;
    address owner;

    modifier onlyRegistry() {
        require(msg.sender == registry, "Not the registry");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @param _projectId test
     * @param TC ..
     */

    function createTask(
        uint64 _projectId,
        DataTypes.TaskCreation memory TC
    ) external onlyRegistry {
        taskID++;
        TC.ProjectId = _projectId;
        TaskRegistry[taskID] = TC;

        emit TaskCreated(_projectId, taskID);
    }

    function removeTask(
        uint64 _projectID,
        uint64 _taskID
    ) external onlyRegistry {
        DataTypes.TaskCreation memory TC = TaskRegistry[_taskID];
        require(TC.ProjectId != 0);
        TC.taskClosed = true;

        emit TaskRemoved(_projectID, _taskID);
    }

    function changeTaskPayRate(
        uint64 _taskID,
        uint256 _amount
    ) external onlyRegistry {
        DataTypes.TaskCreation storage TC = TaskRegistry[_taskID];
        TC.amount = _amount;

        emit TaskRateChanged(_taskID, _amount);
    }

    function closeTask(
        uint64 taskID,
        uint64 submissionID
    ) external onlyRegistry {
        DataTypes.TaskCreation storage TC = TaskRegistry[taskID];

        TC.taskClosed = true;
        emit TaskCompleted(taskID, submissionID);
    }

    function setRegistry(address _newRegistry) external onlyOwner {
        registry = _newRegistry;
    }

    function getTask(
        uint64 _taskID
    ) public view returns (DataTypes.TaskCreation memory TC) {
        return TaskRegistry[_taskID];
    }
}
