pragma solidity <0.6.0;

import "./interfaces/SignaturitUserInterface.sol";


contract BaseAggregator {
    SignaturitUserInterface public userContract;

    address public signaturit;

    string public aggregatorName;
    string public notifiersKey;

    modifier signaturitOnly () {
        require(
            tx.origin == signaturit,
            "Only Signaturit account can perform this action"
        );

        _;
    }

    constructor(
        address userContractAddress,
        string memory aggregatorString,
        string memory notifiersString
    ) public {
        signaturit = msg.sender;

        aggregatorName = aggregatorString;
        notifiersKey = notifiersString;

        userContract = SignaturitUserInterface(userContractAddress);

        userContract.setAddressAttribute(
            aggregatorName,
            address(this)
        );

        userContract.setAddressArrayAttribute(
            notifiersKey,
            address(this)
        );
    }
}