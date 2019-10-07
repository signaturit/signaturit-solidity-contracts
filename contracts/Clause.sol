pragma solidity <0.6.0;

import "./interfaces/SignaturitUserInterface.sol";
import "./interfaces/NotifierInterface.sol";


contract Clause {
    string public notifiersKey;

    address public signaturit;

    string public contractId;
    string public documentId;
    string public signatureId;

    SignaturitUserInterface public userContract;
    NotifierInterface public signatureContract;

    constructor(
        string memory notifiers
    )
        public
    {
        notifiersKey = notifiers;
    }

    function _notifySignature(string memory creationEvent)
        internal
    {
        signatureContract.notify(
            creationEvent,
            address(this)
        );
    }

    function _notify(string memory eventType)
        internal
    {
        address contractToNofify;
        uint notificationIndex = 0;

        do {
            contractToNofify = userContract.getAddressArrayAttribute(notifiersKey, notificationIndex);
            ++notificationIndex;

            if (contractToNofify != address(0)) {
                contractToNofify.call(
                    abi.encodeWithSignature(
                        "notify(string,address)",
                        eventType,
                        address(this)
                    )
                );
            }
        } while (contractToNofify != address(0));
    }
}
