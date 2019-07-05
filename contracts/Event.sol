pragma solidity 0.5.0;

/*Gas to deploy: 661.223*/

import "./interfaces/EventInterface.sol";


contract Event is EventInterface {
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
        id = eventId;
        eventType = initType;
        userAgent = eventUserAgent;
        createdAt = eventCreatedAt;
    }
}
