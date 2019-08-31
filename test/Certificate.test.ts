contract('Certificate', async (accounts) => {
    const ArtifactCertificate   = artifacts.require('Certificate');
    const ArtifactFile          = artifacts.require('File');
    const ArtifactEvent         = artifacts.require('Event');
    const ArtifactCertifiedEmailDeployer = artifacts.require('CertifiedEmailDeployer');

    const v4 = require("uuid").v4;

    const certifiedEmailAddress = accounts[0];
    const ownerAddress      = accounts[1];
    const invalidAddress    = accounts[2];

    const nullAddress = '0x0000000000000000000000000000000000000000';

    let certificateContract;
    let certifiedEmailDeployer;

    const certificateId = v4();
    const createdAt = Date.now();

    const eventId = v4();
    const eventType = 'email_opened';
    const userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.90 Safari/537.36';

    const fileId = v4();
    const fileHash = 'File hash';
    const fileName = 'Test.pdf';
    const fileSize = 123;

    beforeEach(async () => {
        certifiedEmailDeployer = await ArtifactCertifiedEmailDeployer.new();

        certificateContract = await ArtifactCertificate.new(
            certificateId,
            certifiedEmailDeployer.address,
            {
                from: certifiedEmailAddress
            }
        )
    });

    it('Check if it deploy correctly', async () => {
        assert.ok(certificateContract.address);
    });

    it('Init the contracts as CertifiedEmail account, expect to pass', async () => {
        await certificateContract.init(
            ownerAddress,
            createdAt,
            {
                from: certifiedEmailAddress
            }
        );

        const readCreatedAt = await certificateContract.createdAt();
        const readOwnerAddress = await certificateContract.owner();
        const readCertificateId = await certificateContract.id();

        assert.equal(createdAt, readCreatedAt);
        assert.equal(ownerAddress, readOwnerAddress);
        assert.equal(certificateId, readCertificateId);
    });

    it('Init the contracts as not CertifiedEmail account, expect to exception', async () => {
        
        try {
            await certificateContract.init(
                ownerAddress,
                createdAt,
                {
                    from: invalidAddress
                }
            );    
        } catch(error) {
            assert.include(
                error.message,
                "Only CertifiedEmail account can perform this action"
            )
        }
    });

    it('Create an instance of file', async() => {
        await certificateContract.createFile(
            fileHash,
            fileId,
            fileName,
            createdAt,
            fileSize,
            {
                from: certifiedEmailAddress
            }
        );

        const fileAddress = await certificateContract.file();
        const file = await ArtifactFile.at(fileAddress);

        const readFileHash = await file.originalFileHash();
        const readFileId = await file.id();
        const readFileSize = await file.size();

        assert.equal(fileHash, readFileHash);
        assert.equal(fileId, readFileId);
        assert.equal(fileSize, readFileSize);
    });

    it('Create an instance of file from other account than the CertifiedEmail contract', async() => {
        try {
            await certificateContract.createFile(
                fileHash,
                fileId,
                fileName,
                createdAt,
                fileSize,
                {
                    from: invalidAddress
                }
            );

            assert.fail("It should have thrown");
        } catch (error) {
            assert.include(
                error.message,
                'Only CertifiedEmail account can perform this action.'
            );
        }
    });

    it('Add new event to the certificate', async() => {
        await certificateContract.createEvent(
            eventId,
            eventType,
            userAgent,
            createdAt,
            {
                from: certifiedEmailAddress
            }
        );

        assert.ok('Event created successfully');
    });

    it('Add new event  as not CertifiedEmail account, expect to exception', async () => {
        
        try {
            await certificateContract.createEvent(
                eventId,
                eventType,
                userAgent,
                createdAt,
                {
                    from: invalidAddress
                }
            );    
        } catch(error) {
            assert.include(
                error.message,
                "Only CertifiedEmail account can perform this action"
            )
        }
    });

    it('Create duplicated event', async() => {
        try {
            await certificateContract.createEvent(
                eventId,
                eventType,
                userAgent,
                createdAt,
                {
                    from: certifiedEmailAddress
                }
            );

            await certificateContract.createEvent(
                eventId,
                eventType,
                userAgent,
                createdAt,
                {
                    from: certifiedEmailAddress
                }
            );

            assert.fail("It should have thrown");
        } catch (error){
            assert.include(
                error.message,
                "The current event already exists."
            )
        }

    });

    it('Retrieve no storerd event', async() => {
        const eventId = v4();

        const readAddress = await certificateContract.getEvent(eventId);

        assert.equal(readAddress, nullAddress);
    });

    it('Retrieve event data', async() => {
        await certificateContract.createEvent(
            eventId,
            eventType,
            userAgent,
            createdAt,
            {
                from: certifiedEmailAddress
            }
        );

        const eventAddress = await certificateContract.getEvent(eventId);

        const eventContract = await ArtifactEvent.at(eventAddress);

        const readEventId = await eventContract.id();
        const readEventType = await eventContract.eventType();
        const readUserAgent = await eventContract.userAgent();
        const readEventCreatedAt = await eventContract.createdAt();
        const readEventSize = await certificateContract.getEventsSize();

        assert.equal(eventId, readEventId);
        assert.equal(eventType, readEventType);
        assert.equal(userAgent, readUserAgent);
        assert.equal(createdAt, readEventCreatedAt.toNumber());
        assert.equal(1, readEventSize);
    });
});
