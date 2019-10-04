pragma solidity <0.6.0;

import "./interfaces/UserInterface.sol";
import "./interfaces/NotifierInterface.sol";


contract Clause {
    string public notificationEvent;

    address public signaturit;

    string public clause;
    string public contractId;
    string public documentId;
    string public signatureId;

    UserInterface public userContract;
    NotifierInterface public signatureContract;

    constructor(
        string memory clauseType,
        string memory eventType
    )
        public
    {
        clause = clauseType;
        notificationEvent = eventType;
    }

    function _notify(
    )
        internal
    {
        signatureContract.notify(
            clause,
            address(this)
        );
    }
}
