pragma solidity <0.6.0;

import "./DocumentInterface.sol";
import "./SignaturitUserInterface.sol";


contract SignatureInterface {
    address public signaturit;
    address public deployer;
    address public owner;

    string public id;

    string[] public documentsId;

    int public createdAt;

    mapping(string => DocumentInterface) private documents;

    mapping(string => address) private clauses;

    SignaturitUserInterface public userContract;

    function notify(
        uint attribute,
        address adr
    )
        public;
    
    function notifyCreation()
        public;

    function createDocument(
        string memory documentId,
        string memory signatureType,
        uint documentCreatedAt
    )
        public;

    function setDocumentOwner(
        string memory documentId,
        address documentOwner
    )
        public;

    function setSignedFileHash(
        string memory documentId,
        string memory signedFileHash
    )
        public;

    function cancelDocument(
        string memory documentId,
        string memory cancelReason
    )
        public;

    function signDocument (
        string memory documentId,
        uint signedAt
    )
        public;

    function createFile(
        string memory documentId,
        string memory fileId,
        string memory fileName,
        string memory fileHash,
        uint fileCreatedAt,
        uint fileSize
    )
        public;

    function createEvent(
        string memory documentId,
        string memory eventId,
        string memory eventType,
        string memory eventUserAgent,
        uint eventCreatedAt
    )
        public;

    function getClause(
        string memory clauseType
    )
        public
        view
        returns (address clauseAddress);

    function getFile(
        string memory documentId
    )
        public
        view
        returns (address);

    function getDocument(
        string memory documentId
    )
        public
        view
        returns (address);

    function getDocumentByIndex(
        uint index
    )
        public
        view
        returns (address);

    function getDocumentsSize()
        public
        view
        returns (uint);

    function getEvent(
        string memory documentId,
        string memory eventId
    )
        public
        view
        returns (address);

    function _notifyEntityEvent (
        string memory notifiersKey,
        uint createdEvent,
        address adrToNotify
    )
        private;

    function _getDocument(
        string memory documentId
    )
        private
        returns (DocumentInterface);

    function _documentExist(
        string memory documentId
    )
        private
        view
        returns (bool);
}
