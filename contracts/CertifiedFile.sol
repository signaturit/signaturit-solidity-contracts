pragma solidity <0.6.0;

/*
Gas to deploy: 655.214
*/

import "./interfaces/CertifiedFileInterface.sol";
import "./interfaces/SignaturitUserInterface.sol";


contract CertifiedFile is CertifiedFileInterface {
    address public signaturit;
    address public owner;

    string constant CREATED_EVENT = 'certified_file.contract.created';
    string constant NOTIFIERS_KEY = 'certified-file-nofify';

    string public id;
    string public hash;

    uint public createdAt;
    uint public size;

    SignaturitUserInterface userContract;

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
            contractToNofify = userContract.getAddressArrayAttribute(NOTIFIERS_KEY, notificationIndex);
            ++notificationIndex;

            if (contractToNofify != address(0)) {
                contractToNofify.call(
                    abi.encodeWithSignature(
                        'notify(string,address)',
                        CREATED_EVENT,
                        address(this)
                    )
                );
            }
        } while (contractToNofify != address(0));
    }
}
