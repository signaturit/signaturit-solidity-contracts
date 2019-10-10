contract('UserEvents', async (accounts) => {
    const truffleAssert = require('truffle-assertions');
    const v4 = require('uuid').v4;

    const ArtifactUser = artifacts.require('SignaturitUser');
    const ArtifactUserEvents = artifacts.require('UserEvents');
    const ArtifactSignature = artifacts.require('Signature');
    const ArtifactSignatureDeployer = artifacts.require('SignatureDeployer');
    const ArtifactCertifiedFile = artifacts.require('CertifiedFile');
    const ArtifactCertifiedEmail = artifacts.require('CertifiedEmail');
    const ArtifactCertifiedEmailDeployer = artifacts.require('CertifiedEmailDeployer');
    const ArtifactCertificate = artifacts.require('Certificate');

    const SIGNATURE_NOTIFIERS_KEY = "signature-notifiers";
    const DOCUMENT_NOTIFIERS_KEY = "document-notifiers";
    const FILE_NOTIFIERS_KEY = "file-notifiers";
    const EVENT_NOTIFIERS_KEY = "event-notifiers";
    const CERTIFIED_EMAIL_NOTIFIERS_KEY = "certified-email-notifiers";
    const CERTIFICATE_NOTIFIERS_KEY = "certificate-notifiers";
    const CERTIFIED_FILE_NOTIFIERS_KEY = "certified-file-notifiers";



    const ownerAddress = accounts[0];
    const signaturitUser = accounts[1];

    const signatureId = v4();
    const signatureType = 'advanced';
    const documentId = v4();
    const documentCreatedAt = Date.now();

    const eventId = v4();
    const eventType = 'document_opened';
    const eventUserAgent = 'user agent';
    const eventCreatedAt = Date.now();

    const fileId = v4();
    const fileSize = 123423;
    const fileName = 'File.name';
    const fileHash = 'asdf';
    const fileCreatedAt = Date.now();

    const certifiedEmailId = v4();
    const certifiedEmailSubject = 'subject';
    const certifiedEmailBody = 'body';
    const certifiedEmailDelivery = 'full';
    const certifiedEmailCreatedAt = Date.now();
    
    const certificateId = v4();
    const certificateCreatedAt = Date.now();

    let userEventsContract;
    let userContract;
    let signatureContract;
    let certifiedFileContract;
    let signatureDeployerContract;
    let certifiedEmailDeployerContract;
    let certifiedEmailContract;

    beforeEach(async () => {
        userContract = await ArtifactUser.new(
            ownerAddress,
            {
                from: signaturitUser
            }
        );

        userEventsContract = await ArtifactUserEvents.new(
            userContract.address,
            {
                from: signaturitUser
            }
        );

        signatureDeployerContract = await ArtifactSignatureDeployer.new({from: signaturitUser});
        certifiedEmailDeployerContract = await ArtifactCertifiedEmailDeployer.new({from: signaturitUser});

        signatureContract = await ArtifactSignature.new(
            signatureId,
            signatureDeployerContract.address,
            Date.now(),
            ownerAddress,
            userContract.address,
            {
                from: signaturitUser
            }
        );

        certifiedFileContract = await ArtifactCertifiedFile.new(
            ownerAddress,
            userContract.address,
            fileId,
            fileHash,
            fileCreatedAt,
            fileSize,
            {
                from: signaturitUser
            }
        );

        certifiedEmailContract = await ArtifactCertifiedEmail.new(
            certifiedEmailId,
            certifiedEmailSubject,
            certifiedEmailBody,
            certifiedEmailDelivery,
            certifiedEmailCreatedAt,
            certifiedEmailDeployerContract.address,
            ownerAddress,
            userContract.address, 
            {
                from: signaturitUser
            }
        );
    });

    it("Check if it deploy correctly", async (done) => {
        assert.ok(userEventsContract);
        done();
    });

    it("Check if the deploy of the user events adds on the user", async () => {
        const signatureNotifierAddress = await userContract.getAddressArrayAttribute(SIGNATURE_NOTIFIERS_KEY, 0);
        const documentNotifierAddress = await userContract.getAddressArrayAttribute(DOCUMENT_NOTIFIERS_KEY, 0);
        const fileNotifierAddress = await userContract.getAddressArrayAttribute(FILE_NOTIFIERS_KEY, 0);
        const eventNotifierAddress = await userContract.getAddressArrayAttribute(EVENT_NOTIFIERS_KEY, 0);
        const certifiedEmailNotifierAddress = await userContract.getAddressArrayAttribute(CERTIFIED_EMAIL_NOTIFIERS_KEY, 0);
        const certificateNotifierAddress = await userContract.getAddressArrayAttribute(CERTIFICATE_NOTIFIERS_KEY, 0);
        const certifiedFileNotifierAddress = await userContract.getAddressArrayAttribute(CERTIFIED_FILE_NOTIFIERS_KEY, 0);


        assert.equal(signatureNotifierAddress, userEventsContract.address);
        assert.equal(documentNotifierAddress, userEventsContract.address);
        assert.equal(fileNotifierAddress, userEventsContract.address);
        assert.equal(eventNotifierAddress, userEventsContract.address);
        assert.equal(certifiedEmailNotifierAddress, userEventsContract.address);
        assert.equal(certificateNotifierAddress, userEventsContract.address);
        assert.equal(certifiedFileNotifierAddress, userEventsContract.address);


    });

    it("Deploy signature and expect to be notified", async () => {
        await signatureContract.notifyCreation(
            {
                from: signaturitUser
            }
        );
        const events = await userEventsContract.getPastEvents('SignatureCreated', {
            fromBlock: 0,
            toBlock: "latest"
        });
        
        assert.equal(events.length, 1)
        assert.equal(events[0].returnValues[0], signatureContract.address);
    });

    it("Deploy signature with document and file and expect to be notified", async () => {
        await signatureContract.notifyCreation(
            {
                from: signaturitUser
            }
        );

        await signatureContract.createDocument(
            documentId,
            signatureType,
            documentCreatedAt,
            {
                from: signaturitUser
            }
        );

        await signatureContract.createFile(
            documentId,
            fileId,
            fileName,
            fileHash,
            fileCreatedAt,
            fileSize,
            {
                from: signaturitUser
            }
        );

        await signatureContract.createEvent(
            documentId,
            eventId,
            eventType,
            eventUserAgent,
            eventCreatedAt,
            {
                from: signaturitUser
            }
        );

        const signatureEvents = await userEventsContract.getPastEvents('SignatureCreated', {
            fromBlock: 0,
            toBlock: "latest"
        });

        const documentEvents = await userEventsContract.getPastEvents('DocumentCreated', {
            fromBlock: 0,
            toBlock: "latest"
        });

        const fileEvents = await userEventsContract.getPastEvents('FileCreated', {
            fromBlock: 0,
            toBlock: "latest"
        });

        const eventEvents = await userEventsContract.getPastEvents('EventCreated', {
            fromBlock: 0,
            toBlock: "latest"
        });

        const documentAddress = await signatureContract.getDocumentByIndex(0);
        const fileAddress = await signatureContract.getFile(documentId);
        const eventAddress = await signatureContract.getEvent(documentId, eventId);

        assert.equal(signatureEvents.length, 1)
        assert.equal(signatureEvents[0].returnValues[0], signatureContract.address);

        assert.equal(documentEvents.length, 1)
        assert.equal(documentEvents[0].returnValues[0], documentAddress);

        assert.equal(eventEvents.length, 1)
        assert.equal(eventEvents[0].returnValues[0], eventAddress);

        assert.equal(fileEvents.length, 1)
        assert.equal(fileEvents[0].returnValues[0], fileAddress);
    });

    it("Deploy certified email with certificate and file and expect to be notified", async () => {
        await certifiedEmailContract.notifyCreation(
            {
                from: signaturitUser
            }
        );

        await certifiedEmailContract.createCertificate(
            certificateId,
            certificateCreatedAt,
            ownerAddress,
            {
                from: signaturitUser
            }
        );

        await certifiedEmailContract.createFile(
            certificateId,
            fileHash,
            fileId,
            fileName,
            fileCreatedAt,
            fileSize,
            {
                from: signaturitUser
            }
        );

        await certifiedEmailContract.createEvent(
            certificateId,
            eventId,
            eventType,
            eventUserAgent,
            eventCreatedAt,
            {
                from: signaturitUser
            }
        );

        const signatureEvents = await userEventsContract.getPastEvents('CertifiedEmailCreated', {
            fromBlock: 0,
            toBlock: "latest"
        });

        const documentEvents = await userEventsContract.getPastEvents('CertificateCreated', {
            fromBlock: 0,
            toBlock: "latest"
        });

        const fileEvents = await userEventsContract.getPastEvents('FileCreated', {
            fromBlock: 0,
            toBlock: "latest"
        });

        const eventEvents = await userEventsContract.getPastEvents('EventCreated', {
            fromBlock: 0,
            toBlock: "latest"
        });

        const certificateAddress = await certifiedEmailContract.getCertificateByIndex(0);
        const fileAddress = await certifiedEmailContract.getFile(certificateId);
        const eventAddress = await certifiedEmailContract.getEvent(certificateId, eventId);

        assert.equal(signatureEvents.length, 1)
        assert.equal(signatureEvents[0].returnValues[0], certifiedEmailContract.address);

        assert.equal(documentEvents.length, 1)
        assert.equal(documentEvents[0].returnValues[0], certificateAddress);

        assert.equal(eventEvents.length, 1)
        assert.equal(eventEvents[0].returnValues[0], eventAddress);

        assert.equal(fileEvents.length, 1)
        assert.equal(fileEvents[0].returnValues[0], fileAddress);
    });

    it("Deploy certified file and expect to be notified", async () => {
        await certifiedFileContract.notifyEvent(
            {
                from: signaturitUser
            }
        );
        const events = await userEventsContract.getPastEvents('CertifiedFileCreated', {
            fromBlock: 0,
            toBlock: "latest"
        });
        
        assert.equal(events.length, 1)
        assert.equal(events[0].returnValues[0], certifiedFileContract.address);
    });
})