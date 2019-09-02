pragma solidity <0.6.0;

import "./EventInterface.sol";
import "./FileInterface.sol";


contract CertificateInterface {
    address public certifiedEmail;
    address public owner;
    address public deployer;

    string public id;

    string[] public eventsId;

    uint public createdAt;

    FileInterface public file;

    mapping(string => EventInterface) private events;

    function init(
        address certificateOwner,
        uint certificateCreatedAt
    )
        public;

    function createFile(
        string memory fileHash,
        string memory fileId,
        string memory fileName,
        uint fileCreatedAt,
        uint fileSize
    )
        public;

    function createEvent(
        string memory eventId,
        string memory eventType,
        string memory eventUserAgent,
        uint eventCreatedAt
    )
        public;

    function getEvent(
        string memory eventId
    )
        public
        view
        returns (address);

    function getEventsSize()
        public
        view
        returns (uint);
}
