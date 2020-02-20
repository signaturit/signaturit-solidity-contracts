pragma solidity <0.6.0;

/*
Gas to deploy: 2.094.931
*/

import "./interfaces/DocumentInterface.sol";
import "./interfaces/FileInterface.sol";
import "./interfaces/EventInterface.sol";
import "./interfaces/SignaturitUserInterface.sol";
import "./libraries/Utils.sol";
import "./libraries/UsingConstants.sol";


contract Document is DocumentInterface, UsingConstants {

    string constant private ID_DOCUMENT_SIGNED = "id_document_signed";
    string constant private ID_FILE_SIGNED_HASH = "id_file_signed_hash";
    string constant private ID_DOCUMENT_DECLINED = "id_document_declined";
    string constant private ID_DOCUMENT_CANCELED = "id_document_canceled";

    address public signature;
    address public signer;
    address public deployer;

    string public id;
    string public cancelReason;
    string public signatureType;
    string public declineReason;
    string public signedFileHash;

    string[] public eventsId;

    uint public signedAt;
    uint public createdAt;

    bool public signed;
    bool public canceled;
    bool public declined;

    FileInterface public file;

    SignaturitUserInterface public signatureOwner;

    mapping(string => EventInterface) private events;

    constructor(
        string memory documentId,
        address signatureDeployer
    ) public {
        signature = msg.sender;
        deployer = signatureDeployer;
        id = documentId;
    }

    modifier protected() {
        require(
            msg.sender == signature || msg.sender == signer,
            "Only the Signature account can perform this action"
        );

        _;
    }

    modifier signerOnly() {
        require(
            msg.sender == signer,
            "Only the owner account can perform this action"
        );

        _;
    }

    function init(
        string memory initType,
        uint documentCreatedAt
    )
        public
        protected
    {
        signatureType = initType;
        createdAt = documentCreatedAt;
    }

    function setSignatureOwner(
        address signatureOwnerAdr
    )
        public
        protected
    {
        signatureOwner = SignaturitUserInterface(signatureOwnerAdr);
    }

    function setOwner(
        address signerAddress
    )
        public
        protected
    {
        signer = signerAddress;
    }

    function sign(
        uint documentSignedAt
    )
        public
        signerOnly
    {
        require(
            !declined || !canceled,
            "Document is already declined or canceled, you can't sign it"
        );

        signedAt = documentSignedAt;

        signed = true;
            
        createEvent(
            ID_DOCUMENT_SIGNED,
            "document-signed",
            SOLIDITY_SOURCE,
            block.timestamp
        );
    }

    function decline(
        string memory documentDeclineReason
    )
        public
        signerOnly
    {
        require(
            !signed,
            "Document is already signed, you can't decline it"
        );

        declineReason = documentDeclineReason;

        declined = true;

        createEvent(
            ID_DOCUMENT_DECLINED,
            "document-declined",
            SOLIDITY_SOURCE,
            block.timestamp
        );
    }

    function cancel(
        string memory documentCancelReason
    )
        public
        protected
    {
        require(
            !signed,
            "Document is already signed, you can't cancel it"
        );

        cancelReason = documentCancelReason;

        canceled = true;

        createEvent(
            ID_DOCUMENT_CANCELED,
            "document-canceled",
            SOLIDITY_SOURCE,
            block.timestamp
        );
    }

    function createFile(
        string memory fileId,
        string memory fileName,
        string memory fileHash,
        uint fileCreatedAt,
        uint fileSize
    )
        public
        protected
    {
        (bool success, bytes memory returnData) = deployer.delegatecall(
            abi.encodeWithSignature(
                "deployFile(string)",
                fileId
            )
        );

        require(
            success,
            "Error while deploying file from document"
        );

        file = FileInterface(Utils._bytesToAddress(returnData));

        file.init(
                fileName,
                fileHash,
                fileCreatedAt,
                fileSize
        );

        notifyEntityEvent(FILE_NOTIFIERS_KEY, uint(enumEvents.FILE_CREATED_EVENT), address(file));
    }

    function setFileHash(
        string memory fileHash
    )
        public
        protected
    {
        signedFileHash = fileHash;

        createEvent(
            ID_FILE_SIGNED_HASH,
            "file-signed-hash",
            SOLIDITY_SOURCE,
            block.timestamp
        );
    }

    function createEvent(
        string memory eventId,
        string memory eventType,
        string memory eventUserAgent,
        uint eventCreatedAt
    )
        public
        protected
    {
        (bool success, bytes memory returnData) = deployer.delegatecall(
            abi.encodeWithSignature(
                "deployEvent(string,string,string,uint256)",
                eventId,
                eventType,
                eventUserAgent,
                eventCreatedAt
            )
        );

        require(
            success,
            "Error while deploying event from document"
        );

        events[eventId] = EventInterface(Utils._bytesToAddress(returnData));

        eventsId.push(eventId);

        notifyEntityEvent(EVENT_NOTIFIERS_KEY, uint(enumEvents.EVENT_CREATED_EVENT), address(events[eventId]));
    }

    function notifyEntityEvent (
        string memory notifiersKey,
        uint createdEvent,
        address adrToNotify
    )
        internal
    {
        address contractToNofify;
        uint notificationIndex = 0;

        do {
            contractToNofify = signatureOwner.getAddressArrayAttribute(notifiersKey, notificationIndex);
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

    function getEvent(
        string memory eventId
    )
        public
        view
        returns (address)
    {
        require(
            address(events[eventId]) != address(0),
            "The event doesn't exist"
        );

        return address(events[eventId]);
    }

    function getEventsSize()
        public
        view
        returns (uint)
    {
        return eventsId.length;
    }
}
