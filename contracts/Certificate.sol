pragma solidity <0.6.0;

/*
Gas to deploy: 1.700.561
*/

import "./interfaces/CertificateInterface.sol";
import "./interfaces/SignaturitUserInterface.sol";

import "./libraries/Utils.sol";
import "./libraries/UsingConstants.sol";

contract Certificate is CertificateInterface, UsingConstants {
    address public certifiedEmail;
    address public owner;
    address public deployer;

    string public id;

    string[] public eventsId;

    uint public createdAt;

    FileInterface public file;

    mapping(string => EventInterface) private events;

    SignaturitUserInterface public certifiedEmailOwner;

    constructor(
        string memory certificateId,
        address certifiedEmailDeployer
    ) public {
        id = certificateId;
        deployer = certifiedEmailDeployer;
        certifiedEmail = msg.sender;
    }

    modifier certifiedEmailModifier() {
        require(
            msg.sender == certifiedEmail,
            "Only CertifiedEmail account can perform this action"
        );

        _;
    }

    function init(
        address certificateOwner,
        uint certificateCreatedAt
    )
        public
        certifiedEmailModifier
    {
        owner = certificateOwner;
        createdAt = certificateCreatedAt;
    }

    function setCertifiedEmailOwner(
        address certifiedEmailOwnerAdr
    )
        public
        certifiedEmailModifier
    {
        certifiedEmailOwner = SignaturitUserInterface(certifiedEmailOwnerAdr);
    }

    function createFile(
        string memory fileHash,
        string memory fileId,
        string memory fileName,
        uint fileCreatedAt,
        uint fileSize
    )
        public
        certifiedEmailModifier
    {
        (bool success, bytes memory returnData) = deployer.delegatecall(
            abi.encodeWithSignature(
                "deployFile(string)",
                fileId
            )
        );

        require(
            success,
            "Error while deploying file from certificate"
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

    function createEvent(
        string memory eventId,
        string memory eventType,
        string memory eventUserAgent,
        uint eventCreatedAt
    )
        public
        certifiedEmailModifier
    {
        require(
            address(events[eventId]) == address(0),
            "The current event already exists"
        );

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
            "Error while deploying event from certificate"
        );

        events[eventId] = EventInterface(Utils._bytesToAddress(returnData));

        eventsId.push(eventId);

        notifyEntityEvent(EVENT_NOTIFIERS_KEY, uint(enumEvents.EVENT_CREATED_EVENT), address(events[eventId]));
    }

    function getEvent(
        string memory eventId
    )
        public
        view
        returns (address)
    {
        if (address(events[eventId]) == address(0)) return address(0);

        return address(events[eventId]);
    }

    function getEventsSize()
        public
        view
        returns (uint)
    {
        return eventsId.length;
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
            contractToNofify = certifiedEmailOwner.getAddressArrayAttribute(notifiersKey, notificationIndex);
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

}
