pragma solidity <0.6.0;

import "./interfaces/NotifierInterface.sol";
import "./interfaces/SignaturitUserInterface.sol";
import "./CertifiedFile.sol";

contract CertifiedFileAggregator is NotifierInterface {
    SignaturitUserInterface userContract;

    address signaturit;

    string constant AGGREGATOR_NAME = 'certified-file-aggregator';
    string constant NOTIFICATION_EVENT = 'certified-file-nofify';
    string constant CERTIFIED_FILE_CREATED_EVENT = 'certified_file.contract.created';

    mapping (bytes32 => CertifiedFile) certifiedFiles;
    
    bytes32[] certifiedFilesIds;

    modifier signaturitOnly () {
        require(
            tx.origin == signaturit,
            "Only Signaturit account can perform this action"
        );

        _;
    }
    constructor (
        address _userContractAddress
    ) public {
        signaturit = msg.sender;

        userContract = SignaturitUserInterface(_userContractAddress);

        userContract.setAddressAttribute(
            AGGREGATOR_NAME,
            address(this)
        );

        userContract.setAddressArrayAttribute(
            NOTIFICATION_EVENT,
            address(this)
        );
    }

    function getCertifiedFileById(
        string memory id
    )
        public
        view
        returns (address)
    {
        bytes32 bytes32id = _keccak(id);

        return address(certifiedFiles[bytes32id]);
    }

    function getCertifiedFile(
        uint index
    )
        public
        view
        returns (address addr, bool more)
    {
        bool _more = index + 1 < certifiedFilesIds.length;
        bytes32 certifiedFileId = certifiedFilesIds[index];

        return (
            address(certifiedFiles[certifiedFileId]),
            _more
        );
    }

    function count()
        public
        view
        returns (uint)
    {
        return certifiedFilesIds.length;
    }

    function notify(
        string memory eventType,
        address addr
    )
        public
        signaturitOnly
    {
        bytes32 bytes32eventType = _keccak(eventType);

        if (_keccak(CERTIFIED_FILE_CREATED_EVENT) == bytes32eventType) {
            CertifiedFile certifiedFile = CertifiedFile(addr);

            bytes32 bytes32id = _keccak(certifiedFile.id());

            certifiedFilesIds.push(bytes32id);
            certifiedFiles[bytes32id] = certifiedFile;
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