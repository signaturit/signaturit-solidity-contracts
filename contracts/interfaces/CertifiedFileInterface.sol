pragma solidity <0.6.0;

import "./SignaturitUserInterface.sol";
import "./CertifiedFileCheckerInterface.sol";

contract CertifiedFileInterface {
    address public signaturit;
    address public owner;

    string public id;
    string public hash;

    uint public createdAt;
    uint public size;

    SignaturitUserInterface userContract;
}
