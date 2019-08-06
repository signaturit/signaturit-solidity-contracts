pragma solidity 0.5.0;

import "./interfaces/UserInterface.sol";

contract Clause {
    string public clause;

    UserInterface public userContract;

    constructor(string memory clauseType) public {
        clause = clauseType;
    }

    function publishNotification(
        address clauseContract,
        string memory notificationType,
        string memory id
    )
        internal
    {
        userContract.clauseNotification(clauseContract, notificationType, id);
    }
}
