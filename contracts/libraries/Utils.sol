pragma solidity 0.5.0;


library Utils {
    function _bytesToAddress(bytes memory rawData) internal pure returns(address) {
        uint bytesToUint;
        assembly {
            bytesToUint := mload(add(rawData,0x20))
        }
        return address(uint160(uint256(bytesToUint)));
    }
}
