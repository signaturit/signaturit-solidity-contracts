pragma solidity <0.6.0;

/*
Gas to deploy: 1.949.100
*/

import "./interfaces/DocumentInterface.sol";
import "./libraries/Utils.sol";


contract Document is DocumentInterface {
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

    mapping(string => EventInterface) private events;

    constructor(
        string memory documentId,
        address signatureDeployer
    ) public {
        signature = msg.sender;
        deployer = signatureDeployer;
        id = documentId;
    }

    modifier signatureOnly() {
        require(
            msg.sender == signature,
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
        signatureOnly
    {
        signatureType = initType;
        createdAt = documentCreatedAt;
    }

    function setOwner(
        address signerAddress
    )
        public
        signatureOnly
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
    }

    function cancel(
        string memory documentCancelReason
    )
        public
        signatureOnly
    {
        require(
            !signed,
            "Document is already signed, you can't cancel it"
        );

        cancelReason = documentCancelReason;

        canceled = true;
    }

    function createFile(
        string memory fileId,
        string memory fileName,
        string memory fileHash,
        uint fileCreatedAt,
        uint fileSize
    )
        public
        signatureOnly
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
    }

    function setFileHash(
        string memory fileHash
    )
        public
        signatureOnly
    {
        signedFileHash = fileHash;
    }

    function createEvent(
        string memory eventId,
        string memory eventType,
        string memory eventUserAgent,
        uint eventCreatedAt
    )
        public
        signatureOnly
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
    }

    function getEvent(
        string memory eventId
    )
        public
        view
        returns (EventInterface)
    {
        require(
            address(events[eventId]) != address(0),
            "The event doesn't exist"
        );

        return events[eventId];
    }

    function getEventsSize()
        public
        view
        returns (uint)
    {
        return eventsId.length;
    }
}
