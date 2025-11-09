// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {DataTypes} from "src/types/DataTypes.sol";
import {
    SafeERC20,
    IERC20
} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title OpenLeaf's SubmissionManager
/// @author Plairfx
/// @notice Use this contract for submitting & managing submissions.
/// @dev This contracts manages Tasks and submissions associated with the tasks.

contract SubmissionManager {
    using SafeERC20 for IERC20;

    mapping(uint64 submissionID => DataTypes.SubmissionCreation) SubmissionRegistry;

    address immutable USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint64 submissionID;

    event SubmissionCreated(uint64 taskId, uint64 submissionId);
    event SubmissionAccepted(uint64 taskId, uint64 submissionId);
    event SubmissionDenied(uint64 taskId, uint64 submissionId);

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

    function createSubmission(
        uint64 _taskID,
        DataTypes.SubmissionCreation memory SC,
        DataTypes.TaskCreation memory TC
    ) external onlyRegistry {
        require(TC.ProjectId != 0);
        require(!TC.taskClosed, "task cannot be closed..");

        submissionID++;
        SubmissionRegistry[submissionID] = SC;

        emit SubmissionCreated(_taskID, submissionID);
    }

    function acceptSubmission(
        uint64 _taskID,
        uint64 _submissionId,
        DataTypes.TaskCreation memory TC
    ) external onlyRegistry {
        // DataTypes.SubmissionCreation memory SC = SubmissionRegistry[
        //     _submissionId
        // ];

        emit SubmissionAccepted(_taskID, _submissionId);
    }

    function rejectSubmission(
        uint64 _taskID,
        uint64 _submissionId
    ) external onlyRegistry {
        DataTypes.SubmissionCreation storage SC = SubmissionRegistry[
            _submissionId
        ];
        SC.SubmissionRejected = true;

        emit SubmissionDenied(_taskID, _submissionId);
    }

    function setRegistry(address _newRegistry) external onlyOwner {
        registry = _newRegistry;
    }

    function getSubmission(
        uint64 _submissionID
    ) public view returns (DataTypes.SubmissionCreation memory TC) {
        return SubmissionRegistry[_submissionID];
    }
}
