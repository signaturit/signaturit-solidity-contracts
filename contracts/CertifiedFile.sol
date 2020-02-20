pragma solidity <0.6.0;

/*
Gas to deploy: 747.382
*/

import "./interfaces/CertifiedFileInterface.sol";
import "./interfaces/SignaturitUserInterface.sol";

import "./libraries/UsingConstants.sol";

contract CertifiedFile is CertifiedFileInterface, UsingConstants {
    address public signaturit;
    address public owner;

    string public id;
    string public hash;

    uint public createdAt;
    uint public size;

    SignaturitUserInterface public userContract;

    modifier signaturitOnly() {
        require(
            msg.sender == signaturit,
            "Only Signaturit account can perform this action"
        );

        _;
    }

    constructor(
        address _owner,
        address userContractAddress,
        string memory fileId,
        string memory fileHash,
        uint fileCreatedAt,
        uint fileSize
    )
        public
    {
        signaturit = msg.sender;
        owner = _owner;

        id = fileId;
        hash = fileHash;
        size = fileSize;
        createdAt = fileCreatedAt;

        userContract = SignaturitUserInterface(userContractAddress);
    }

    function notifyEvent ()
        public
        signaturitOnly
    {
        address contractToNofify;
        uint notificationIndex = 0;

        do {
            contractToNofify = userContract.getAddressArrayAttribute(CERTIFIED_FILE_NOTIFIERS_KEY, notificationIndex);
            ++notificationIndex;

            if (contractToNofify != address(0)) {
                contractToNofify.call(
                    abi.encodeWithSignature(
                        "notify(uint256,address)",
                        enumEvents.CERTIFIED_FILE_CREATED_EVENT,
                        address(this)
                    )
                );
            }
        } while (contractToNofify != address(0));
    }
}
