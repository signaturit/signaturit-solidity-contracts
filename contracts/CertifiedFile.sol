pragma solidity <0.6.0;

/*
Gas to deploy: 658.778
*/

import "./interfaces/CertifiedFileInterface.sol";
import "./interfaces/UserInterface.sol";


contract CertifiedFile is CertifiedFileInterface {
    address public signaturit;
    address public owner;

    string public id;
    string public name;
    string public hash;

    uint public createdAt;
    uint public size;

    UserInterface public userSmartContract;

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
        userSmartContract.addCertifiedFile(address(this), fileId);
    }
}
