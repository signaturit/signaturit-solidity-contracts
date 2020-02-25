pragma solidity <0.6.0;

contract SignaturitUserInterface {
    address public rootAddress;
    address public ownerAddress;

    mapping (bytes32 => string) private stringAttr;
    mapping (bytes32 => string[]) private stringArrayAttr;
    mapping (bytes32 => int) private numberAttr;
    mapping (bytes32 => int[]) private numberArrayAttr;
    mapping (bytes32 => address) private addressAttr;
    mapping (bytes32 => address[]) private addressArrayAttr;
    mapping (bytes32 => bool) private boolAttr;
    mapping (bytes32 => bool[]) private boolArrayAttr;

    mapping(bytes32 => mapping(address => bool)) private mappingAddressBool;

    function setMappingAddressBool(
        string memory key,
        address adr,
        bool value
    )
        public;

    function getMappingAddressBool(
        string memory key,
        address adr
    )
        public view returns(bool);

    function setStringAttribute (
        string memory key,
        string memory value
    ) public;

    function getStringAttribute (
        string memory key
    ) public view returns (string memory);

    function setStringArrayAttribute (
        string memory key,
        string memory value
    ) public;

    function getStringArrayAttribute (
        string memory key,
        uint index
    ) public view returns (string memory);

    function setNumberAttribute (
        string memory key,
        int value
    ) public;

    function getNumberAttribute (
        string memory key
     ) public view returns (int);

    function setNumberArrayAttribute (
        string memory key,
        int value
    ) public;

    function getNumberArrayAttribute (
        string memory key,
        uint index
    ) public view returns (int);

    function setAddressAttribute (
        string memory key,
        address value
    ) public;

    function getAddressAttribute (
        string memory key
    ) public view returns (address);

    function setAddressArrayAttribute (
        string memory key,
        address value
    ) public;

    function getAddressArrayAttribute (
        string memory key,
        uint index
    ) public view returns (address);

    function setBooleanAttribute (
        string memory key,
        bool value
    ) public;

    function getBooleanAttribute (
        string memory key
    ) public view returns (bool);

    function setBooleanArrayAttribute (
        string memory key,
        bool value
    ) public;

    function getBooleanArrayAttribute (
        string memory key,
        uint index
    ) public view returns (bool);
}