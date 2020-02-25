pragma solidity <0.6.0;


contract NotifierInterface {

function notify(
        uint attribute,
        address adr
    )
        public;
}