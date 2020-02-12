contract('AuditTrails', async (accounts) => {
    const ArtifactAuditTrails = artifacts.require('AuditTrails');
    const ArtifactFile        = artifacts.require('File');
    const ArtifactEvent       = artifacts.require('Event');
    const ArtifactSignature   = artifacts.require('Signature');
    const ArtifactDocument    = artifacts.require('Document');
    const ArtifactSignatureDeployer = artifacts.require('SignatureDeployer');
    const ArtifactSignaturitUser = artifacts.require('SignaturitUser');

    const v4 = require("uuid").v4;

    const signaturitAddress = accounts[0];
    const requesterAddress  = accounts[1];
    const signerAddress     = accounts[2];
    const invalidAddress    = accounts[3];

    const FILE_NOTIFIERS_KEY = "file-notifiers";
    const EVENT_NOTIFIERS_KEY = "event-notifiers";
    const DOCUMENT_NOTIFIERS_KEY = "document-notifiers";

    const nullAddress = '0x0000000000000000000000000000000000000000';

    let auditTrailsContract;
    let signaturitUserContract;
    let signatureDeployerContract;
    let signatureContract;
    let userContract;

    const signatureId = v4();


    beforeEach(async () => {
        signatureDeployerContract = await ArtifactSignatureDeployer.new({from: signaturitAddress});

        userContract = await ArtifactSignaturitUser.new(
            requesterAddress,
            {
                from: signaturitAddress
            }
        );

        auditTrailsContract = await ArtifactAuditTrails.new({from: signaturitAddress});

        await auditTrailsContract.subscribe(userContract.address, {from: signaturitAddress});

        signatureContract = await ArtifactSignature.new(
            signatureId,
            signatureDeployerContract.address,
            Date.now(),
            requesterAddress,
            userContract.address,
            {
                from: signaturitAddress
            }
        );

        await signatureContract.notifyCreation(
            {
                from: signaturitAddress
            }
        );
    });

    it('Check if it deploy correctly', async () => {
        assert.ok(auditTrailsContract.address);
    });

    it("Check if it's correctly subsribed to the user's smart contract", async () => {
        const readAddressFromFile = await userContract.getAddressArrayAttribute(FILE_NOTIFIERS_KEY, 0);
        const readAddressFromEvent = await userContract.getAddressArrayAttribute(EVENT_NOTIFIERS_KEY, 0);
        const readAddressFromDocument = await userContract.getAddressArrayAttribute(DOCUMENT_NOTIFIERS_KEY, 0);

        assert.equal(readAddressFromFile, auditTrailsContract.address);
        assert.equal(readAddressFromEvent, auditTrailsContract.address);
        assert.equal(readAddressFromDocument, auditTrailsContract.address);
    });

    it("Create a document on signature and expect this to create an audit trail", async () => {
        const documentId = v4();
        const signatureType = 'advanced'
        const createdAt = Date.now();

        await signatureContract.createDocument(
            documentId,
            signatureType,
            createdAt,
            {
                from: signaturitAddress
            }
        );

        await signatureContract.setDocumentOwner(
            documentId,
            signerAddress,
            {
                from: signaturitAddress
            }
        );

        const documentAddress = await signatureContract.getDocument(documentId);

        const readAudit = await auditTrailsContract.getAudit(requesterAddress, documentId);

        assert.equal(signatureContract.address, readAudit.signatureAddr);
        assert.equal(documentAddress, readAudit.documentAddr);
        assert.equal(requesterAddress, readAudit.requesterAddr);
    });

    it("Access to not existing audit trail for existing document", async () => {
        const documentId = v4();
        const signatureType = 'advanced'
        const createdAt = Date.now();

        await signatureContract.createDocument(
            documentId,
            signatureType,
            createdAt,
            {
                from: signaturitAddress
            }
        );

        await signatureContract.setDocumentOwner(
            documentId,
            signerAddress,
            {
                from: signaturitAddress
            }
        );

        const documentAddress = await signatureContract.getDocument(documentId);

        try {
            const readAudit = await auditTrailsContract.getAudit(signaturitAddress, documentId);
        }catch(error) {
            assert.include(
                error.message,
                "The audit for this document doesn't exists"
            )
        }
    });

    it("Create a document and then a file, this create an audit trails first and then it populates it with file address", async () => {
        const documentId = v4();
        const createdAt = Date.now();
        const fileId = v4();
        const fileName = 'name';
        const fileHash = 'hash';
        const fileSize = 100;
        const signatureType = 'advanced'

        await signatureContract.createDocument(
            documentId,
            signatureType,
            createdAt,
            {
                from: signaturitAddress
            }
        );

        await signatureContract.setDocumentOwner(
            documentId,
            signerAddress,
            {
                from: signaturitAddress
            }
        );

        await signatureContract.createFile(
            documentId,
            fileId,
            fileName,
            fileHash,
            createdAt,
            fileSize,
            {
                from: signaturitAddress
            }
        );

        const documentAddress = await signatureContract.getDocument(documentId);
        const fileAddress = await signatureContract.getFile(documentId);

        const readAudit = await auditTrailsContract.getAudit(requesterAddress, documentId);

        assert.equal(signatureContract.address, readAudit.signatureAddr);
        assert.equal(documentAddress, readAudit.documentAddr);
        assert.equal(requesterAddress, readAudit.requesterAddr);
        assert.equal(fileAddress, readAudit.fileAddr);
    });

    it("Create a file on signature and expect this to create a document and a related audit trail", async () => {
        const documentId = v4();
        const createdAt = Date.now();
        const fileId = v4();
        const fileName = 'name';
        const fileHash = 'hash';
        const fileSize = 100;

        await signatureContract.createFile(
            documentId,
            fileId,
            fileName,
            fileHash,
            createdAt,
            fileSize,
            {
                from: signaturitAddress
            }
        );

        await signatureContract.setDocumentOwner(
            documentId,
            signerAddress,
            {
                from: signaturitAddress
            }
        );

        const documentAddress = await signatureContract.getDocument(documentId);
        const fileAddress = await signatureContract.getFile(documentId);

        const readAudit = await auditTrailsContract.getAudit(requesterAddress, documentId);

        assert.equal(signatureContract.address, readAudit.signatureAddr);
        assert.equal(documentAddress, readAudit.documentAddr);
        assert.equal(requesterAddress, readAudit.requesterAddr);
        assert.equal(fileAddress, readAudit.fileAddr);
    });

    it("Create a document and then an event, this create an audit trails first and then it populates it with event address", async () => {
        const documentId = v4();
        const createdAt = Date.now();
        const signatureType = 'advanced'
        const eventId = v4();
        const eventType = 'document.contract.signed';
        const eventUserAgent = 'userAgent';

        await signatureContract.createDocument(
            documentId,
            signatureType,
            createdAt,
            {
                from: signaturitAddress
            }
        );

        await signatureContract.setDocumentOwner(
            documentId,
            signerAddress,
            {
                from: signaturitAddress
            }
        );

        await signatureContract.createEvent(
            documentId,
            eventId,
            eventType,
            eventUserAgent,
            createdAt,
            {
                from: signaturitAddress
            }
        );

        const documentAddress = await signatureContract.getDocument(documentId);
        const documentContract = await ArtifactDocument.at(documentAddress);

        const readSignerAddress = await documentContract.signer();
        
        const eventAddress = await signatureContract.getEvent(documentId, eventId);

        const eventContract = await ArtifactEvent.at(eventAddress);

        const readEventId = await eventContract.id();
        const readEventType = await eventContract.eventType();
        const readEventUserAgent = await eventContract.userAgent();
        const readEventCreatedAt = await eventContract.createdAt();
        const readEventParent = await eventContract.parent();

        const readAudit = await auditTrailsContract.getAudit(requesterAddress, documentId);

        const readEventInAudit = await auditTrailsContract.getEventInAudit(0, requesterAddress, documentId);

        assert.equal(signatureContract.address, readAudit.signatureAddr);
        assert.equal(documentAddress, readAudit.documentAddr);
        assert.equal(requesterAddress, readAudit.requesterAddr);
        assert.equal(readSignerAddress, readAudit.signerAddr);
        assert.equal(createdAt, readAudit.terminatedAt);
        assert.equal(1, readAudit.eventsLength);
        assert.equal(eventId, readEventId);
        assert.equal(readEventId, readEventInAudit.id);
        assert.equal(eventType, readEventType);
        assert.equal(readEventType, readEventInAudit.eventType);
        assert.equal(eventUserAgent, readEventUserAgent);
        assert.equal(readEventUserAgent, readEventInAudit.userAgent);
        assert.equal(readEventCreatedAt, createdAt);
        assert.equal(readEventCreatedAt.toNumber(), readEventInAudit.createdAt.toNumber());
        assert.equal(readEventParent, documentAddress);
    });


    it("Create an event on signature and expect this to create first a document and then an audit trail, also retrieve the event from AuditTrails contract", async () => {
        const documentId = v4();
        const createdAt = Date.now();
        const eventId = v4();
        const eventType = 'document.contract.signed';
        const eventUserAgent = 'userAgent';

        await signatureContract.createEvent(
            documentId,
            eventId,
            eventType,
            eventUserAgent,
            createdAt,
            {
                from: signaturitAddress
            }
        );

        await signatureContract.setDocumentOwner(
            documentId,
            signerAddress,
            {
                from: signaturitAddress
            }
        );

        const documentAddress = await signatureContract.getDocument(documentId);

        const eventAddress = await signatureContract.getEvent(documentId, eventId);

        const eventContract = await ArtifactEvent.at(eventAddress);

        const readEventId = await eventContract.id();
        const readEventType = await eventContract.eventType();
        const readEventUserAgent = await eventContract.userAgent();
        const readEventCreatedAt = await eventContract.createdAt();
        const readEventParent = await eventContract.parent();

        const readAudit = await auditTrailsContract.getAudit(requesterAddress, documentId);

        const readEventInAudit = await auditTrailsContract.getEventInAudit(0, requesterAddress, documentId);

        assert.equal(signatureContract.address, readAudit.signatureAddr);
        assert.equal(documentAddress, readAudit.documentAddr);
        assert.equal(requesterAddress, readAudit.requesterAddr);
        assert.equal(1, readAudit.eventsLength);
        assert.equal(eventId, readEventId);
        assert.equal(readEventId, readEventInAudit.id);
        assert.equal(eventType, readEventType);
        assert.equal(readEventType, readEventInAudit.eventType);
        assert.equal(eventUserAgent, readEventUserAgent);
        assert.equal(readEventUserAgent, readEventInAudit.userAgent);
        assert.equal(readEventCreatedAt, createdAt);
        assert.equal(readEventCreatedAt.toNumber(), readEventInAudit.createdAt.toNumber());
        assert.equal(readEventParent, documentAddress);

    });
})