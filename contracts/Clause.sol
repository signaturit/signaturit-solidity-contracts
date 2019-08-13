pragma solidity 0.5.0;

import "./interfaces/UserInterface.sol";
import "./interfaces/SignatureInterface.sol";


contract Clause {
    address public signaturit;

    string public clause;
    string public contractId;
    string public documentId;
    string public signatureId;

    UserInterface public userContract;
    SignatureInterface public signatureContract;

    constructor(
        string memory clauseType
    )
        public
    {
        clause = clauseType;
    }

    function publishNotification(
        string memory notificationType,
        string memory id
    )
        internal
    {
        userContract.clauseNotification(
            address(this),
            clause,
            notificationType,
            id
        );
    }

    function setClauseOnSignature()
        internal
    {
        signatureContract.setClause(
            clause,
            address(this)
        );
    }
}
