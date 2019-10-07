pragma solidity <0.6.0;

import "./interfaces/SignaturitUserInterface.sol";
import "./interfaces/NotifierInterface.sol";


contract Clause {
    string public notificationEvent;

    address public signaturit;

    string public clause;
    string public contractId;
    string public documentId;
    string public signatureId;

    SignaturitUserInterface public userContract;
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

    function _notifySignature()
        internal
    {
        signatureContract.notify(
            clause,
            address(this)
        );
    }

    function _notify()
        internal
    {
        address contractToNofify;
        uint notificationIndex = 0;

        do {
            contractToNofify = userContract.getAddressArrayAttribute(notificationEvent, notificationIndex);
            ++notificationIndex;

            if (contractToNofify != address(0)) {
                contractToNofify.call(
                    abi.encodeWithSignature(
                        "notify(string,address)",
                        notificationEvent,
                        address(this)
                    )
                );
            }
        } while (contractToNofify != address(0));
    }
}
