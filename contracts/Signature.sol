pragma solidity <0.6.0;

/*
Gas to deploy: 3.329.557
*/

import "./interfaces/SignatureInterface.sol";
import "./interfaces/NotifierInterface.sol";
import "./interfaces/DocumentInterface.sol";
import "./interfaces/SignaturitUserInterface.sol";
import "./interfaces/FileInterface.sol";
import "./interfaces/EventInterface.sol";
import "./interfaces/SignaturitUserInterface.sol";
import "./libraries/Utils.sol";
import "./libraries/UsingConstants.sol";


contract Signature is SignatureInterface, NotifierInterface, UsingConstants {

    address public signaturit;
    address public deployer;
    address public owner;

    string public id;

    string[] public documentsId;

    int public createdAt;

    mapping(string => DocumentInterface) private documents;

    mapping(string => address) private clauses;

    SignaturitUserInterface public userContract;

    constructor(
        string memory signatureId,
        address deployerAddress,
        int signatureCreatedAt,
        address signatureOwner,
        address userSmartContractAddress
    ) public {
        signaturit = msg.sender;
        deployer = deployerAddress;

        owner = signatureOwner;
        userContract = SignaturitUserInterface(userSmartContractAddress);

        id = signatureId;
        createdAt = signatureCreatedAt;
    }

    modifier signaturitOnly() {
        require(
            tx.origin == signaturit,
            "Only Signaturit account can perform this action"
        );

        _;
    }

    modifier ownerOnly() {
        require(
            msg.sender == owner,
            "Only the owner account can perform this action"
        );

        _;
    }

    function notify(
        uint attribute,
        address adr
    )
        public
        signaturitOnly
    {
        if (attribute == uint(enumEvents.PAYMENT_CLAUSE_CREATED)) clauses[PAYMENT_CLAUSE_KEY] = adr;
        else if (attribute == uint(enumEvents.TIMELOGGER_CLAUSE_CREATED)) clauses[TIMELOGGER_CLAUSE_KEY] = adr;
    }

    function notifyCreation()
        public
        signaturitOnly
    {
        _notifyEntityEvent(SIGNATURE_NOTIFIERS_KEY, uint(enumEvents.SIGNATURE_CREATED_EVENT), address(this));
    }

    function createDocument(
        string memory documentId,
        string memory signatureType,
        uint documentCreatedAt
    )
        public
        signaturitOnly
    {
        DocumentInterface document = _getDocument(documentId);

        document.init(signatureType, documentCreatedAt);

        documentsId.push(documentId);

        _notifyEntityEvent(DOCUMENT_NOTIFIERS_KEY, uint(enumEvents.DOCUMENT_CREATED_EVENT), address(document));
    }

    function setDocumentOwner (
        string memory documentId,
        address documentOwner
    )
        public
        signaturitOnly
    {
        DocumentInterface document = _getDocument(documentId);

        document.setOwner(documentOwner);
    }

    function setSignedFileHash (
        string memory documentId,
        string memory signedFileHash
    )
        public
        signaturitOnly
    {
        DocumentInterface document = _getDocument(documentId);

        document.setFileHash(signedFileHash);
    }

    function cancelDocument (
        string memory documentId,
        string memory cancelReason
    )
        public
        ownerOnly
    {
        DocumentInterface document = _getDocument(documentId);

        document.cancel(cancelReason);
    }

    function createFile(
        string memory documentId,
        string memory fileId,
        string memory fileName,
        string memory fileHash,
        uint fileCreatedAt,
        uint fileSize
    )
        public
        signaturitOnly
    {
        DocumentInterface document = _getDocument(documentId);

        document.
            createFile(
            fileId,
            fileName,
            fileHash,
            fileCreatedAt,
            fileSize
        );
    }

    function createEvent(
        string memory documentId,
        string memory eventId,
        string memory eventType,
        string memory eventUserAgent,
        uint eventCreatedAt
    )
        public
        signaturitOnly
    {
        DocumentInterface document = _getDocument(documentId);

        document.createEvent(
            eventId,
            eventType,
            eventUserAgent,
            eventCreatedAt
        );
    }

    function getClause(
        string memory clauseType
    )
        public
        view
        returns (address clauseAddress)
    {
        return clauses[clauseType];
    }

    function getDocument(
        string memory documentId
    )
        public
        view
        returns (address)
    {
        if (!_documentExist(documentId)) return address(0);

        return address(documents[documentId]);
    }

    function getDocumentByIndex(
        uint index
    )
        public
        view
        returns (address)
    {
        if (index > documentsId.length - 1) return address(0);

        return address(documents[documentsId[index]]);
    }

    function getDocumentsSize()
        public
        view
        returns (uint)
    {
        return documentsId.length;
    }

    function getFile(
        string memory documentId
    )
        public
        view
        returns (address)
    {
        if (!_documentExist(documentId)) return address(0);

        FileInterface signatureFile = documents[documentId].file();

        if (address(signatureFile) == address(0)) return address(0);

        return address(signatureFile);
    }

    function getEvent(
        string memory documentId,
        string memory eventId
    )
        public
        view
        returns (address)
    {
        if (!_documentExist(documentId)) return address(0);

        EventInterface signatureEvent = EventInterface(documents[documentId].getEvent(
            eventId
        ));

        if (address(signatureEvent) == address(0)) return address(0);

        return address(signatureEvent);
    }

    function _notifyEntityEvent (
        string memory notifiersKey,
        uint createdEvent,
        address adrToNotify
    )
        private
    {
        address contractToNofify;
        uint notificationIndex = 0;

        do {
            contractToNofify = userContract.getAddressArrayAttribute(notifiersKey, notificationIndex);
            ++notificationIndex;

            if (contractToNofify != address(0)) {
                contractToNofify.call(
                    abi.encodeWithSignature(
                        "notify(uint256,address)",
                        createdEvent,
                        adrToNotify
                    )
                );
            }
        } while (contractToNofify != address(0));
    }

    function _getDocument(
        string memory documentId
    )
        private
        returns (DocumentInterface)
    {
        if (_documentExist(documentId))
            return documents[documentId];

        (
            bool success,
            bytes memory returnData
        ) = deployer.delegatecall(
            abi.encodeWithSignature("deployDocument(string,address)",
            documentId,
            deployer)
        );

        require(
            success,
            "Error while deploying document"
        );

        documents[documentId] = DocumentInterface(
            Utils._bytesToAddress(returnData)
        );

        documents[documentId].setSignatureOwner(address(userContract));

        return documents[documentId];
    }

    function _documentExist(
        string memory documentId
    )
        private
        view
        returns (bool)
    {
        return address(documents[documentId]) != address(0);
    }
}
