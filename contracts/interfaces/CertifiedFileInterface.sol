pragma solidity <0.6.0;

import "./UserInterface.sol";


contract CertifiedFileInterface {
    address public signaturit;
    address public owner;

    string public id;
    string public name;
    string public hash;

    uint public createdAt;
    uint public size;

    UserInterface public userSmartContract;
}
