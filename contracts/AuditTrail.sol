pragma solidity <0.6.0;

/*
Gas to deploy: 1.441.547
*/

import "./libraries/Utils.sol";

import "./interfaces/FileInterface.sol";
import "./interfaces/EventInterface.sol";
import "./interfaces/EventInterface.sol";
import "./interfaces/DocumentInterface.sol";
import "./interfaces/SignatureInterface.sol";
import "./interfaces/SignaturitUserInterface.sol";

contract AuditTrails {

    string constant private FILE_NOTIFIERS_KEY = "file-notifiers";
    string constant private EVENT_NOTIFIERS_KEY = "event-notifiers";
    string constant private DOCUMENT_NOTIFIERS_KEY = "document-notifiers";
    string constant private SIGNATURE_NOTIFIERS_KEY = "signature-notifiers";

    string constant private FILE_CREATED_EVENT = "file.contract.created";
    string constant private EVENT_CREATED_EVENT = "event.contract.created";
    string constant private TIMELOG_ADDED_EVENT = "timelog.added";
    string constant private DOCUMENT_CREATED_EVENT = "document.contract.created";
    string constant private SIGNATURE_CREATED_EVENT = "signature.contract.created";

    string constant private DOCUMENT_SIGNED_EVENT = "document.contract.signed";
    string constant private DOCUMENT_DECLINED_EVENT = "document.contract.declined";
    string constant private DOCUMENT_CANCELED_EVENT = "document.contract.canceled";

    string constant private VALIDATED_NOTIFIERS_KEY = "validated-notifiers";

    struct AuditTrail {
        address signatureAddress;
        address requesterAddress;
        address signerAddress;
        address fileAddress;
        address[] events;
        uint terminatedAt;
    }

    mapping(address => mapping(string => AuditTrail)) requesterAuditTrails;
    mapping(address => mapping(address => bool)) admittedNotifiers;

    constructor() public {}

    function subscribe(
        address requesterSmartContract
    )
        public
    {
        SignaturitUserInterface tmpUser = SignaturitUserInterface(requesterSmartContract);

        admittedNotifiers[tmpUser.ownerAddress()][msg.sender] = true;

        tmpUser.setAddressArrayAttribute(FILE_NOTIFIERS_KEY, address(this));
        tmpUser.setAddressArrayAttribute(EVENT_NOTIFIERS_KEY, address(this));
        tmpUser.setAddressArrayAttribute(DOCUMENT_NOTIFIERS_KEY, address(this));
    }

    function getAudit(
        address requesterPubKey,
        string memory documentHashedId
    )
        public
        view
        returns(
            address signatureAddr,
            address documentAddr,
            address requesterAddr,
            address signerAddr,
            address fileAddr,
            uint eventsLength,
            uint terminatedAt
        )
    {
        AuditTrail memory tmpAudit = _getAudit(requesterPubKey, documentHashedId);

        SignatureInterface signature = SignatureInterface(tmpAudit.signatureAddress);

        return (
            tmpAudit.signatureAddress,
            signature.getDocument(documentHashedId),
            tmpAudit.requesterAddress,
            tmpAudit.signerAddress,
            tmpAudit.fileAddress,
            tmpAudit.events.length,
            tmpAudit.terminatedAt
        );
    }

    function getEventInAudit(
        uint index,
        address requesterPubKey,
        string memory documentHashedId
    )
        public
        view
        returns(
        string memory id,
        string memory eventType,
        string memory userAgent,
        uint createdAt
    ) {
        AuditTrail memory tmpAudit = _getAudit(requesterPubKey, documentHashedId);

        require(tmpAudit.events.length > index, "The index exceeds the number of events");

        EventInterface tmpEvent = EventInterface(tmpAudit.events[index]);

        return(
            tmpEvent.id(),
            tmpEvent.eventType(),
            tmpEvent.userAgent(),
            tmpEvent.createdAt()
        );
    }

    function notify (
        string memory eventType,
        address addr
    )
        public
    {
        bytes32 bytes32event = Utils.keccak(eventType);

        if (bytes32event == Utils.keccak(DOCUMENT_CREATED_EVENT)) {
            DocumentInterface document = DocumentInterface(addr);
            SignatureInterface signature = SignatureInterface(document.signature());

            _checkValidCaller(address(signature.userContract()));

            address owner = signature.owner();
            string memory documentId = document.id();

            require(
                !_checkExistence(owner, documentId),
                "The audit for this document already exists"
            );

            address[] memory eventsInAudit;

            AuditTrail memory audit = AuditTrail(
                address(signature),
                signature.owner(),
                document.signer(),
                address(0),
                eventsInAudit,
                0
            );

            requesterAuditTrails[signature.owner()][document.id()] = audit;

        } else if (bytes32event == Utils.keccak(FILE_CREATED_EVENT)) {
            FileInterface file = FileInterface(addr);
            DocumentInterface document = DocumentInterface(file.parent());
            SignatureInterface signature = SignatureInterface(document.signature());

            _checkValidCaller(address(signature.userContract()));

            address owner = signature.owner();
            string memory documentId = document.id();

            require(_checkExistence(owner, documentId), "The audit for this document doesn't exists");

            requesterAuditTrails[owner][documentId].fileAddress = addr;

        } else if (bytes32event == Utils.keccak(EVENT_CREATED_EVENT)) {
            EventInterface documentEvent = EventInterface(addr);
            DocumentInterface document = DocumentInterface(documentEvent.parent());
            SignatureInterface signature = SignatureInterface(document.signature());

            _checkValidCaller(address(signature.userContract()));

            address owner = signature.owner();
            string memory documentId = document.id();

            require(_checkExistence(owner, documentId), "The audit for this document doesn't exists");

            bytes32 documentEventType = Utils.keccak(documentEvent.eventType());

            if(
                documentEventType == Utils.keccak(DOCUMENT_SIGNED_EVENT) ||
                documentEventType == Utils.keccak(DOCUMENT_DECLINED_EVENT) ||
                documentEventType == Utils.keccak(DOCUMENT_CANCELED_EVENT)
            ) {
                requesterAuditTrails[owner][documentId].terminatedAt = documentEvent.createdAt();
            }

            requesterAuditTrails[signature.owner()][document.id()].events.push(addr);
        }
    }

    function _getAudit(address requester, string memory documentId) internal view returns(AuditTrail memory) {
        require(requesterAuditTrails[requester][documentId].signatureAddress != address(0), "The audit for this document doesn't exists");

        return requesterAuditTrails[requester][documentId];
    }

    function _checkExistence(address owner, string memory documentId) internal view returns(bool){
        if(requesterAuditTrails[owner][documentId].signatureAddress != address(0)) return true;
        else return false;
    }

    function _checkValidCaller(address userSmartContract) internal view {
        require(
            _validAddress(userSmartContract),
            "Only Signaturit or a validated account can perform this action"
        );
    }

    function _validAddress(address userSmartContract) internal view returns(bool){
        address checkedAddress;
        uint notificationIndex = 0;
        bool result = false;

        SignaturitUserInterface userContract = SignaturitUserInterface(userSmartContract);

        if (admittedNotifiers[userContract.ownerAddress()][msg.sender]) {
            result = true;

        } else {
            do {
                checkedAddress = userContract.getAddressArrayAttribute(VALIDATED_NOTIFIERS_KEY, notificationIndex);

                if (checkedAddress == msg.sender) {
                    result = true;

                    checkedAddress = address(0);
                }

                ++notificationIndex;
            } while (checkedAddress != address(0));
        }

        return result;
    }
}
