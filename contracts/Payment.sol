pragma solidity 0.5.0;

/*
Gas to deploy: 4.323.950 units

Statements status legend:

UNPROCESSED    = 0;
PROCESSING     = 1
PAID           = 2;
OVER_PAID      = 3;
PARTIALLY_PAID = 4;
*/

import "./interfaces/SignatureInterface.sol";
import "./interfaces/UserInterface.sol";


contract Payment {

    struct Statement {
        string id;
        uint status;
        uint receivedAt;
        uint createdAt;
    }

    struct Reference {
        string id;
        string value;
        uint price;
        string[] statements;
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
    mapping(string => Statement) private statements;

    UserInterface public userSmartContract;
    SignatureInterface public signatureSmartContract;

    constructor(
        address userContract,
        address signatureContract,
        string memory id
    )
        public
    {
        contractId = id;
        signaturit = msg.sender;

        userSmartContract = UserInterface(userContract);
        signatureSmartContract = SignatureInterface(signatureContract);
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

        signatureSmartContract.setClause(
            "payment",
            address(this)
        );
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

    function addStatement(
        string memory receiverId,
        string memory referenceId,
        string memory statementId,
        uint status,
        uint receivedAt,
        uint checkedAt
    )
        public
        signaturitOnly
    {
        Reference storage newReference = _getReference(
            receiverId,
            referenceId
        );

        statements[statementId] = Statement(
            statementId,
            status,
            receivedAt,
            checkedAt
        );

        newReference.statements.push(statementId);

        userSmartContract.notifyPaymentCheck(
            address(this),
            referenceId,
            receiverId,
            statementId,
            status,
            receivedAt,
            checkedAt
        );
    }

    // Get statement if you got the id
    function getStatementById(
        string memory statementId
    )
        public
        view
        returns (
            string memory id,
            uint status,
            uint receivedAt,
            uint createdAt
        )
    {
        _checkStatementExistence(statementId);

        return (
            statements[statementId].id,
            statements[statementId].status,
            statements[statementId].receivedAt,
            statements[statementId].createdAt
        );
    }

    // Get statmentID if you want the last one given a referenceId
    function getLastStatementFromReference(
        string memory referenceId
    )
        public
        view
        returns (
            string memory id,
            uint status,
            uint receivedAt,
            uint createdAt
        )
    {
        _checkStatementFromReferenceExistence(
            referenceId,
            references[referenceId].statements.length - 1
        );

        return getStatementById(
            statements[
                references[
                    referenceId
                ].statements[
                    references[
                        referenceId
                    ].statements.length - 1
                ]
            ].id
        );
    }

    // Get statementID if you want to iterate through all
    // the statements of a reference
    function getStatementFromReference(
        string memory referenceId,
        uint index
    )
        public
        view
        returns (
            string memory id,
            uint status,
            uint receivedAt,
            uint createdAt,
            bool more
        )
    {
        _checkReferenceExistence(referenceId);

        require(
            index < references[referenceId].statements.length,
            "Overflowed index"
        );

        bool thereIsMore = false;

        if (references[referenceId].statements.length > index + 1)
            thereIsMore = true;

        (
            string memory statementId,
            uint statmentStatus,
            uint statementReceivedAt,
            uint statementCreatedAt
        ) = getStatementById(
            references[referenceId].statements[index]
        );

        return(
            statementId,
            statmentStatus,
            statementReceivedAt,
            statementCreatedAt,
            thereIsMore
        );
    }

    // Get how many statements there are for a reference
    function getStatementSizeFromReference(
        string memory referenceId
    )
        public
        view
        returns (uint size)
    {
        _checkReferenceExistence(referenceId);

        return references[referenceId].statements.length;
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

            string[] memory tmpStatements;

            references[referenceId] = Reference(
                referenceId,
                "",
                0,
                tmpStatements
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

    function _checkStatementFromReferenceExistence(
        string memory referenceId,
        uint index
    )
        private
        view
    {
        _checkReferenceExistence(referenceId);

        require(
            bytes(references[referenceId].statements[index]).length != 0,
            "This statement doesn't exist"
        );
    }

    function _checkStatementExistence(
        string memory id
    )
        private
        view
    {
        require(
            bytes(statements[id].id).length != 0,
            "This statement doesn't exist"
        );
    }
}
