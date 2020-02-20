pragma solidity <0.6.0;

/*
Gas to deploy: 745.108
*/

import "./Signature.sol";
import "./BaseAggregator.sol";

contract SignatureAggregator is
    NotifierInterface,
    BaseAggregator,
    UsingConstants
{
    mapping (bytes32 => Signature) private signatures;
    
    bytes32[] private signatureIds;

    constructor (
        address _userContractAddress
    )
        public
        BaseAggregator(
            _userContractAddress,
            "signature-aggregator",
            "signature-notifiers"
        )
    {}

    function getSignatureById(
        string memory id
    )
        public
        view
        returns (address)
    {
        bytes32 bytes32id = Utils.keccak(id);

        return address(signatures[bytes32id]);
    }

    function getSignature(
        uint index
    )
        public
        view
        returns (address addr, bool more)
    {
        bool _more = index + 1 < signatureIds.length;
        if (
            index < signatureIds.length &&
            address(signatures[signatureIds[index]]) != address(0)
        ) {
            return (
                address(signatures[signatureIds[index]]),
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
        return signatureIds.length;
    }

    function notify(
        uint receivedEventType,
        address addr
    )
        public
        signaturitOnly
    {
        if (uint(enumEvents.SIGNATURE_CREATED_EVENT) == receivedEventType) {
            Signature signature = Signature(addr);

            bytes32 bytes32id = Utils.keccak(signature.id());

            signatureIds.push(bytes32id);
            signatures[bytes32id] = signature;
        }
    }
}