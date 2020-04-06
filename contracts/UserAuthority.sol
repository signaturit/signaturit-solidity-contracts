pragma solidity <0.6.0;

import "./libraries/Utils.sol";

/*
Gas to deploy: 907.423
*/

contract UserAuthority {
    address public rootAddress;

    enum role {
        UNDEFINED,
        USER,
        ADMIN,
        ROOT
    }

    enum reputation {
        UNDEFINED,
        VERY_LOW,
        LOW,
        MEDIUM,
        HIGH,
        VERY_HIGH
    }

    struct User {
        address contractAddress;
        UserAuthority.role role;
        UserAuthority.reputation reputation;
        bool validity;
        address[] managedUsers;
        mapping(address => bool) managers;
    }
    
    mapping(address => User) private users;

    constructor () public {
        rootAddress = msg.sender;

        address[] memory tmpAddresses;

        users[rootAddress] = User(address(0), role.ROOT, reputation.VERY_HIGH, true, tmpAddresses);
    }

    modifier allowedAdminCreation() {
        require(
            users[msg.sender].role >= role.ADMIN,
            "The account can't perform this action"
        );

        _;
    }

    modifier allowedUserCreation() {
        require(
            users[msg.sender].role > role.USER,
            "The account can't perform this action"
        );

        _;
    }

    modifier allowedEdit(address userAdr) {
        require(
            users[msg.sender].role > role.USER &&
            isUserManager(userAdr, msg.sender),
            "Unauthorized action"
        );

        _;
    }

    modifier notCreatedYet(address userAdr) {
        require(
            uint8(users[userAdr].role) == 0, "User already exists"
        );

        _;
    }

    function createAdmin(
        address adminAdr
    )
        public
        allowedAdminCreation
        notCreatedYet(adminAdr)
    {
        _createUser(msg.sender, adminAdr, UserAuthority.role.ADMIN);
    }

    function createUser(
        address userAdr
    )
        public
        allowedUserCreation
        notCreatedYet(userAdr)
    {
        _createUser(msg.sender, userAdr, UserAuthority.role.USER);
    }

    function createAdminAndUser(
        address adminAdr,
        address userAdr
    )
        public
        allowedAdminCreation
        notCreatedYet(userAdr)
        notCreatedYet(adminAdr)
    {
        _createUser(msg.sender, adminAdr, UserAuthority.role.ADMIN);
        _createUser(adminAdr, userAdr, UserAuthority.role.USER);
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
        UserAuthority.role inputRole
    )
        public
        allowedEdit(userAdr)
    {
        require(uint8(inputRole) <= uint8(users[msg.sender].role), "Can't set an higher role");

        users[userAdr].role = inputRole;
    }

    function setReputation(
        address userAdr,
        UserAuthority.reputation inputReputation
    )
        public
        allowedEdit(userAdr)
    {
        users[userAdr].reputation = inputReputation;
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
            UserAuthority.role outputRole,
            UserAuthority.reputation outputReputation,
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
            return(address(0), role.UNDEFINED, reputation.UNDEFINED, false, 0);
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

    function _createUser(
        address manager,
        address user,
        UserAuthority.role inputRole
    ) internal {
        address[] memory tmpAddresses;

        users[user] = User(address(0), inputRole, reputation.MEDIUM, true, tmpAddresses);

        users[user].managers[manager] = true;

        users[manager].managedUsers.push(user);
    }

}
