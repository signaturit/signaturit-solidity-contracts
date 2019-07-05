contract('Signature', async (accounts) => {
    const ArtifactFile      = artifacts.require('File');
    const ArtifactUser      = artifacts.require('User');
    const ArtifactEvent     = artifacts.require('Event');
    const ArtifactDocument  = artifacts.require('Document');
    const ArtifactSignature = artifacts.require('Signature');
    const ArtifactSignatureDeployer = artifacts.require('SignatureDeployer');

    const v4 = require("uuid").v4;

    let userContract;
    let signatureContract;
    let signatureDeployer;

    const signaturitAddress = accounts[0];
    const signatureOwner = accounts[1];
    const documentOwnerAddress = accounts[2];
    const invalidAddress = accounts[3];
    const userAddress = accounts[4];

    const fileId = v4();
    const fileName = 'File name';
    const fileHash = 'File hash';
    const fileSize = 123;

    const eventId = v4();

    const documentId = v4();
    const documentSignatureType = 'advanced';
    const notExistingDocumentId = v4();
    const signedFileHash = 'Signed file hash';
    const cancelReason = 'Cancel reason';
    const signedAt = Date.now();
    const createdAt = Date.now();

    const signatureId = v4();
    const signatureType = 'advanced';

    const eventType = 'document opened';
    const eventUserAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.90 Safari/537.36';

    beforeEach(async () => {
        signatureDeployer = await ArtifactSignatureDeployer.new({from: signaturitAddress});

        userContract = await ArtifactUser.new(
            userAddress,
            {
                from: signaturitAddress
            }
        )

        signatureContract = await ArtifactSignature.new(
            signatureId,
            signatureDeployer.address,
            Date.now(),
            {
                from: signaturitAddress
            }
        );

        await signatureContract.setSignatureOwner(
            signatureOwner,
            userContract.address,
            {
                from: signaturitAddress
            }
        );
    });

    it('Check the address of the signature', async () => {
        assert.ok(signatureContract.address);
    });

    it('Check the signature id', async () => {
        const readContractId = await signatureContract.id();

        assert.equal(signatureId, readContractId);
    });

    it('Add owner to the signature contract from signaturit account', async () => {

        await signatureContract.setSignatureOwner(
            signatureOwner,
            userContract.address,
            {
                from: signaturitAddress
            }
        );

        const readSignature = await userContract.getSignature(0);
        const readOwnerAddress = await signatureContract.owner();

        assert.equal(signatureOwner, readOwnerAddress);
        assert.equal(readSignature.adr, signatureContract.address);
    });

    it('Add owner to the signature contract from invalid signaturit account', async () => {
        try {
            await signatureContract.setSignatureOwner(
                signatureOwner,
                signatureContract.address,
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

    it('Create new document', async () => {
        const transaction = await signatureContract.createDocument(
            documentId,
            signatureType,
            createdAt,
            {
                from: signaturitAddress
            }
        );

        const readDocument = await userContract.getDocument(0);

        const readDocumentAddress = await signatureContract.getDocument(documentId);
        const documentContract = await ArtifactDocument.at(readDocumentAddress);

        const readDocumentId = await documentContract.id();
        const readDocumentSignatureType = await documentContract.signatureType()
        const readCreatedAt = await documentContract.createdAt();
        const readDocumentsSize = await signatureContract.getDocumentsSize();

        assert.equal(readDocument.adr, readDocumentAddress);
        assert.equal(readDocumentId, documentId);
        assert.equal(signatureType, readDocumentSignatureType);
        assert.equal(createdAt, readCreatedAt);
        assert.equal(readDocumentsSize, 1);
    });

    it('Create new document and cancel it', async () => {
        const transaction = await signatureContract.createDocument(
            documentId,
            signatureType,
            createdAt,
            {
                from: signaturitAddress
            }
        );

        await signatureContract.cancelDocument(
            documentId,
            cancelReason,
            {
                from: signatureOwner
            }
        )

        const readDocument = await userContract.getDocument(0);

        const readDocumentAddress = await signatureContract.getDocument(documentId);
        const documentContract = await ArtifactDocument.at(readDocumentAddress);

        const readCancelStatus = await documentContract.canceled();

        assert.ok(readCancelStatus);
    });


    it('Access to unexisting document', async () => {
        try {
            await signatureContract.getDocument(notExistingDocumentId);

            assert.fail("The document don't exist");
        } catch (error) {
            assert.include(
                error.message,
                "Returned error: VM Exception while processing transaction: revert",
            );
        }
    });

    it('Add owner to existing document', async () => {
        await signatureContract.createDocument(
            documentId,
            signatureType,
            createdAt,
            {
                from: signaturitAddress
            }

        );

        signatureContract.setDocumentOwner(
            documentId,
            documentOwnerAddress
        );
    });

    it('Sign document with from the owner address', async () => {
        await signatureContract.createDocument(
            documentId,
            signatureType,
            createdAt,
            {
                from: signaturitAddress
            }

        );

        signatureContract.setDocumentOwner(
            documentId,
            documentOwnerAddress
        );

        const readDocumentAddress = await signatureContract.getDocument(documentId);
        const documentContract = await ArtifactDocument.at(readDocumentAddress);

        await documentContract.sign(
            signedAt,
            {
                from: documentOwnerAddress
            }
        );

        const readDocumentSigned = await documentContract.signed();

        assert.isTrue(readDocumentSigned);
    });

    it('Sign document with invalid owner address', async () => {
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
            documentOwnerAddress,
            {
                from: signaturitAddress
            }
        );

        try {
            const readDocumentAddress = await signatureContract.getDocument(documentId);
            const documentContract = await ArtifactDocument.at(readDocumentAddress);

            await documentContract.sign(
                signedAt,
                {
                    from: invalidAddress
                }
            );

            assert.fail("This address can't sign the document")
        } catch (error) {
            assert.include(
                error.message,
                'Only the owner account can perform this action.',
            );
        }
    });

    it('Add file to uncreated document; the document must be created', async () => {
        await signatureContract.createFile(
            documentId,
            fileId,
            fileName,
            fileHash,
            createdAt,
            fileSize
        );

        const readDocumentAddress = await signatureContract.getDocument(documentId);
        const readFile = await userContract.getSignatureFile(0);

        const documentContract = await ArtifactDocument.at(readDocumentAddress);

        const readDocumentId = await documentContract.id();
        const readFileAddress = await documentContract.file();

        assert.equal(documentId, readDocumentId);
        assert.equal(readFile.adr, readFileAddress);
    });

    it('Add file to uncreated document and after create the document', async () => {
        await signatureContract.createFile(
            documentId,
            fileId,
            fileName,
            fileHash,
            createdAt,
            fileSize
        );

        const readFirstDocumentAddress = await signatureContract.getDocument(documentId);

        await signatureContract.createDocument(
            documentId,
            documentSignatureType,
            createdAt
        );

        const readSecondDocumentAddress = await signatureContract.getDocument(documentId);

        assert.equal(readFirstDocumentAddress, readSecondDocumentAddress);
    });

    it('Retrieve a created file', async () => {
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

        const readFileAddress = await signatureContract.getFile.call(documentId);
        const fileContract = await ArtifactFile.at(readFileAddress);

        const readFileName = await fileContract.name();
        const readFileId = await fileContract.id();

        assert.equal(fileName, readFileName);
        assert.equal(fileId, readFileId);
    });

    it('Add file to a created document the document must be created', async () => {
        await signatureContract.createDocument(
            documentId,
            documentSignatureType,
            createdAt
        );

        const readFirstDocumentAddress = await signatureContract.getDocument(documentId);

        await signatureContract.createFile(
            documentId,
            fileId,
            fileName,
            fileHash,
            createdAt,
            fileSize
        );

        const readSecondDocumentAddress = await signatureContract.getDocument(documentId);

        const documentContract = await ArtifactDocument.at(readSecondDocumentAddress);
        const readDocumentId = await documentContract.id();

        assert.equal(readFirstDocumentAddress, readSecondDocumentAddress);
        assert.equal(documentId, readDocumentId);
    });

    it('Add event to uncreated document', async () => {
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

        const readEvent = await userContract.getSignatureEvent(0);

        const readEventAddress = await signatureContract.getEvent.call(
            documentId,
            eventId
        );

        const eventContract = await ArtifactEvent.at(readEventAddress);

        const readEventId = await eventContract.id.call();
        const readEventType = await eventContract.eventType.call();

        assert.equal(readEvent.adr, readEventAddress);
        assert.equal(eventId,readEventId);
        assert.equal(eventType, readEventType);
    });

    it('Set signed file hash as not signaturit role, expect exception', async () => {
        try {
            await signatureContract.setSignedFileHash(
                documentId,
                signedFileHash,
                {
                    from: signatureOwner
                }
            );

            assert.fail("This account can't set the signed file hash");
        } catch (error) {
            assert.include(
                error.message,
                'Only Signaturit account can perform this action.'
            );
        }
    });

    it('Set file signed hash as signaturit role, expect to pass', async () => {
        const transaction = await signatureContract.setSignedFileHash(
            documentId,
            signedFileHash,
            {
                from: signaturitAddress
            }
        );

        assert.ok(transaction.receipt.status);
    });
});
