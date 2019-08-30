pragma solidity <0.6.0;

/*
Gas to deploy: 894.726
*/

import "./interfaces/CertifiedFileInterface.sol";
import "./interfaces/CertifiedFileCheckerInterface.sol";

contract CertifiedFileChecker is CertifiedFileCheckerInterface {

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

    function addFile(
        address certifiedFileAddress
    ) public signaturitOnly {
        CertifiedFileInterface cerfiedFile = CertifiedFileInterface(certifiedFileAddress);

        bytes32 hashConverted = keccak256(
            abi.encodePacked(cerfiedFile.hash())
        );

        if (!certifiedFiles[hashConverted].exist) certifiedFiles[hashConverted].exist = true;

        certifiedFiles[hashConverted].files.push(cerfiedFile);
    }

    function getFile(
        string memory fileHash,
        uint index
    ) public view returns(
        string memory id,
        string memory name,
        string memory hash,
        uint size,
        uint createdAt,
        address  owner,
        bool more
    ) {
        bytes32 hashConverted = keccak256(
            abi.encodePacked(fileHash)
        );

        if (
            certifiedFiles[hashConverted].exist &&
            certifiedFiles[hashConverted].files.length > index
        ) {
            bool foundMore = certifiedFiles[hashConverted].files.length > (index + 1) ? true : false;
            return (
                certifiedFiles[hashConverted].files[index].id(),
                certifiedFiles[hashConverted].files[index].name(),
                certifiedFiles[hashConverted].files[index].hash(),
                certifiedFiles[hashConverted].files[index].size(),
                certifiedFiles[hashConverted].files[index].createdAt(),
                certifiedFiles[hashConverted].files[index].owner(),
                foundMore
            );
        }

        return (
            "",
            "",
            "",
            0,
            0,
            address(0),
            false
        );
    }
}
