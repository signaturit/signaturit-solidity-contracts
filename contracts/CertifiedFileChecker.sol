pragma solidity <0.6.0;

/*
Gas to deploy: 676.562
*/

import "./interfaces/CertifiedFileInterface.sol";
import "./interfaces/CertifiedFileCheckerInterface.sol";
import "./libraries/Utils.sol";
import "./libraries/UsingConstants.sol";


contract CertifiedFileChecker is CertifiedFileCheckerInterface, UsingConstants {
    address public signaturit;

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
        bytes32 hashConverted = Utils.keccak(fileHash);

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
        uint receivedEventType,
        address certifiedFileAddress
    ) public signaturitOnly {

        if (uint(enumEvents.CERTIFIED_FILE_CREATED_EVENT) == receivedEventType) {
            CertifiedFileInterface cerfiedFile = CertifiedFileInterface(certifiedFileAddress);
            bytes32 hashConverted = Utils.keccak(cerfiedFile.hash());

            if (!certifiedFiles[hashConverted].exist) certifiedFiles[hashConverted].exist = true;

            certifiedFiles[hashConverted].files.push(cerfiedFile);
        }
    }
}
