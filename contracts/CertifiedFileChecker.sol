pragma solidity <0.6.0;

/*
Gas to deploy: 894.726
*/

import "./interfaces/CertifiedFileInterface.sol";
import "./interfaces/CertifiedFileCheckerInterface.sol";


contract CertifiedFileChecker is CertifiedFileCheckerInterface {
    address public signaturit;

    string constant private CERTIFIED_FILE_CREATED_EVENT = "certified_file.contract.created";

    struct CertifiedFilesWithHash {
        bool exist;
        CertifiedFileInterface[] files;
    }

    mapping(bytes32 => CertifiedFilesWithHash) private certifiedFiles;

    modifier signaturitOnly() {
        require(
            tx.origin == signaturit,
            "Only Signaturit account can perform this action"
        );

        _;
    }

    constructor() public {
        signaturit = msg.sender;
    }

    function getFile(
        string memory fileHash,
        uint index
    ) public view returns(
        string memory id,
        string memory hash,
        uint size,
        uint createdAt,
        address  owner,
        address contract_address,
        bool more
    ) {
        bytes32 hashConverted = _keccak(fileHash);

        if (
            certifiedFiles[hashConverted].exist &&
            certifiedFiles[hashConverted].files.length > index
        ) {
            bool foundMore = certifiedFiles[hashConverted].files.length > (index + 1) ? true : false;
            CertifiedFileInterface certifiedFile = certifiedFiles[hashConverted].files[index];

            return (
                certifiedFile.id(),
                certifiedFile.hash(),
                certifiedFile.size(),
                certifiedFile.createdAt(),
                certifiedFile.owner(),
                address(certifiedFile),
                foundMore
            );
        }

        return (
            "",
            "",
            0,
            0,
            address(0),
            address(0),
            false
        );
    }

    function notify(
        string memory eventType,
        address certifiedFileAddress
    ) public signaturitOnly {
        bytes32 bytes32eventType = _keccak(eventType);

        if (_keccak(CERTIFIED_FILE_CREATED_EVENT) == bytes32eventType) {
            CertifiedFileInterface cerfiedFile = CertifiedFileInterface(certifiedFileAddress);
            bytes32 hashConverted = _keccak(cerfiedFile.hash());

            if (!certifiedFiles[hashConverted].exist) certifiedFiles[hashConverted].exist = true;

            certifiedFiles[hashConverted].files.push(cerfiedFile);
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
