pragma solidity <0.6.0;

/*
Gas to deploy: 1.441.547
*/

import "./interfaces/EventInterface.sol";

contract AuditTrails {

    struct AuditTrail {
        address signatureAddress;
        address requesterAddress;
        address signerAddress;
        address fileAddress;
        address[] events;
        uint terminatedAt;
    }

    mapping(string => address) documentAddress;
    mapping(address => AuditTrail) documentAuditTrail;
    mapping(address => bool) admittedManagers;

    constructor(
    ) public {
        admittedManagers[msg.sender] = true;
    }

    modifier onlyManager() {
        require(
            admittedManagers[msg.sender] == true,
            "Only Signaturit's manager account can perform this action"
        );

        _;
    }

    function addManager(
        address manager
    )
        public
        onlyManager
    {
        admittedManagers[manager] = true;
    }

    function createAudit(
        string  memory hashedDocumentId,
        address documentContract,
        address signatureContract,
        address requesterPubKey,
        address signerPubKey,
        address fileContractAddress
    )
        public
        onlyManager
    {
        require(documentAddress[hashedDocumentId] == address(0), "The audit for this document already exists");

        address[] memory eventsInAudit;

        AuditTrail memory audit = AuditTrail(
            signatureContract,
            requesterPubKey,
            signerPubKey,
            fileContractAddress,
            eventsInAudit,
            0
        );

        documentAuditTrail[documentContract] = audit;

        documentAddress[hashedDocumentId] = documentContract;
    }

    function terminateAudit(
        uint terminatedTime,
        string memory hashedId
    )
        public
        onlyManager
    {
        require(documentAddress[hashedId] != address(0), "The audit for this document doesn't exists");

        documentAuditTrail[documentAddress[hashedId]].terminatedAt = terminatedTime;
    }

    function addEventInAudit(
        address eventAddress,
        string memory hashedId
    )
        public
        onlyManager
    {
        require(documentAddress[hashedId] != address(0), "The audit for this document doesn't exists");

        documentAuditTrail[documentAddress[hashedId]].events.push(eventAddress);
    }

    function getAuditByDocumentId(
        string memory hashedId
    )
        public
        view
        returns(
            address signatureAddr,
            address documentAddr,
            address requesterAddr,
            address signerAddr,
            address fileAddr,
            uint eventsLength,
            uint terminatedAt
        )
    {
        AuditTrail memory tmpAudit = _getAudit(hashedId);

        return (
            tmpAudit.signatureAddress,
            documentAddress[hashedId],
            tmpAudit.requesterAddress,
            tmpAudit.signerAddress,
            tmpAudit.fileAddress,
            tmpAudit.events.length,
            tmpAudit.terminatedAt
        );
    }

    function getEventInAudit(
        uint index,
        string memory hashedId
    )
        public
        view
        returns(
        string memory id,
        string memory eventType,
        string memory userAgent,
        uint createdAt
    ) {
        AuditTrail memory tmpAudit = _getAudit(hashedId);

        require(tmpAudit.events.length > index, "The index exceeds the number of events");

        EventInterface tmpEvent = EventInterface(tmpAudit.events[index]);

        return(
            tmpEvent.id(),
            tmpEvent.eventType(),
            tmpEvent.userAgent(),
            tmpEvent.createdAt()
        );
    }

    function _getAudit(
        string memory hashedId
    )
        private
        view
        returns(AuditTrail memory)
    {
        require(documentAddress[hashedId] != address(0), "The audit for this document doesn't exists");

        return documentAuditTrail[documentAddress[hashedId]];
    }
}
