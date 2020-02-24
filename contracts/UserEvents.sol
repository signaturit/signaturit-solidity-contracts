pragma solidity <0.6.0;

/*
Gas to deploy: 1.241.327
*/

import "./interfaces/NotifierInterface.sol";
import "./interfaces/SignaturitUserInterface.sol";

import "./libraries/Utils.sol";
import "./libraries/UsingConstants.sol";

contract UserEvents is NotifierInterface, UsingConstants {
    address public signaturit;

    SignaturitUserInterface public userContract;

    event SignatureCreated(address);
    event DocumentCreated(address);
    event FileCreated(address);
    event EventCreated(address);
    event CertifiedFileCreated(address);
    event CertifiedEmailCreated(address);
    event CertificateCreated(address);
    event TimeLogAdded(address);
    event PaymentCheckAdded(address);

    constructor (
        address signaturitUser
    )
        public
    {
        signaturit = msg.sender;

        userContract = SignaturitUserInterface(signaturitUser);

        userContract.setAddressAttribute(USER_EVENTS, address(this));

        userContract.setAddressArrayAttribute(FILE_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(EVENT_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(DOCUMENT_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(SIGNATURE_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(TIMELOGGER_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(CERTIFICATE_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(CERTIFIED_FILE_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(PAYMENT_CHECKS_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(CERTIFIED_EMAIL_NOTIFIERS_KEY, address(this));
    }

    function notify (
        uint receivedEventType,
        address addr
    )
        public
    {
        require(
            validAddress(),
            "Only Signaturit or a validated account can perform this action"
        );

        if (receivedEventType == uint(enumEvents.SIGNATURE_CREATED_EVENT)) {
            emit SignatureCreated(addr);
        } else if (receivedEventType == uint(enumEvents.DOCUMENT_CREATED_EVENT)) {
            emit DocumentCreated(addr);
        } else if (receivedEventType == uint(enumEvents.FILE_CREATED_EVENT)) {
            emit FileCreated(addr);
        } else if (receivedEventType == uint(enumEvents.EVENT_CREATED_EVENT)) {
            emit EventCreated(addr);
        } else if (receivedEventType == uint(enumEvents.CERTIFIED_FILE_CREATED_EVENT)) {
            emit CertifiedFileCreated(addr);
        } else if (receivedEventType == uint(enumEvents.CERTIFIED_EMAIL_CREATED_EVENT)) {
            emit CertifiedEmailCreated(addr);
        } else if (receivedEventType == uint(enumEvents.CERTIFICATE_CREATED_EVENT)) {
            emit CertificateCreated(addr);
        } else if (receivedEventType == uint(enumEvents.TIMELOG_ADDED_EVENT)) {
            emit TimeLogAdded(addr);
        } else if (receivedEventType == uint(enumEvents.PAYMENT_CHECK_ADDED_EVENT)) {
            emit PaymentCheckAdded(addr);
        }
    }

    function validAddress() internal view returns(bool){
        bool result = false;

        if (tx.origin == signaturit ||
            userContract.getMappingAddressBool(VALIDATED_NOTIFIERS_KEY, tx.origin)
        ) {
            result = true;
        }

        return result;
    }
}