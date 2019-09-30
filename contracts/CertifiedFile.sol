pragma solidity <0.6.0;

/*
Gas to deploy: 655.214
*/

import "./interfaces/CertifiedFileInterface.sol";


contract CertifiedFile is CertifiedFileInterface {
    CertifiedFileCheckerInterface public certifiedFileChecker;

    address public signaturit;
    address public owner;

    string public id;
    string public name;
    string public hash;

    uint public createdAt;
    uint public size;

    UserInterface public userSmartContract;

    modifier signaturitOnly() {
        require(
            msg.sender == signaturit,
            "Only Signaturit account can perform this action"
        );

        _;
    }

    constructor(
        address fileOwner,
        address userSmartContractAddress,
        string memory fileId,
        string memory fileName,
        string memory fileHash,
        uint fileCreatedAt,
        uint fileSize
    )
        public
    {
        id = fileId;
        name = fileName;
        hash = fileHash;
        size = fileSize;
        createdAt = fileCreatedAt;
        signaturit = msg.sender;
        owner = fileOwner;
        userSmartContract = UserInterface(userSmartContractAddress);

        userSmartContract.addCertifiedFile(address(this), id);
    }

    function notify(
        address certifiedFileCheckerAddress
    )
        public
        signaturitOnly
    {
        certifiedFileChecker = CertifiedFileCheckerInterface(certifiedFileCheckerAddress);

        certifiedFileChecker.addFile(address(this));
    }
}
