pragma solidity <0.6.0;

/*
Gas to deploy: 1.925.304
*/

contract SignaturitUser {
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
        bytes32 bytes32key = _keccak256(key);

        stringAttr[bytes32key] = value;
    }

    function getStringAttribute (
        string memory key
    ) 
        public
        view
        returns (string memory)
    {
        bytes32 bytes32key = _keccak256(key);

        return stringAttr[bytes32key];
    }

    function setStringArrayAttribute (
        string memory key,
        string memory value
    )
        public
        protected
    {
        bytes32 bytes32key = _keccak256(key);
        stringArrayAttr[bytes32key].push(value);
    }

    function getStringArrayAttribute (
        string memory key,
        uint index
    )
        public
        view
        returns (string memory)
    {
        bytes32 bytes32key = _keccak256(key);

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
        bytes32 bytes32key = _keccak256(key);
        numberAttr[bytes32key] = value;
    }

    function getNumberAttribute (
        string memory key
    )
        public
        view
        returns (int)
    {
        bytes32 bytes32key = _keccak256(key);

        return numberAttr[bytes32key];
    }

    function setNumberArrayAttribute (
        string memory key,
        int value
    )
        public
        protected
    {
        bytes32 bytes32key = _keccak256(key);
        numberArrayAttr[bytes32key].push(value);
    }

    function getNumberArrayAttribute (
        string memory key,
        uint index
    )
        public
        view
        returns (int)
    {
        bytes32 bytes32key = _keccak256(key);

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
        bytes32 bytes32key = _keccak256(key);

        addressAttr[bytes32key] = value;
    }

    function getAddressAttribute (
        string memory key
    )
        public
        view
        returns (address)
    {
        bytes32 bytes32key = _keccak256(key);

        return addressAttr[bytes32key];
    }

    function setAddressArrayAttribute (
        string memory key,
        address value
    )
        public
        protected
    {
        bytes32 bytes32key = _keccak256(key);
        addressArrayAttr[bytes32key].push(value);
    }

    function getAddressArrayAttribute (
        string memory key,
        uint index
    )
        public
        view
        returns (address)
    {
        bytes32 bytes32key = _keccak256(key);

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
        bytes32 bytes32key = _keccak256(key);

        boolAttr[bytes32key] = value;
    }

    function getBooleanAttribute (
        string memory key
    )
        public
        view
        returns (bool)
    {
        bytes32 bytes32key = _keccak256(key);

        return boolAttr[bytes32key];
    }

    function setBooleanArrayAttribute (
        string memory key,
        bool value
    )
        public
        protected
    {
        bytes32 bytes32key = _keccak256(key);
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
        bytes32 bytes32key = _keccak256(key);

        if (boolArrayAttr[bytes32key].length > index) {
            return boolArrayAttr[bytes32key][index];
        }

        return false;
    }

    function _keccak256 (
        string memory value
    )
        private
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(value)
        );
    }
}