pragma solidity <0.6.0;

/*
Gas to deploy: 570.352
*/

import "./interfaces/FileInterface.sol";


contract File is FileInterface {
    address public parent;

    string public id;
    string public name;
    string public originalFileHash;

    uint public createdAt;
    uint public size;

    constructor(
        string memory fileId
    )
        public
    {
        id = fileId;
        parent = msg.sender;
    }

    modifier parentOnly() {
        require(
            msg.sender == parent,
            "Only the parent account can perform this action"
        );

        _;
    }

    function init(
        string memory fileName,
        string memory fileHash,
        uint fileDate,
        uint fileSize
    )
        public
        parentOnly
    {
        require(
            fileSize > 0 &&
            bytes(fileName).length != 0,
            "Invalid input value(s)"
        );

        name = fileName;
        size = fileSize;
        createdAt = fileDate;
        originalFileHash = fileHash;
    }
}
