pragma solidity <0.6.0;

/*
Gas to deploy: 2.882.648
*/

import "./interfaces/SignatureInterface.sol";
import "./interfaces/NotifierInterface.sol";
import "./interfaces/DocumentInterface.sol";
import "./interfaces/UserInterface.sol";
import "./interfaces/FileInterface.sol";
import "./interfaces/EventInterface.sol";
import "./interfaces/SignaturitUserInterface.sol";
import "./libraries/Utils.sol";


contract Signature is SignatureInterface, NotifierInterface {
    string constant private SIGNATURE_CREATED_EVENT = "signature.contract.created";
    string constant private DOCUMENT_CREATED_EVENT = "document.contract.created";
    string constant private FILE_CREATED_EVENT = "file.contract.created";
    string constant private EVENT_CREATED_EVENT = "event.contract.created";

    string constant private SIGNATURE_NOTIFIERS_KEY = "signature-notifiers";
    string constant private DOCUMENT_NOTIFIERS_KEY = "document-notifiers";
    string constant private FILE_NOTIFIERS_KEY = "file-notifiers";
    string constant private EVENT_NOTIFIERS_KEY = "event-notifiers";

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
        string memory attribute,
        address adr
    )
        public
        signaturitOnly
    {
        if(Utils.keccak(attribute) == Utils.keccak("payment")) clauses[attribute] = adr;
        else if(Utils.keccak(attribute) == Utils.keccak("timelogger")) clauses[attribute] = adr;
    }

    function notifyCreation()
        public
        signaturitOnly
    {
        notifyEntityEvent(SIGNATURE_NOTIFIERS_KEY, SIGNATURE_CREATED_EVENT, address(this));
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

        notifyEntityEvent(DOCUMENT_NOTIFIERS_KEY, DOCUMENT_CREATED_EVENT, address(document));
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

        FileInterface signatureFile = document.file();
        require(
            address(signatureFile) != address(0),
            "Error while retrieving file from document"
        );

        notifyEntityEvent(FILE_NOTIFIERS_KEY, FILE_CREATED_EVENT, address(signatureFile));
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

        EventInterface signatureEvent = document.getEvent(eventId);

        require(
            address(signatureEvent) != address(0),
            "Error while retrieving event from document"
        );

        notifyEntityEvent(EVENT_NOTIFIERS_KEY, EVENT_CREATED_EVENT, address(signatureEvent));
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

        EventInterface signatureEvent = documents[documentId].getEvent(
            eventId
        );

        if (address(signatureEvent) == address(0)) return address(0);

        return address(signatureEvent);
    }

    function notifyEntityEvent (
        string memory notifiersKey,
        string memory createdEvent,
        address adrToNotify
    )
        public
        signaturitOnly
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
