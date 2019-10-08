contract('Certified Email', async (accounts) => {
    const ArtifactUser  = artifacts.require('SignaturitUser');
    const ArtifactEvent = artifacts.require('Event');
    const ArtifactFile  = artifacts.require('File');
    const ArtifactCertificate            = artifacts.require('Certificate');
    const ArtifactCertifiedEmail         = artifacts.require('CertifiedEmail');
    const ArtifactCertifiedEmailDeployer = artifacts.require('CertifiedEmailDeployer');
    const ArtifactCertifiedEmailAggregator = artifacts.require('CertifiedEmailAggregator');

    const v4 = require("uuid").v4;

    let userContract;
    let fileContract;
    let eventContract;
    let certificateContract;
    let certifiedEmailContract;
    let certifiedEmailAggregatorContract;
    let certifiedEmailDeployer;

    const signaturitAddress = accounts[0];
    const ownerAddress      = accounts[1];
    const invalidAddress    = accounts[2];

    const invalidId = 'Invalid id';

    const certifiedEmailId = v4();
    const bodyHash = 'Body hash';
    const subjectHash = 'Subject hash';
    const deliveryType = 'email_delivered';
    const createdAt = Date.now()

    const fileId = v4();
    const fileName = 'File name';
    const fileHash = 'File hash';
    const fileSize = 123;
    const fileCreatedAt = Date.now();

    const eventId = v4();
    const eventType = 'created_at';
    const eventUserAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.90 Safari/537.36';

    const certificateId = v4();

    beforeEach(async () => {
        certifiedEmailDeployer = await ArtifactCertifiedEmailDeployer.new(
            {
                from: signaturitAddress
            }
        );

        userContract = await ArtifactUser.new(
            accounts[4],
            {
                from: signaturitAddress
            }
        )

        certifiedEmailAggregatorContract = await ArtifactCertifiedEmailAggregator.new(
            userContract.address,
            {
                from: signaturitAddress
            }
        )

        certifiedEmailContract = await ArtifactCertifiedEmail.new(
            certifiedEmailId,
            subjectHash,
            bodyHash,
            deliveryType,
            createdAt,
            certifiedEmailDeployer.address,
            signaturitAddress,
            userContract.address,
            {
                from: signaturitAddress
            }
        );

        await certifiedEmailContract.notifyCreation();
    });

    it('Check if it deploy correctly', async () => {
        assert.ok(certifiedEmailContract.address);
    });

    it('Check the owner address correctness', async () => {
        const readOwnerContractAddress = await certifiedEmailContract.owner();

        assert.equal(signaturitAddress, readOwnerContractAddress);
    });

    it('Check the stored constructor parameters correctness', async () => {
        const readCertifiedEmailId = await certifiedEmailContract.id();
        const readCertifiedEmailSubjectHash = await certifiedEmailContract.subjectHash();
        const readCertifiedEmailBodyHash = await certifiedEmailContract.bodyHash();
        const readCertifiedEmailDeliveryType = await certifiedEmailContract.deliveryType();
        const readCertifiedEmailCreatedAt = await certifiedEmailContract.createdAt();

        assert.equal(readCertifiedEmailId, certifiedEmailId);
        assert.equal(readCertifiedEmailSubjectHash, subjectHash);
        assert.equal(readCertifiedEmailBodyHash, bodyHash);
        assert.equal(readCertifiedEmailDeliveryType, deliveryType);
        assert.equal(createdAt, readCertifiedEmailCreatedAt );
    });

    it('Create certificate on the certified email and check stored parameters correctness', async () => {
        await certifiedEmailContract.createCertificate(
            certificateId,
            createdAt,
            ownerAddress, {
                from: signaturitAddress
            }
        );

        assert.ok('Contract deployed');
        
        const readSavedCertifiedEmail = await certifiedEmailAggregatorContract.getCertifiedEmail(0);

        const savedCertifiedEmailContract = await ArtifactCertifiedEmail.at(readSavedCertifiedEmail.addr);

        const readSavedCertificateAddress = await savedCertifiedEmailContract.getCertificate(certificateId)

        const readCertificateAddress = await certifiedEmailContract.getCertificate(certificateId);

        certificateContract = await ArtifactCertificate.at(readCertificateAddress);

        const readCertificateId = await certificateContract.id();
        const readCertificateCreatedAt = await certificateContract.createdAt();
        const readCertificatesSize = await certifiedEmailContract.getCertificatesSize();
        
        assert.equal(certificateId, readCertificateId);
        assert.equal(readSavedCertificateAddress, readCertificateAddress);
        assert.equal(createdAt, readCertificateCreatedAt);
        assert.equal(readCertificatesSize, 1);
    });

    it('Create certificate on the certified email from not Signaturit account, expect exception', async () => {
        try {
            await certifiedEmailContract.createCertificate(
                certificateId,
                createdAt,
                ownerAddress, {
                    from: invalidAddress
                }
            );

            assert.fail("This account can't add contracts")
        } catch (error) {
            assert.include(
                error.message,
                'Only Signaturit account can perform this action.',
            );
        }
    });

    it('Create certificate on the certified email twice, expect only one to be created', async () => {
        await certifiedEmailContract.createCertificate(
            certificateId,
            createdAt,
            ownerAddress, {
                from: signaturitAddress
            }
        );

        const readFirstCertificateAddress = await certifiedEmailContract.getCertificate(certificateId);

        await certifiedEmailContract.createCertificate(
            certificateId,
            createdAt,
            ownerAddress, {
                from: signaturitAddress
            }
        );

        const readSecondCertificateAddress = await certifiedEmailContract.getCertificate(certificateId);

        assert.equal(readFirstCertificateAddress, readSecondCertificateAddress);
    });

    it('Retrieve certificate from certificateId', async () => {
        await certifiedEmailContract.createCertificate(
            certificateId,
            createdAt,
            ownerAddress, {
                from: signaturitAddress
            }
        );

        const readCertificateAddress = await certifiedEmailContract.getCertificate(certificateId);

        certificateContract = await ArtifactCertificate.at(readCertificateAddress);

        const readCertificateContractId = await certificateContract.id();
        const readCertificateContractCreatedAt = await certificateContract.createdAt();
        const readCertificateOwner = await certificateContract.owner();

        assert.equal(certificateId, readCertificateContractId);
        assert.equal(createdAt, readCertificateContractCreatedAt);
        assert.equal(ownerAddress,readCertificateOwner);
    });

    it('Retrieve certificate from index', async () => {
        await certifiedEmailContract.createCertificate(
            certificateId,
            createdAt,
            ownerAddress, {
                from: signaturitAddress
            }
        );

        const readCertificateAddress = await certifiedEmailContract.getCertificateByIndex(0);
        const notExistingCertificateAddress = await certifiedEmailContract.getCertificateByIndex(1);

        certificateContract = await ArtifactCertificate.at(readCertificateAddress);

        const readCertificateContractId = await certificateContract.id();
        const readCertificateContractCreatedAt = await certificateContract.createdAt();
        const readCertificateOwner = await certificateContract.owner();

        assert.equal(certificateId, readCertificateContractId);
        assert.equal(createdAt, readCertificateContractCreatedAt);
        assert.equal(ownerAddress,readCertificateOwner);
        
        assert.equal(notExistingCertificateAddress, '0x0000000000000000000000000000000000000000');
    });

    it('Retrieve uncreated certificate from certificateId', async() => {
        try {
            await certifiedEmailContract.getCertificate(invalidId);
        } catch(error) {
            assert.include(
                error.message,
                "The certificate with this id doesn't exist"
            );
        }
    });

    it('Get event of uncreated certificate, expect exception', async() => {
        try {
            await certifiedEmailContract.getEvent(invalidId, eventId);
        } catch(error) {
            assert.include(
                error.message,
                "The certificate with this id doesn't exist"
            );
        }
    });

    it('Get file of uncreated certificate, expect exception', async() => {
        try {
            await certifiedEmailContract.getFile(invalidId);
        } catch(error) {
            assert.include(
                error.message,
                "The certificate with this id doesn't exist"
            );
        }
    });

    it('Create event on created certificate and check parameters correctness', async () => {
        await certifiedEmailContract.createCertificate(
            certificateId,
            createdAt,
            ownerAddress, 
            {
                from: signaturitAddress
            }
        );

        await certifiedEmailContract.createEvent(
            certificateId,
            eventId,
            eventType,
            eventUserAgent,
            createdAt
        );

        const readEventAddress = await certifiedEmailContract.getEvent.call(certificateId,eventId);

        eventContract = await ArtifactEvent.at(readEventAddress);

        const readEventId = await eventContract.id();
        const readEventType = await eventContract.eventType();
        const readUserAgent = await eventContract.userAgent();
        const readEventCreatedAt = await eventContract.createdAt();

        assert.equal(eventId, readEventId);
        assert.equal(eventType, readEventType);
        assert.equal(eventUserAgent, readUserAgent);
        assert.equal(createdAt, readEventCreatedAt.toNumber());
    });

    it('notify creation from signaturit account', async () => {

        await certifiedEmailContract.notifyCreation(
            {
                from: signaturitAddress
            }
        );

        const readCertifiedEmail = await certifiedEmailAggregatorContract.getCertifiedEmail(0);

        const readOwnerAddress = await certifiedEmailContract.owner();

        assert.equal(signaturitAddress, readOwnerAddress);
        assert.equal(readCertifiedEmail.addr, certifiedEmailContract.address);
    });

    it('notify creation from from invalid signaturit account', async () => {
        try {
            await certifiedEmailContract.notifyCreation(
                {
                    from: invalidAddress
                }
            );

            assert.fail("This account can't add the owner");
        } catch (error) {
            assert.include(
                error.message,
                'Only Signaturit account can perform this action.',
            );
        }
    });

    it('Create event on uncreated certificate, expect it to be created', async () => {
        await certifiedEmailContract.createEvent(
            certificateId,
            eventId,
            eventType,
            eventUserAgent,
            createdAt
        );

        const readEventAddress = await certifiedEmailContract.getEvent.call(certificateId,eventId);
        const readSavedCertifiedEmail = await certifiedEmailAggregatorContract.getCertifiedEmail(0);
        const readCertifiedEmail = await ArtifactCertifiedEmail.at(readSavedCertifiedEmail.addr);

        const readSavedEventAddress = await readCertifiedEmail.getEvent(certificateId, eventId);

        eventContract = await ArtifactEvent.at(readEventAddress);

        const readEventId = await eventContract.id();
        const readEventType = await eventContract.eventType();
        const readUserAgent = await eventContract.userAgent();
        const readEventCreatedAt = await eventContract.createdAt();

        assert.equal(eventId, readEventId);
        assert.equal(eventType, readEventType);
        assert.equal(eventUserAgent, readUserAgent);
        assert.equal(readSavedEventAddress, readEventAddress);
        assert.equal(createdAt, readEventCreatedAt.toNumber());
    });

    it('Create event as not Signaturit account, expect exception', async() => {
        try {
            await certifiedEmailContract.createEvent(
                certificateId,
                eventId,
                eventType,
                eventUserAgent,
                createdAt,
                {
                    from: invalidAddress
                }
            );
        } catch(error) {
            assert.include(
                error.message,
                "Only Signaturit account can perform this action"
            );
        }
    });

    it('Add file to uncreated certificate, expect it to be created', async () => {
        await certifiedEmailContract.createFile(
            certificateId,
            fileHash,
            fileId,
            fileName,
            fileCreatedAt,
            fileSize
        );

        const readCertificateAddress = await certifiedEmailContract.getCertificate(certificateId);
        const readSavedCertifiedEmail = await certifiedEmailAggregatorContract.getCertifiedEmail(0);

        const readCertifiedEmail = await ArtifactCertifiedEmail.at(readSavedCertifiedEmail.addr);
        const readSavedFileAddress = await readCertifiedEmail.getFile(certificateId);

        certificateContract = await ArtifactCertificate.at(readCertificateAddress);
        const readCurrentCertificateId = await certificateContract.id();
        const readFileAddress = await certificateContract.file();

        assert.equal(certificateId, readCurrentCertificateId);
        assert.equal(readSavedFileAddress, readFileAddress);
    });

    it('Add file to uncreated certificate and after create the certificate', async () => {
        await certifiedEmailContract.createFile(
            certificateId,
            fileHash,
            fileId,
            fileName,
            fileCreatedAt,
            fileSize
        );

        const readFirstCertificateAddress = await certifiedEmailContract.getCertificate(certificateId);

        await certifiedEmailContract.createCertificate(
            certificateId,
            createdAt,
            ownerAddress
        );

        const readSecondCertificateAddress = await certifiedEmailContract.getCertificate(certificateId);

        assert.equal(readFirstCertificateAddress, readSecondCertificateAddress);
    });

    it('Retrieve a created file', async () => {
        await certifiedEmailContract.createFile(
            certificateId,
            fileHash,
            fileId,
            fileName,
            fileCreatedAt,
            fileSize
        );

        const readFileAddress = await certifiedEmailContract.getFile.call(certificateId);
        fileContract = await ArtifactFile.at(readFileAddress);

        const readFileName = await fileContract.name();
        const readFileId = await fileContract.id();

        assert.equal(fileName, readFileName);
        assert.equal(fileId, readFileId);
    });

    it('Add file to a created certificate', async () => {
        await certifiedEmailContract.createCertificate(
            certificateId,
            createdAt,
            ownerAddress
        );

        const readFirstCertificateAddress = await certifiedEmailContract.getCertificate(certificateId);

        await certifiedEmailContract.createFile(
            certificateId,
            fileHash,
            fileId,
            fileName,
            fileCreatedAt,
            fileSize
        );

        const readSecondCertificateAddress = await certifiedEmailContract.getCertificate(certificateId);

        const certificate = await ArtifactCertificate.at(readSecondCertificateAddress);
        const readCurrentCertificateId = await certificate.id();

        assert.equal(readFirstCertificateAddress, readSecondCertificateAddress);
        assert.equal(certificateId, readCurrentCertificateId);
    });
});
