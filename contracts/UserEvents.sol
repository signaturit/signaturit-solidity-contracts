pragma solidity <0.6.0;

import "./interfaces/NotifierInterface.sol";
import "./interfaces/SignaturitUserInterface.sol";

import "./libraries/Utils.sol";

contract UserEvents is NotifierInterface {
    address public signaturit;

    SignaturitUserInterface public userContract;

    string constant private USER_EVENTS = "user_events";

    string constant private SIGNATURE_CREATED_EVENT = "signature.contract.created";
    string constant private DOCUMENT_CREATED_EVENT = "document.contract.created";
    string constant private FILE_CREATED_EVENT = "file.contract.created";
    string constant private EVENT_CREATED_EVENT = "event.contract.created";
    string constant private CERTIFIED_EMAIL_CREATED_EVENT = "certified_email.contract.created";
    string constant private CERTIFICATE_CREATED_EVENT = "certificate.contract.created";
    string constant private CERTIFIED_FILE_CREATED_EVENT = "certified_file.contract.created";

    string constant private SIGNATURE_NOTIFIERS_KEY = "signature-notifiers";
    string constant private DOCUMENT_NOTIFIERS_KEY = "document-notifiers";
    string constant private FILE_NOTIFIERS_KEY = "file-notifiers";
    string constant private EVENT_NOTIFIERS_KEY = "event-notifiers";
    string constant private CERTIFIED_EMAIL_NOTIFIERS_KEY = "certified-email-notifiers";
    string constant private CERTIFICATE_NOTIFIERS_KEY = "certificate-notifiers";
    string constant private CERTIFIED_FILE_NOTIFIERS_KEY = "certified-file-notifiers";

    event SignatureCreated(address);
    event DocumentCreated(address);
    event FileCreated(address);
    event EventCreated(address);
    event CertifiedFileCreated(address);
    event CertifiedEmailCreated(address);
    event CertificateCreated(address);

    modifier signaturitOnly () {
        require(
            tx.origin == signaturit,
            "Only signaturit account can perform this acction"
        );

        _;
    }

    constructor (
        address signaturitUser
    )
        public
    {
        signaturit = msg.sender;

        userContract = SignaturitUserInterface(signaturitUser);

        userContract.setAddressAttribute(USER_EVENTS, address(this));

        userContract.setAddressArrayAttribute(SIGNATURE_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(DOCUMENT_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(FILE_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(EVENT_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(CERTIFIED_EMAIL_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(CERTIFICATE_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(CERTIFIED_FILE_NOTIFIERS_KEY, address(this));
    }

    function notify (
        string memory eventType,
        address addr
    )
        public
        signaturitOnly
    {
        bytes32 bytes32event = Utils.keccak(eventType);

        if (bytes32event == Utils.keccak(SIGNATURE_CREATED_EVENT)) {
            emit SignatureCreated(addr);
        } else if (bytes32event == Utils.keccak(DOCUMENT_CREATED_EVENT)) {
            emit DocumentCreated(addr);
        } else if (bytes32event == Utils.keccak(FILE_CREATED_EVENT)) {
            emit FileCreated(addr);
        } else if (bytes32event == Utils.keccak(EVENT_CREATED_EVENT)) {
            emit EventCreated(addr);
        } else if (bytes32event == Utils.keccak(CERTIFIED_FILE_CREATED_EVENT)) {
            emit CertifiedFileCreated(addr);
        } else if (bytes32event == Utils.keccak(CERTIFIED_EMAIL_CREATED_EVENT)) {
            emit CertifiedEmailCreated(addr);
        } else if (bytes32event == Utils.keccak(CERTIFICATE_CREATED_EVENT)) {
            emit CertificateCreated(addr);
        }
    }
}