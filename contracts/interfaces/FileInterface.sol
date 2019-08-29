pragma solidity <0.6.0;


contract FileInterface {
    address public parent;

    string public id;
    string public name;
    string public originalFileHash;

    uint public createdAt;
    uint public size;

    function init(
        string memory fileName,
        string memory fileHash,
        uint fileDate,
        uint fileSize
    )
        public;
}
