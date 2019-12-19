pragma solidity <0.6.0;

/*
Gas to deploy: 3.365.936
*/

import "./File.sol";
import "./Document.sol";
import "./Event.sol";


contract SignatureDeployer {

    constructor() public {}

    function deployFile(
        string memory fileId
    )
        public
        returns (address)
    {
        return address(new File(fileId));
    }

    function deployDocument(
        string memory documentId,
        address deployer
    )
        public
        returns (address)
    {
        return address(new Document(documentId, deployer));
    }

    function deployEvent(
        string memory eventId,
        string memory eventType,
        string memory eventUserAgent,
        uint eventCreatedAt
    )
        public
        returns (address)
    {
        return address(
            new Event(
                eventId,
                eventType,
                eventUserAgent,
                eventCreatedAt
            )
        );
    }
}
