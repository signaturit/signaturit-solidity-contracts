pragma solidity <0.6.0;

/*
Gas to deploy: 1.679.680
*/

import "./libraries/Utils.sol";
import "./libraries/UsingConstants.sol";

import "./interfaces/SignatureInterface.sol";

contract AuditTrails is UsingConstants {

    mapping(address => bool) rootAddresses;
    
    struct AuditTrail {
        address signatureAddress;
    }

    mapping(address => mapping(string => AuditTrail)) private requesterAuditTrails;
    mapping(address => mapping(address => bool)) private admittedNotifiers;

    constructor() public {
        rootAddresses[msg.sender] = true;
    }

    modifier onlyNotifier(address requesterAddress) {
        require(
            rootAddresses[msg.sender] == true ||
            admittedNotifiers[requesterAddress][msg.sender] == true,
            "Only an admitted notifier can call this function"
        );

        _;
    }

    modifier onlyRoot() {
        require(
            rootAddresses[msg.sender] == true,
            "Only an admitted root address can call this function"
        );

        _;
    }

    function subscribe(
        address requesterSmartContract
    )
        public
        onlyRoot
    {
        SignaturitUserInterface tmpUser = SignaturitUserInterface(requesterSmartContract);

        admittedNotifiers[tmpUser.ownerAddress()][msg.sender] = true;

        tmpUser.setAddressArrayAttribute(DOCUMENT_NOTIFIERS_KEY, address(this));
    }

    function addRoot(
        address newRoot
    )
        public
        onlyRoot
    {
        rootAddresses[newRoot] = true;
    }

    function setNotifier(
        address requesterAddress,
        address notifier
    )
        public
        onlyNotifier(requesterAddress)
    {
        admittedNotifiers[requesterAddress][notifier] = true;
    }

    function getAudit(
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
        AuditTrail memory tmpAudit = _getAudit(msg.sender, documentHashedId);

        SignatureInterface signature = SignatureInterface(tmpAudit.signatureAddress);

        DocumentInterface document = DocumentInterface(signature.getDocument(documentHashedId));

        address fileAdr = signature.getFile(documentHashedId);

        return (
            tmpAudit.signatureAddress,
            signature.getDocument(documentHashedId),
            signature.owner(),
            document.signer(),
            address(fileAdr),
            document.getEventsSize(),
            document.signedAt()
        );
    }

    function getEventInAudit(
        uint index,
        string memory documentHashedId
    )
        public
        view
        returns(
        string memory id,
        string memory eventType,
        string memory userAgent,
        uint createdAt
    )  {
            AuditTrail memory tmpAudit = _getAudit(msg.sender, documentHashedId);

            SignatureInterface signature = SignatureInterface(tmpAudit.signatureAddress);

            DocumentInterface document = DocumentInterface(signature.getDocument(documentHashedId));

            require(document.getEventsSize() > index, "The index exceeds the number of events");

            string memory eventId = document.eventsId(index);

            EventInterface tmpEvent = EventInterface(document.getEvent(eventId));

            return(
                eventId,
                tmpEvent.eventType(),
                tmpEvent.userAgent(),
                tmpEvent.createdAt()
            );
        }

    function notify (
        uint receivedEventType,
        address addr
    )
        public
    {
        if (receivedEventType == uint(enumEvents.DOCUMENT_CREATED_EVENT)) {
            DocumentInterface document = DocumentInterface(addr);
            SignatureInterface signature = SignatureInterface(document.signature());

            _checkValidCaller(address(signature.userContract()));

            address owner = signature.owner();
            string memory documentId = document.id();

            require(
                !_checkExistence(owner, documentId),
                "The audit for this document already exists"
            );

            AuditTrail memory audit = AuditTrail(
                address(signature)
            );

            requesterAuditTrails[owner][documentId] = audit;

        }
    }

    function _getAudit(address requester, string memory documentId) internal view returns(AuditTrail memory) {
        require(requesterAuditTrails[requester][documentId].signatureAddress != address(0), "The audit for this document doesn't exists");

        return requesterAuditTrails[requester][documentId];
    }

    function _checkExistence(address owner, string memory documentId) internal view returns(bool){
        if (requesterAuditTrails[owner][documentId].signatureAddress != address(0)) return true;
        return false;
    }

    function _checkValidCaller(address userSmartContract) internal view {
        require(
            _validAddress(userSmartContract),
            "Only Signaturit or a validated account can perform this action"
        );
    }

    function _validAddress(address userSmartContract) internal view returns(bool){
        bool result = false;

        SignaturitUserInterface userContract = SignaturitUserInterface(userSmartContract);

        if (admittedNotifiers[userContract.ownerAddress()][tx.origin]) {
            result = true;
        }

        return result;
    }
}
