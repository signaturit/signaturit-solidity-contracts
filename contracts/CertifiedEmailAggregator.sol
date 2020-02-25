pragma solidity <0.6.0;

/*
Gas to deploy: 785.507
*/

import "./libraries/UsingConstants.sol";

import "./interfaces/NotifierInterface.sol";

import "./BaseAggregator.sol";
import "./CertifiedEmail.sol";

contract CertifiedEmailAggregator is
    NotifierInterface,
    BaseAggregator,
    UsingConstants
{
    mapping (bytes32 => CertifiedEmail) private certifiedEmails;
    
    bytes32[] private certifiedEmailIds;

    constructor (
        address _userContractAddress
    )
        public
        BaseAggregator(
            _userContractAddress,
            "certified-email-aggregator",
            "certified-email-notifiers"
        )
    {}

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
        if (
            index < certifiedEmailIds.length &&
            address(certifiedEmails[certifiedEmailIds[index]]) != address(0)
        ) {
            return (
                address(certifiedEmails[certifiedEmailIds[index]]),
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
        uint receivedEventType,
        address addr
    )
        public
        signaturitOnly
    {
        if (uint(enumEvents.CERTIFIED_EMAIL_CREATED_EVENT) == receivedEventType) {
            CertifiedEmail certifiedEmail = CertifiedEmail(addr);

            bytes32 bytes32id = Utils.keccak(certifiedEmail.id());

            certifiedEmailIds.push(bytes32id);
            certifiedEmails[bytes32id] = certifiedEmail;
        }
    }
}