pragma solidity <0.6.0;


contract NotifierInterface {

function notify(
        string memory attribute,
        address adr
    )
        public;
}