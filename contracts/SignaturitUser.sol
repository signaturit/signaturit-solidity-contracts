pragma solidity <0.6.0;

import "./interfaces/SignaturitUserInterface.sol";
import "./libraries/Utils.sol";

/*
Gas to deploy: 1.925.304
*/

contract SignaturitUser is SignaturitUserInterface {
    address public rootAddress;
    address public ownerAddress;

    mapping (bytes32 => string) public stringAttr;
    mapping (bytes32 => string[]) private stringArrayAttr;
    mapping (bytes32 => int) public numberAttr;
    mapping (bytes32 => int[]) public numberArrayAttr;
    mapping (bytes32 => address) public addressAttr;
    mapping (bytes32 => address[]) public addressArrayAttr;
    mapping (bytes32 => bool) public boolAttr;
    mapping (bytes32 => bool[]) public boolArrayAttr;

    constructor (
        address _ownerAddress
    ) public {
        rootAddress = msg.sender;
        ownerAddress = _ownerAddress;
    }

    modifier protected() {
        require(
            tx.origin == rootAddress,
            "Only the owner can perform this action"
        );

        _;
    }

    function setStringAttribute (
        string memory key,
        string memory value
    )
        public
        protected
    {
        bytes32 bytes32key = Utils.keccak(key);

        stringAttr[bytes32key] = value;
    }

    function deleteStringAttribute (
        string memory key
    )
        public
        protected
    {
        bytes32 bytes32key = Utils.keccak(key);

        stringAttr[bytes32key] = "";
    }

    function getStringAttribute (
        string memory key
    )
        public
        view
        returns (string memory)
    {
        bytes32 bytes32key = Utils.keccak(key);

        return stringAttr[bytes32key];
    }

    function setStringArrayAttribute (
        string memory key,
        string memory value
    )
        public
        protected
    {
        bytes32 bytes32key = Utils.keccak(key);
        stringArrayAttr[bytes32key].push(value);
    }

    function deleteStringArrayAttribute (
        string memory key,
        uint index
    )
        public
        protected
    {
        bytes32 bytes32key = Utils.keccak(key);
        uint arrayLength = stringArrayAttr[bytes32key].length;

        if (index >= arrayLength) return;

        for (uint i = index; i < arrayLength - 1; i++){
            stringArrayAttr[bytes32key][i] = stringArrayAttr[bytes32key][i+1];
        }

        stringArrayAttr[bytes32key].length--;
    }

    function getStringArrayAttribute (
        string memory key,
        uint index
    )
        public
        view
        returns (string memory)
    {
        bytes32 bytes32key = Utils.keccak(key);

        if (stringArrayAttr[bytes32key].length > index) {
            return stringArrayAttr[bytes32key][index];
        }

        return "";
    }

    function setNumberAttribute (
        string memory key,
        int value
    )
        public
        protected
    {
        bytes32 bytes32key = Utils.keccak(key);
        numberAttr[bytes32key] = value;
    }

    function deleteNumberAttribute (
        string memory key
    )
        public
        protected
    {
        bytes32 bytes32key = Utils.keccak(key);
        numberAttr[bytes32key] = 0;
    }

    function getNumberAttribute (
        string memory key
    )
        public
        view
        returns (int)
    {
        bytes32 bytes32key = Utils.keccak(key);

        return numberAttr[bytes32key];
    }

    function setNumberArrayAttribute (
        string memory key,
        int value
    )
        public
        protected
    {
        bytes32 bytes32key = Utils.keccak(key);
        numberArrayAttr[bytes32key].push(value);
    }

    function deleteNumberArrayAttribute (
        string memory key,
        uint index
    )
        public
        protected
    {
        bytes32 bytes32key = Utils.keccak(key);
        uint arrayLength = numberArrayAttr[bytes32key].length;

        if (index >= arrayLength) return;

        for (uint i = index; i < arrayLength - 1; i++){
            numberArrayAttr[bytes32key][i] = numberArrayAttr[bytes32key][i+1];
        }

        numberArrayAttr[bytes32key].length--;
    }

    function getNumberArrayAttribute (
        string memory key,
        uint index
    )
        public
        view
        returns (int)
    {
        bytes32 bytes32key = Utils.keccak(key);

        if (numberArrayAttr[bytes32key].length > index) {
            return numberArrayAttr[bytes32key][index];
        }

        return 0;
    }

    function setAddressAttribute (
        string memory key,
        address value
    )
        public
        protected
    {
        bytes32 bytes32key = Utils.keccak(key);

        addressAttr[bytes32key] = value;
    }

    function deleteAddressAttribute (
        string memory key
    )
        public
        protected
    {
        bytes32 bytes32key = Utils.keccak(key);

        addressAttr[bytes32key] = address(0);
    }

    function getAddressAttribute (
        string memory key
    )
        public
        view
        returns (address)
    {
        bytes32 bytes32key = Utils.keccak(key);

        return addressAttr[bytes32key];
    }

    function setAddressArrayAttribute (
        string memory key,
        address value
    )
        public
        protected
    {
        bytes32 bytes32key = Utils.keccak(key);
        addressArrayAttr[bytes32key].push(value);
    }

    function deleteAddressArrayAttribute (
        string memory key,
        uint index
    )
        public
        protected
    {
        bytes32 bytes32key = Utils.keccak(key);
        uint arrayLength = addressArrayAttr[bytes32key].length;

        if (index >= arrayLength) return;

        for (uint i = index; i < arrayLength - 1; i++){
            addressArrayAttr[bytes32key][i] = addressArrayAttr[bytes32key][i+1];
        }

        addressArrayAttr[bytes32key].length--;
    }

    function getAddressArrayAttribute (
        string memory key,
        uint index
    )
        public
        view
        returns (address)
    {
        bytes32 bytes32key = Utils.keccak(key);

        if (addressArrayAttr[bytes32key].length > index) {
            return addressArrayAttr[bytes32key][index];
        }

        return address(0);
    }

    function setBooleanAttribute (
        string memory key,
        bool value
    )
        public
        protected
    {
        bytes32 bytes32key = Utils.keccak(key);

        boolAttr[bytes32key] = value;
    }

    function deleteBooleanAttribute (
        string memory key
    )
        public
        protected
    {
        bytes32 bytes32key = Utils.keccak(key);

        boolAttr[bytes32key] = false;
    }

    function getBooleanAttribute (
        string memory key
    )
        public
        view
        returns (bool)
    {
        bytes32 bytes32key = Utils.keccak(key);

        return boolAttr[bytes32key];
    }

    function setBooleanArrayAttribute (
        string memory key,
        bool value
    )
        public
        protected
    {
        bytes32 bytes32key = Utils.keccak(key);
        boolArrayAttr[bytes32key].push(value);
    }

    function getBooleanArrayAttribute (
        string memory key,
        uint index
    )
        public
        view
        returns (bool)
    {
        bytes32 bytes32key = Utils.keccak(key);

        if (boolArrayAttr[bytes32key].length > index) {
            return boolArrayAttr[bytes32key][index];
        }

        return false;
    }

    function deleteBooleanArrayAttribute (
        string memory key,
        uint index
    )
        public
        protected
    {
        bytes32 bytes32key = Utils.keccak(key);
        uint arrayLength = boolArrayAttr[bytes32key].length;

        if (index >= arrayLength) return;

        for (uint i = index; i < arrayLength - 1; i++){
            boolArrayAttr[bytes32key][i] = boolArrayAttr[bytes32key][i+1];
        }

        boolArrayAttr[bytes32key].length--;
    }
}