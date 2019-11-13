pragma solidity <0.6.0;

import "./interfaces/SignaturitUserInterface.sol";
import "./libraries/Utils.sol";

/*
Gas to deploy: 2.896.394
*/

/*
User's role:
0 - User
1 - Admin
2 - Root

- Everyone that create an user is also manager for that user
- Root is manager of all the users

Admins can:
- create users
- create admins
- set role, reputation and validity for managed users

Admins can't:
- set role, validity and reputation of root
- create root users
- set role, reputation and validity of not managed users

Root can:
- create admins
- create users
- create root users
- set role, reputation and validity of everyone
- revoke management of users to admins

User's reputation:
Scale from 0 to 5, by default it sets to 3 to reflect neutrality

- For each new user with contractAddress not null the rootAddress is set as manager on the user smart contract
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

    modifier allowedAdminCreation() {
        require(
            users[msg.sender].role > 1,
            "The account can't perform this action"
        );

        _;
    }

    modifier allowedUserCreation() {
        require(
            users[msg.sender].role > 0,
            "The account can't perform this action"
        );

        _;
    }

    modifier allowedEdit(address userAdr) {
        require(
            users[msg.sender].role >= users[userAdr].role &&
            _isUserManager(userAdr, msg.sender),
            "Unauthorized action"
        );

        _;
    }

    function createAdmin(
        address adminAdr
    )
        public
        allowedAdminCreation
    {
        address[] memory tmpAddresses;

        users[adminAdr] = User(address(0), 1, 3, true, tmpAddresses);

        users[msg.sender].managedUsers.push(adminAdr);
    }

    function createUser(
        address userAdr
    )
        public
        allowedUserCreation
    {
        address[] memory tmpAddresses;

        users[userAdr] = User(address(0), 0, 3, true, tmpAddresses);

        users[msg.sender].managedUsers.push(userAdr);
    }

    function setUserContract(
        address userAdr,
        address contractAddress
    )
        public
        allowedEdit(userAdr)
    {
        require(users[userAdr].validity, "The user doesn't exists or it's not valid anymore");

        SignaturitUserInterface tmpUserContract = SignaturitUserInterface(contractAddress);

        tmpUserContract.setAddressArrayAttribute(MANAGERS_KEY, rootAddress);

        users[rootAddress].managedUsers.push(userAdr);

        users[userAdr].contractAddress = contractAddress;
    }

    function setRole(
        address userAdr,
        uint role
    )
        public
        allowedEdit(userAdr)
    {
        users[userAdr].role = role;
    }

    function setReputation(
        address userAdr,
        uint reputation
    )
        public
        allowedEdit(userAdr)
    {
        users[userAdr].reputation = reputation;
    }

    function setValidity(
        address userAdr,
        bool validity
    )
        public
        allowedEdit(userAdr)
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
            bool validity,
            uint managedUsers
        )
    {
        if (users[userAdr].validity)

        return(
            users[userAdr].contractAddress,
            users[userAdr].role,
            users[userAdr].reputation,
            users[userAdr].validity,
            users[userAdr].managedUsers.length
        );

        else return(address(0), 0, 0, false, 0);
    }

    function getManagedUser(
        address userAdr,
        uint index
    )
        public
        view
        returns (
            address adr,
            bool more
        )
    {
        if(
            users[userAdr].validity &&
            users[userAdr].managedUsers[index] == address(0)
        ) return(address(0), false);

        bool thereIsMore = false;

        if (index < users[userAdr].managedUsers.length - 1) thereIsMore = true;

        return(
            users[userAdr].managedUsers[index],
            thereIsMore
        );
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