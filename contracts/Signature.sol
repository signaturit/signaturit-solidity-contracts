pragma solidity <0.6.0;

/*
Gas to deploy: 2.882.648
*/

import "./interfaces/SignatureInterface.sol";
import "./interfaces/DocumentInterface.sol";
import "./interfaces/UserInterface.sol";
import "./interfaces/FileInterface.sol";
import "./interfaces/EventInterface.sol";
import "./libraries/Utils.sol";


contract Signature is SignatureInterface {
    address public signaturit;
    address public deployer;
    address public owner;

    string public id;

    string[] public documentsId;

    int public createdAt;

    mapping(string => DocumentInterface) private documents;

    mapping(string => address) private clauses;

    UserInterface public userSmartContract;

    constructor(
        string memory signatureId,
        address deployerAddress,
        int signatureCreatedAt
    ) public {
        signaturit = msg.sender;
        deployer = deployerAddress;

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

    function setSignatureOwner (
        address signatureOwner,
        address userSmartContractAddress
    )
        public
        signaturitOnly
    {
        owner = signatureOwner;

        userSmartContract = UserInterface(userSmartContractAddress);
        userSmartContract.addSignature(address(this), id);
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

        userSmartContract.addDocument(address(document));

        documentsId.push(documentId);
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

        userSmartContract.addFile(
            "signature",
            address(signatureFile)
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

        EventInterface signatureEvent = document.getEvent(eventId);

        require(
            address(signatureEvent) != address(0),
            "Error while retrieving event from document"
        );

        userSmartContract.addEvent("signature", address(signatureEvent));
    }

    function setClause(
        string memory clauseType,
        address clauseAddress
    )
        public
        signaturitOnly
    {
        clauses[clauseType] = clauseAddress;
    }

    function getClause(
        string memory clauseType
    )
        public
        view
        returns (address clauseAddress)
    {
        require(
            clauses[clauseType] != address(0),
            "This clause is not set"
        );

        return clauses[clauseType];
    }

    function getDocument(
        string memory documentId
    )
        public
        view
        returns (DocumentInterface)
    {
        require(
            _documentExist(documentId),
            "The document with this id doesn't exist"
        );

        return documents[documentId];
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
        returns (FileInterface)
    {
        require(
            _documentExist(documentId),
            "The document with this id doesn't exist"
        );

        FileInterface signatureFile = documents[documentId].file();

        require(
            address(signatureFile) != address(0),
            "Error while retrieving file from document"
        );

        return signatureFile;
    }

    function getEvent(
        string memory documentId,
        string memory eventId
    )
        public
        view
        returns (EventInterface)
    {
        require(
            _documentExist(documentId),
            "The document doesn't exist"
        );

        EventInterface signatureEvent = documents[documentId].getEvent(
            eventId
        );

        require(
            address(signatureEvent) != address(0),
            "Error while retrieving event from document"
        );

        return signatureEvent;
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
