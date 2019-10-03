pragma solidity <0.6.0;

import "./interfaces/SignaturitUserInterface.sol";


contract BaseAggregator {
    SignaturitUserInterface userContract;

    address public signaturit;

    string public AGGREGATOR_NAME;
    string public NOTIFIERS_KEY;

    modifier signaturitOnly () {
        require(
            tx.origin == signaturit,
            "Only Signaturit account can perform this action"
        );

        _;
    }

    constructor(
        string memory aggregatorString,
        string memory notifiersString
    ) public {
        signaturit = msg.sender;

        AGGREGATOR_NAME = aggregatorString;
        NOTIFIERS_KEY = notifiersString;
    }

    function setOnUser(
        address userContractAddress
    )
        public
        signaturitOnly
    {
        userContract = SignaturitUserInterface(userContractAddress);

        userContract.setAddressAttribute(
            AGGREGATOR_NAME,
            address(this)
        );

        userContract.setAddressArrayAttribute(
            NOTIFIERS_KEY,
            address(this)
        );
    }
}