pragma solidity <0.6.0;

/*
Gas to deploy: 2.712.304
*/

import "./File.sol";
import "./Certificate.sol";
import "./Event.sol";


contract CertifiedEmailDeployer {

    constructor() public {}

    function deployFile(
        string memory fileId
    )
        public
        returns (address)
    {
        return address(new File(fileId));
    }

    function deployCertificate(
        string memory certificateId,
        address deployer
    )
        public
        returns (address)
    {
        return address(new Certificate(certificateId, deployer));
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
