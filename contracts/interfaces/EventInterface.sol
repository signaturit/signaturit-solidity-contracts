pragma solidity <0.6.0;


contract EventInterface {
    address public parent;
    
    string public id;
    string public eventType;
    string public userAgent;
    uint public createdAt;
}
