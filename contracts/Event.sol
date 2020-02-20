pragma solidity <0.6.0;

/*
Gas to deploy: 422.365
*/

import "./interfaces/EventInterface.sol";


contract Event is EventInterface {
    address public parent;

    string public id;
    string public evenType;
    string public userAgent;

    uint public createdAt;

    constructor(
        string memory eventId,
        string memory initType,
        string memory eventUserAgent,
        uint eventCreatedAt
    )
        public
    {
        parent = msg.sender;
        
        id = eventId;
        eventType = initType;
        userAgent = eventUserAgent;
        createdAt = eventCreatedAt;
    }
}
