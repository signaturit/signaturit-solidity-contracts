pragma solidity <0.6.0;


library Utils {
    function _bytesToAddress(
        bytes memory rawData
    )
        internal
        pure
        returns (address)
    {
        uint bytesToUint;
        assembly {
            bytesToUint := mload(add(rawData,0x20))
        }
        return address(uint160(uint256(bytesToUint)));
    }

    function keccak (
        string memory key
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(key)
        );
    }
}
