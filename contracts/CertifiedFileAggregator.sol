pragma solidity <0.6.0;

import "./interfaces/NotifierInterface.sol";
import "./BaseAggregator.sol";
import "./CertifiedFile.sol";
import "./libraries/Utils.sol";

contract CertifiedFileAggregator is
    NotifierInterface,
    BaseAggregator
{
    string constant private CERTIFIED_FILE_CREATED_EVENT = "certified_file.contract.created";

    mapping (bytes32 => CertifiedFile) private certifiedFiles;

    bytes32[] private certifiedFilesIds;

    constructor (
        address _userContractAddress
    )
        public
        BaseAggregator(
            _userContractAddress,
            "certified-file-aggregator",
            "certified-file-notifiers"
        )
    {}

    function getCertifiedFileById(
        string memory id
    )
        public
        view
        returns (address)
    {
        bytes32 bytes32id = Utils.keccak(id);

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
        if(address(certifiedFiles[certifiedFileId]) != address(0)) {
            return (
                address(certifiedFiles[certifiedFileId]),
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
        return certifiedFilesIds.length;
    }

    function notify(
        string memory eventType,
        address addr
    )
        public
        signaturitOnly
    {
        bytes32 bytes32eventType = Utils.keccak(eventType);

        if (Utils.keccak(CERTIFIED_FILE_CREATED_EVENT) == bytes32eventType) {
            CertifiedFile certifiedFile = CertifiedFile(addr);

            bytes32 bytes32id = Utils.keccak(certifiedFile.id());

            certifiedFilesIds.push(bytes32id);
            certifiedFiles[bytes32id] = certifiedFile;
        }
    }
}