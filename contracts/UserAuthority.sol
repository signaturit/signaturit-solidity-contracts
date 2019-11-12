pragma solidity <0.6.0;

import "./interfaces/SignaturitUserInterface.sol";
import "./libraries/Utils.sol";

/*
Gas to deploy: 2.896.394
*/

/*
super admins can:
- create users
- set role as admins or users
- set reputations of admins and users
- set validity of admins and users

admins can:
- create users
- set reputations of users
- set validity of users

User's role:
0 - User
1 - Admin 
2 - Root

User's reputation:
Scale from 0 to 5, by default it sets to 3 to reflect neutrality

users can't do anything.
*/

contract UserAuthority {
    string constant private MANAGERS_KEY = "admitted-managers";

    address public rootAddress;

    struct User {
        address contractAddress;
        uint role;
        uint reputation;
        bool validity;
        address[] managedUsers;
    }
    
    mapping(address => User) users;

    constructor () public {
        rootAddress = msg.sender;

        address[] memory tmpAddresses;

        users[rootAddress] = User(address(0), 2, 5, true, tmpAddresses);
    }

    modifier atLeastAdmin() {
        require(
            users[msg.sender].role > 0,
            "Only an allowed account can perform this action"
        );

        _;
    }

    modifier authorizedAction(address userAdr) {
        require(
            users[msg.sender].role >= users[userAdr].role &&
            _isUserManager(userAdr, msg.sender),
            "Unauthorized action"
        );

        _;
    }

    function createUser(
        address userAdr,
        address contractAddress,
        uint role
    )
        public
        atLeastAdmin
    {
        require(role <= users[msg.sender].role, "Can't set an higher role from this account");

        address smartContractAddress = uint(contractAddress) > 0 ? contractAddress : address(0);

        address[] memory tmpAddresses;

        users[userAdr] = User(smartContractAddress, role, 3, true, tmpAddresses);

        // here it should be setted as manager in the user smart contract

        users[msg.sender].managedUsers.push(userAdr);
    }

    function setRole(
        address userAdr,
        uint role
    )
        public
        atLeastAdmin
        authorizedAction(userAdr)
    {

        users[userAdr].role = role;
    }

    function setReputation(
        address userAdr,
        uint reputation
    )
        public
        atLeastAdmin
        authorizedAction(userAdr)
    {
        users[userAdr].reputation = reputation;
    }

    function setValidity(
        address userAdr,
        bool validity
    )
        public
        atLeastAdmin
        authorizedAction(userAdr)
    {
        users[userAdr].validity = validity;
    }

    function getUser(
        address userAdr
    )
        public
        view
        returns(
            address contractAddress,
            uint role,
            uint reputation,
            bool validity
        )
    {
        if (users[userAdr].validity)

        return(
            users[userAdr].contractAddress,
            users[userAdr].role,
            users[userAdr].reputation,
            users[userAdr].validity
        );

        else return(address(0), 0, 0, false);
    }

    function _isUserManager(
        address userAdr,
        address managerAdr
    )
        public
        view
        returns (bool)
    {
        for(uint i = 0; i < users[managerAdr].managedUsers.length; i++) {
            if(users[managerAdr].managedUsers[i] == userAdr) return true;
        }

        return false;
    }
}