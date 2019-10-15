pragma solidity <0.6.0;

/*
Gas to deploy: 959.102
*/

import "./interfaces/NotifierInterface.sol";
import "./BaseAggregator.sol";
import "./CertifiedEmail.sol";

contract CertifiedEmailAggregator is
    NotifierInterface,
    BaseAggregator(
        "certified-email-aggregator",
        "certified-email-notifiers"
    )
{
    string constant private CERTIFIED_EMAIL_CREATED_EVENT = "certified_email.contract.created";

    mapping (bytes32 => CertifiedEmail) private certifiedEmails;
    
    bytes32[] private certifiedEmailIds;

    constructor (
        address _userContractAddress
    ) public {
        setOnUser(_userContractAddress);
    }

    function getCertifiedEmailById(
        string memory id
    )
        public
        view
        returns (address)
    {
        bytes32 bytes32id = Utils.keccak(id);

        return address(certifiedEmails[bytes32id]);
    }

    function getCertifiedEmail(
        uint index
    )
        public
        view
        returns (address addr, bool more)
    {
        bool _more = index + 1 < certifiedEmailIds.length;
        bytes32 certifiedEmailId = certifiedEmailIds[index];

        if (address(certifiedEmails[certifiedEmailId]) != address(0)) {
            return (
                address(certifiedEmails[certifiedEmailId]),
                _more
            );
        }

        return (
            address(0),
            _more
        );
    }

    function count()
        public
        view
        returns (uint)
    {
        return certifiedEmailIds.length;
    }

    function notify(
        string memory eventType,
        address addr
    )
        public
        signaturitOnly
    {
        bytes32 bytes32eventType = Utils.keccak(eventType);

        if (Utils.keccak(CERTIFIED_EMAIL_CREATED_EVENT) == bytes32eventType) {
            CertifiedEmail certifiedEmail = CertifiedEmail(addr);

            bytes32 bytes32id = Utils.keccak(certifiedEmail.id());

            certifiedEmailIds.push(bytes32id);
            certifiedEmails[bytes32id] = certifiedEmail;
        }
    }
}