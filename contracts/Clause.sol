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
    SignatureInterface public signatureSmartContract;

    constructor(
        string memory clauseType
    )
        public
    {
        clause = clauseType;
    }

    function publishNotification(
        address clauseContract,
        string memory clauseType,
        string memory notificationType,
        string memory id
    )
        internal
    {
        userContract.clauseNotification(
            clauseContract,
            clauseType,
            notificationType,
            id
        );
    }
}
