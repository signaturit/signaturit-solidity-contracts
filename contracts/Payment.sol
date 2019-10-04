pragma solidity <0.6.0;

/*
Gas to deploy: 3.347.342

PaymentCheck status legend:

UNPROCESSED    = 0;
PROCESSING     = 1;
PAID           = 2;
OVER_PAID      = 3;
PARTIALLY_PAID = 4;
*/

import "./Clause.sol";


contract Payment is Clause(
    "payment",
    "payment_checker.added"
)
{
    struct PaymentCheck {
        string id;
        uint status;
        uint checkedAt;
        uint createdAt;
    }

    struct Reference {
        string id;
        string value;
        uint price;
        string[] checks;
    }

    struct Receiver {
        string id;
        string[] references;
    }

    address public signaturit;

    string public contractId;
    string public signatureId;
    string public documentId;

    string[] public receiversArray;

    uint public startDate;
    uint public endDate;
    uint public period;

    mapping(string => Receiver) private receivers;
    mapping(string => Reference) private references;
    mapping(string => PaymentCheck) private paymentChecks;

    NotifierInterface public signatureSmartContract;

    constructor(
        address userContractAddress,
        address signatureContractAddress,
        string memory id
    )
        public
    {
        contractId = id;
        signaturit = msg.sender;

        userContract = UserInterface(userContractAddress);
        signatureContract = NotifierInterface(signatureContractAddress);
    }

    modifier signaturitOnly() {
        require(
            msg.sender == signaturit,
            "Only Signaturit account can perform this action"
        );

        _;
    }

    function init(
        string memory signature,
        string memory document,
        uint start,
        uint end,
        uint paymentPeriod
    )
        public
        signaturitOnly
    {
        endDate = end;
        startDate = start;
        documentId = document;
        period = paymentPeriod;
        signatureId = signature;

        _notify();
    }

    function setReceiver(
        string memory id
    )
        public
        signaturitOnly
    {
        _getReceiver(id);
    }

    function setReference(
        string memory receiverId,
        string memory referenceId,
        string memory referenceValue,
        uint referencePrice
    )
        public
        signaturitOnly
    {
        Reference storage newReference = _getReference(
            receiverId,
            referenceId
        );

        newReference.id = referenceId;
        newReference.value = referenceValue;
        newReference.price = referencePrice;
    }

    function addPaymentCheck(
        string memory receiverId,
        string memory referenceId,
        string memory paymentCheckId,
        uint status,
        uint checkedAt,
        uint createdAt
    )
        public
        signaturitOnly
    {
        Reference storage newReference = _getReference(
            receiverId,
            referenceId
        );

        paymentChecks[paymentCheckId] = PaymentCheck(
            paymentCheckId,
            status,
            checkedAt,
            createdAt
        );

        newReference.checks.push(paymentCheckId);
    }

    // Get paymentCheck if you got the id
    function getPaymentCheckById(
        string memory paymentCheckId
    )
        public
        view
        returns (
            string memory id,
            uint status,
            uint checkedAt,
            uint createdAt
        )
    {
        _checkPaymentCheckExistence(paymentCheckId);

        return (
            paymentChecks[paymentCheckId].id,
            paymentChecks[paymentCheckId].status,
            paymentChecks[paymentCheckId].checkedAt,
            paymentChecks[paymentCheckId].createdAt
        );
    }

    // Get paymentCheckID if you want the last one given a referenceId
    function getLastPaymentCheckFromReference(
        string memory referenceId
    )
        public
        view
        returns (
            string memory id,
            uint status,
            uint checkedAt,
            uint createdAt
        )
    {
        _checkPaymentCheckFromReferenceExistence(
            referenceId,
            references[referenceId].checks.length - 1
        );

        return getPaymentCheckById(
            paymentChecks[
                references[
                    referenceId
                ].checks[
                    references[
                        referenceId
                    ].checks.length - 1
                ]
            ].id
        );
    }

    // Get paymentCheckID if you want to iterate through all
    // the paymentChecks of a reference
    function getPaymentCheckFromReference(
        string memory referenceId,
        uint index
    )
        public
        view
        returns (
            string memory id,
            uint status,
            uint checkedAt,
            uint createdAt,
            bool more
        )
    {
        _checkReferenceExistence(referenceId);

        require(
            index < references[referenceId].checks.length,
            "Overflowed index"
        );

        bool thereIsMore = false;

        if (references[referenceId].checks.length > index + 1)
            thereIsMore = true;

        (
            string memory paymentCheckId,
            uint paymentCheckStatus,
            uint paymentCheckCheckedAt,
            uint paymentCheckCreatedAt
        ) = getPaymentCheckById(
            references[referenceId].checks[index]
        );

        return(
            paymentCheckId,
            paymentCheckStatus,
            paymentCheckCheckedAt,
            paymentCheckCreatedAt,
            thereIsMore
        );
    }

    // Get how many paymentChecks there are for a reference
    function getPaymentCheckSizeFromReference(
        string memory referenceId
    )
        public
        view
        returns (uint size)
    {
        _checkReferenceExistence(referenceId);

        return references[referenceId].checks.length;
    }

    // Get reference if you got the id
    function getReferenceById(
        string memory referenceId
    )
        public
        view
        returns (
            string memory id,
            string memory value,
            uint price
        )
    {
        _checkReferenceExistence(referenceId);

        return(
            references[referenceId].id,
            references[referenceId].value,
            references[referenceId].price
        );
    }

    // Get referenceID if you want to iterate through all
    // the references of a receiver
    function getReferenceFromReceiver(
        string memory receiverId,
        uint index
    )
        public
        view
        returns (
            string memory id,
            string memory value,
            uint price,
            bool more
        )
    {
        _checkReceiverExistence(receiverId);

        require(
            index < receivers[receiverId].references.length,
            "Overflowed index"
        );

        bool thereIsMore = false;

        if (receivers[receiverId].references.length > index + 1)
            thereIsMore = true;

        (
            string memory referenceId,
            string memory referenceValue,
            uint referencePrice
        ) = getReferenceById(
            receivers[receiverId].references[index]
        );

        return(
            referenceId,
            referenceValue,
            referencePrice,
            thereIsMore
        );
    }

    // Get references size from receiver
    function getReferenceSizeFromReceiver(
        string memory receiverId
    )
        public
        view
        returns (uint size)
    {
        _checkReceiverExistence(receiverId);

        return receivers[receiverId].references.length;
    }

    // Get receiverID by index
    function getReceiverId(
        uint index
    )
        public
        view
        returns (
            string memory id,
            bool more
        )
    {
        require(
            index < receiversArray.length,
            "Overflowed index"
        );

        bool thereIsMore = false;

        if (receiversArray.length > index + 1)
            thereIsMore = true;

        return(
            receiversArray[index],
            thereIsMore
        );
    }

    function _getReceiver(
        string memory id
    )
        private
        returns (Receiver storage)
    {
        if (bytes(receivers[id].id).length == 0) {

            string[] memory tmpString;

            receivers[id] = Receiver(id, tmpString);

            receiversArray.push(id);
        }

        return receivers[id];
    }

    function _getReference(
        string memory receiverId,
        string memory referenceId
    )
        private
        returns (Reference storage)
    {
        _getReceiver(receiverId);

        if (bytes(references[referenceId].id).length == 0) {

            string[] memory tmpPaymentChecks;

            references[referenceId] = Reference(
                referenceId,
                "",
                0,
                tmpPaymentChecks
            );

            receivers[receiverId].references.push(referenceId);
        }

        return references[referenceId];
    }

    function _checkReferenceExistence(
        string memory id
    )
        private
        view
    {
        require(
            bytes(references[id].id).length != 0,
            "This reference doesn't exist"
        );
    }

    function _checkReceiverExistence(
        string memory id
    )
        private
        view
    {
        require(
            bytes(receivers[id].id).length != 0,
            "This receiver doesn't exist"
        );
    }

    function _checkPaymentCheckFromReferenceExistence(
        string memory referenceId,
        uint index
    )
        private
        view
    {
        _checkReferenceExistence(referenceId);

        require(
            bytes(references[referenceId].checks[index]).length != 0,
            "This payment check doesn't exist"
        );
    }

    function _checkPaymentCheckExistence(
        string memory id
    )
        private
        view
    {
        require(
            bytes(paymentChecks[id].id).length != 0,
            "This payment check doesn't exist"
        );
    }
}
