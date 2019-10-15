pragma solidity <0.6.0;

/*
Gas to deploy: 959.102
*/

import "./interfaces/NotifierInterface.sol";
import "./BaseAggregator.sol";
import "./Signature.sol";

contract SignatureAggregator is
    NotifierInterface,
    BaseAggregator(
        "signature-aggregator",
        "signature-notifiers"
    )
{

    string constant private SIGNATURE_CREATED_EVENT = "signature.contract.created";

    mapping (bytes32 => Signature) private signatures;
    
    bytes32[] private signatureIds;

    constructor (
        address _userContractAddress
    ) public {
        setOnUser(_userContractAddress);
    }

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
        bytes32 signatureId = signatureIds[index];

        if(address(signatures[signatureId]) != address(0)) {
            return (
                address(signatures[signatureId]),
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
        string memory eventType,
        address addr
    )
        public
        signaturitOnly
    {
        bytes32 bytes32eventType = Utils.keccak(eventType);

        if (Utils.keccak(SIGNATURE_CREATED_EVENT) == bytes32eventType) {
            Signature signature = Signature(addr);

            bytes32 bytes32id = Utils.keccak(signature.id());

            signatureIds.push(bytes32id);
            signatures[bytes32id] = signature;
        }
    }
}