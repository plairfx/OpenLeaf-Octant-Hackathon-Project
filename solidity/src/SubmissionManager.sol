// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {DataTypes} from "src/types/DataTypes.sol";
import {
    SafeERC20,
    IERC20
} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title OpenLeaf's SubmissionManager
/// @author github.com/plairfx
/// @notice Manages submission made in the OpenLeaf protocol.
/// @dev This contracts manages Tasks and submissions associated with the tasks.
// RegistryContract uses this contract for submitting & managing submissions.
contract SubmissionManager {
    using SafeERC20 for IERC20;

    mapping(uint64 submissionID => DataTypes.SubmissionCreation) SubmissionRegistry;
    address immutable USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint64 submissionID;
    address registry;
    address owner;

    event SubmissionCreated(uint64 taskId, uint64 submissionId);
    event SubmissionAccepted(uint64 taskId, uint64 submissionId);
    event SubmissionDenied(uint64 taskId, uint64 submissionId);

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

    /// @notice Creates the submission and saves it.
    /// @param _taskID The taskID the user wants to submit for.
    /// @param SC Struct that has all the submission info
    /// @param TC Struct that has the info about the task.
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

    /// @notice Allows the admin to accept a submission and pay him out.
    /// @param _taskID The taskID the user wants to submitted for.
    /// @param _submissionId the submission that admin wants to accept.
    /// @param TC Struct that has all the task info.
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

    /// @notice Allows the admin to reject a submission.
    /// @dev it should revert if its not the admin.
    /// @param _taskID The taskID the user wants to submitted for.
    /// @param _submissionId the submission the admin wants to reject.
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

    /// @notice Allows the owner to set a new registry address
    /// @dev only the Owner can change this.
    /// @param _newRegistry the new registry address.
    function setRegistry(address _newRegistry) external onlyOwner {
        registry = _newRegistry;
    }

    /// @notice return the submission info struct.
    /// @param _submissionID the  address.
    /// @return TC returns the submission struct.
    function getSubmission(
        uint64 _submissionID
    ) public view returns (DataTypes.SubmissionCreation memory TC) {
        return SubmissionRegistry[_submissionID];
    }
}
