import {DataTypes} from "src/types/DataTypes.sol";

interface ISubmissionManager {
    function createSubmission(
        uint64 _taskID,
        DataTypes.SubmissionCreation memory SC,
        DataTypes.TaskCreation memory TC
    ) external;
    function acceptSubmission(
        uint64 _taskID,
        uint64 _submissionId,
        DataTypes.TaskCreation memory TC
    ) external;
    function rejectSubmission(uint64 _taskID, uint64 _submissionId) external;
    function getSubmission(
        uint64 _submissionID
    ) external view returns (DataTypes.SubmissionCreation memory SC);
}
