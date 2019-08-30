pragma solidity <0.6.0;

import "./UserInterface.sol";
import "./CertifiedFileCheckerInterface.sol";

contract CertifiedFileInterface {
    CertifiedFileCheckerInterface public certifiedFileChecker;

    address public signaturit;
    address public owner;

    string public id;
    string public name;
    string public hash;

    uint public createdAt;
    uint public size;

    UserInterface public userSmartContract;

    function notify(
        address certifiedFileCheckerAddress
    ) 
        public;
}
