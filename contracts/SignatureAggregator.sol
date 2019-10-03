pragma solidity <0.6.0;

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
        bytes32 bytes32id = _keccak(id);

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

        return (
            address(signatures[signatureId]),
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
        bytes32 bytes32eventType = _keccak(eventType);

        if (_keccak(SIGNATURE_CREATED_EVENT) == bytes32eventType) {
            Signature signature = Signature(addr);

            bytes32 bytes32id = _keccak(signature.id());

            signatureIds.push(bytes32id);
            signatures[bytes32id] = signature;
        }
    }

    function _keccak (
        string memory key
    )
        private
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(key)
        );
    }
}