import {DataTypes} from "src/types/DataTypes.sol";

interface ITaskManager {
    function createTask(
        uint64 _TaskID,
        DataTypes.TaskCreation memory TC
    ) external;
    function removeTask(uint64 projectID, uint64 taskID) external;
    function changeTaskPayRate(uint64 _taskID, uint256 _amount) external;
    function getTask(
        uint64 _taskID
    ) external view returns (DataTypes.TaskCreation memory TC);
    function closeTask(uint64 taskID, uint64 submissionID) external;
}
