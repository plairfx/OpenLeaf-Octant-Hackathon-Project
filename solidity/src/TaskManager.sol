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
    address registry;
    address owner;

    event TaskCreated(uint64 projectId, uint64 taskID);
    event TaskRemoved(uint64 projectId, uint64 taskID);
    event TaskRateChanged(uint64 taskID, uint256 newAmount);
    event TaskCompleted(uint64 taskID, uint64 submissionID);

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

    /// @notice creates a task
    /// @param _projectId the projectId to create a task for.
    /// @param TC the configuration for the Task
    /// @dev this only accepts calls from the registry address.
    function createTask(
        uint64 _projectId,
        DataTypes.TaskCreation memory TC
    ) external onlyRegistry {
        taskID++;
        TC.ProjectId = _projectId;
        TaskRegistry[taskID] = TC;

        emit TaskCreated(_projectId, taskID);
    }

    /// @notice removes a task
    /// @param _projectID the projectId to remove a task for.
    /// @param _taskID the task to remove.
    /// @dev this only accepts calls from the registry address.
    function removeTask(
        uint64 _projectID,
        uint64 _taskID
    ) external onlyRegistry {
        DataTypes.TaskCreation memory TC = TaskRegistry[_taskID];
        require(TC.ProjectId != 0);
        TC.taskClosed = true;

        emit TaskRemoved(_projectID, _taskID);
    }

    /// @notice changes the payment for a task
    /// @param _taskID the projectId to change the payment rate for.
    /// @param _amount the new payment rate for the task.
    /// @dev this only accepts calls from the registry address.
    function changeTaskPayRate(
        uint64 _taskID,
        uint256 _amount
    ) external onlyRegistry {
        DataTypes.TaskCreation storage TC = TaskRegistry[_taskID];
        TC.amount = _amount;

        emit TaskRateChanged(_taskID, _amount);
    }

    /// @notice close/completenish a task.
    /// @param taskID the taskID you want to complete/payout.
    /// @param submissionID the submission ID you want to complete with.
    /// @dev this only accepts calls from the registry address.
    function closeTask(
        uint64 taskID,
        uint64 submissionID
    ) external onlyRegistry {
        DataTypes.TaskCreation storage TC = TaskRegistry[taskID];

        TC.taskClosed = true;
        emit TaskCompleted(taskID, submissionID);
    }

    /// @notice sets the registryAddress that can call the main function
    /// @param _newRegistry the new registry addess to set.
    /// @dev only the Owner can set this.
    function setRegistry(address _newRegistry) external onlyOwner {
        registry = _newRegistry;
    }

    /// @notice sets the registryAddress that can call the main function
    /// @param _taskID the task info you want to get.
    /// @return TC returns the configuration of a task.
    function getTask(
        uint64 _taskID
    ) public view returns (DataTypes.TaskCreation memory TC) {
        return TaskRegistry[_taskID];
    }
}
