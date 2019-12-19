pragma solidity <0.6.0;

import "./libraries/Utils.sol";

/*
Gas to deploy: 880.108
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
        mapping(address => bool) managers;
    }
    
    mapping(address => User) private users;

    constructor () public {
        rootAddress = msg.sender;

        address[] memory tmpAddresses;

        users[rootAddress] = User(address(0), 2, 5, true, tmpAddresses);
    }

    modifier allowedAdminCreation() {
        require(
            users[msg.sender].role >= 1,
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
            users[msg.sender].role > 0 &&
            isUserManager(userAdr, msg.sender),
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

        users[adminAdr].managers[msg.sender] = true;

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

        users[userAdr].managers[msg.sender] = true;

        users[msg.sender].managedUsers.push(userAdr);
    }

    function setUserContract(
        address userAdr,
        address contractAddress
    )
        public
        allowedEdit(userAdr)
    {
        users[userAdr].contractAddress = contractAddress;
    }

    function setRole(
        address userAdr,
        uint role
    )
        public
        allowedEdit(userAdr)
    {
        require(role <= users[msg.sender].role, "Can't set an higher role");

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

        else
            return(address(0), 0, 0, false, 0);
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
        if (
            users[userAdr].managedUsers.length == 0 ||
            users[userAdr].managedUsers[index] == address(0)
        )
            return(address(0), false);

        bool thereIsMore = false;

        if (index < users[userAdr].managedUsers.length - 1) thereIsMore = true;

        return(
            users[userAdr].managedUsers[index],
            thereIsMore
        );
    }

    function isUserManager(
        address userAdr,
        address managerAdr
    )
        public
        view
        returns (bool)
    {
        return users[userAdr].managers[managerAdr];
    }
}
