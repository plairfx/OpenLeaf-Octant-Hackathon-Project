// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

library DataTypes {
    struct ProjectReg {
        string Name;
        string Description;
        address adminAccount;
        uint256 depositAmount;
        address token;
        bool vault;
        bool registered;
    }

    struct TaskCreation {
        uint64 ProjectId;
        string ProjectName;
        string TaskName;
        string TaskDescription;
        address paymentToken;
        uint256 amount;
        bool taskClosed;
    }

    struct SubmissionCreation {
        uint64 TaskID;
        string SubmissionName;
        address user;
        string SubmissionDescription;
        string SubmissionLink;
        bool SubmissionRejected;
    }
}
