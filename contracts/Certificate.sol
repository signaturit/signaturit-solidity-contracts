pragma solidity <0.6.0;

/*
Gas to deploy: 1.441.547
*/

import "./interfaces/CertificateInterface.sol";
import "./interfaces/FileInterface.sol";
import "./interfaces/EventInterface.sol";
import "./libraries/Utils.sol";


contract Certificate is CertificateInterface {
    address public certifiedEmail;
    address public owner;
    address public deployer;

    string public id;

    string[] public eventsId;

    uint public createdAt;

    FileInterface public file;

    mapping(string => EventInterface) private events;

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
}
