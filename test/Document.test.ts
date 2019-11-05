contract('Document', async (accounts) => {
    const ArtifactUser = artifacts.require('SignaturitUser');
    const ArtifactFile      = artifacts.require('File');
    const ArtifactEvent     = artifacts.require('Event');
    const ArtifactDocument = artifacts.require('Document');
    const ArtifactSignature = artifacts.require('Signature');
    const ArtifactSignatureDeployer = artifacts.require('SignatureDeployer');

    const v4 = require("uuid").v4;

    let userContract;
    let fileContract;
    let eventContract;
    let documentContract;
    let signatureDeployer;
    let signatureContract;

    let documentContractAddress;

    const signaturitAddress = accounts[0];
    const signatureOwner = accounts[1]
    const ownerAddress = accounts[2];
    const invalidAddress = accounts[4];

    const documentId = v4();
    const signatureType = 'advanced';
    const cancelReason = 'Cancel reason';
    const declineReason = 'Decline reason';
    const signedAt = Date.now();
    const createdAt = Date.now();

    const fileId = v4();
    const signatureId = v4();
    const fileName = 'Test.pdf';
    const fileHash = 'File hash';
    const fileSize = 123;

    const eventOneId = v4();
    const eventTwoId = v4();
    const eventType = 'document_signed';
    const userAgent = 'User Agent';

    beforeEach(async () => {
        signatureDeployer = await ArtifactSignatureDeployer.new();

        userContract = await ArtifactUser.new(
            signatureOwner,
            {
                from: signaturitAddress
            }
        );

        signatureContract = await ArtifactSignature.new(
            signatureId,
            signatureDeployer.address,
            Date.now(),
            signatureOwner,
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

        await signatureContract.createDocument(
            documentId,
            signatureType,
            createdAt,
            {
                from: signaturitAddress
            }
        );

        documentContractAddress = await signatureContract.getDocument(documentId);

        documentContract = await ArtifactDocument.at(documentContractAddress);
    });

    it('Check if it deploy correctly', async () => {
        assert.ok(documentContract.address);
    });

    it('Try to setFileHash as signature role, expect to pass', async() => {
        await signatureContract.setSignedFileHash(
            documentId,
            fileHash,
            {from: signaturitAddress}
        );

        const readFileHash = await documentContract.signedFileHash();

        assert.equal(fileHash, readFileHash);
    });

    it('Try to setFileHash with not signature role, expect exception', async() => {
        try {
            await signatureContract.setSignedFileHash(
                documentId,
                fileHash,
                {from: invalidAddress}
            );

            assert.fail('Invalid input parameter');
        } catch(error) {
            assert.include(
                error.message,
                'Only Signaturit account can perform this action'
            );
        }
    });

    it('Create an instance of file', async() => {
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

        const readFileAddress = await documentContract.file();
        fileContract = await ArtifactFile.at(readFileAddress);

        const readFileId = await fileContract.id();
        const readFileSize = await fileContract.size();

        assert.equal(fileId, readFileId);
        assert.equal(fileSize, readFileSize.toNumber());
    });

    it("Sign a document", async () => {
        await signatureContract.setDocumentOwner(
            documentId, 
            ownerAddress,
            {
                from: signaturitAddress
            }
        );

        await documentContract.sign(
            signedAt,
            {
                from: ownerAddress
            }
        );

        const readDocumentSigned = await documentContract.signed();

        assert.isTrue(readDocumentSigned);
    });

    it("Cancel a document", async () => {
        await signatureContract.cancelDocument(
            documentId,
            cancelReason,
            {
                from: signatureOwner
            }
        );

        const readDocumentCanceled = await documentContract.canceled();
        const readDocumentCancelReason = await documentContract.cancelReason();

        assert.isTrue(readDocumentCanceled);
        assert.equal(cancelReason, readDocumentCancelReason);
    });

    it("Cancel a document from other account ", async () => {
        try {
            await signatureContract.cancelDocument(
                documentId,
                cancelReason,
                {
                    from: invalidAddress
                }
            );

            assert.fail('This documentContract must fail');
        } catch (error) {
            assert.include(
                error.message,
                'Only the owner account can perform this action'
            );
        }
    });

    it("Decline a document", async () => {
        await signatureContract.setDocumentOwner(documentId, ownerAddress);

        await documentContract.decline(
            declineReason,
            {
                from: ownerAddress
            }
        );

        const readDocumentDeclined = await documentContract.declined();
        const readDocumentDeclineReason = await documentContract.declineReason();

        assert.isTrue(readDocumentDeclined);
        assert.equal(declineReason, readDocumentDeclineReason);
    });

    it("Decline a document from other account ", async () => {
        try {
            await documentContract.decline(
                declineReason,
                {
                    from: invalidAddress
                }
            );

            assert.fail('This documentContract must fail');
        } catch (error) {
            assert.include(
                error.message,
                'Only the owner account can perform this action.'
            );
        }
    });

    it("Try to sign a document after cancel", async () => {
        try {
            await signatureContract.setDocumentOwner(documentId, ownerAddress);

            await signatureContract.cancelDocument(
                documentId,
                cancelReason,
                {
                    from: signatureOwner
                }
            );

            await documentContract.sign(
                signedAt,
                {
                    from: ownerAddress
                }
            );

        } catch (error) {
            assert.include(
                'Returned error: VM Exception while processing transaction: revert',
                error.message,
            )
        }
    });

    it("Try to cancel a signed document", async () => {
        try {
            await signatureContract.setDocumentOwner(documentId, ownerAddress);

            await documentContract.sign(
                signedAt,
                {
                    from: ownerAddress
                }
            );

            await signatureContract.cancelDocument(
                documentId,
                cancelReason,
                {
                    from: signatureOwner
                }
            );

            assert.fail('The documentContract cant be canceled');

        } catch (error) {
            assert.include(
                error.message,
                "revert"
            );
        }
    })

    it("Try to sign the document after decline", async () => {
        try {
            await signatureContract.setDocumentOwner(documentId, ownerAddress);

            await documentContract.decline('Decline documentContract', {
                from: ownerAddress
            });

            await documentContract.sign(
                signedAt,
                {
                    from: ownerAddress
                }
            );

        } catch (error) {
            assert.include(
                'Returned error: VM Exception while processing transaction: revert',
                error.message
            )
        }
    });

    it("Try to decline a signed document", async () => {
        try {
            await signatureContract.setDocumentOwner(documentId, ownerAddress);

            await documentContract.sign(
                signedAt,
                {
                    from: ownerAddress
                }
            );

            await documentContract.decline('Cancel documentContract', {
                from: ownerAddress
            });

            assert.fail('The documentContract cant be declined');

        } catch (error) {
            assert.include(
                error.message,
                "revert"
            )
        }
    });

    it("Create event on the document", async () => {
        await signatureContract.createEvent(
            documentId,
            eventOneId,
            eventType,
            userAgent,
            createdAt,
            {
                from: signaturitAddress
            }
        );

        const readEventsLength = await documentContract.getEventsSize();

        assert.equal(readEventsLength, 1);
    });

    it("Create two event on the document", async () => {
        signatureContract.createEvent(
            documentId,
            eventOneId,
            eventType,
            userAgent,
            createdAt,
            {
                from: signaturitAddress
            }
        );

        signatureContract.createEvent(
            documentId,
            eventTwoId,
            eventType,
            userAgent,
            createdAt,
            {
                from: signaturitAddress
            }
        );

        const readEventsLength = await documentContract.getEventsSize();

        assert.equal(readEventsLength, 2);
    });

    it("Get existing event from the document", async () => {
        signatureContract.createEvent(
            documentId,
            eventOneId,
            eventType,
            userAgent,
            createdAt,
            {
                from: signaturitAddress
            }
        );

        signatureContract.createEvent(
            documentId,
            eventTwoId,
            eventType,
            userAgent,
            createdAt,
            {
                from: signaturitAddress
            }
        );

        const readEventAddress = await documentContract.getEvent(eventOneId);

        eventContract = await ArtifactEvent.at(readEventAddress);

        const readEventId = await eventContract.id.call();
        const readEventtype = await eventContract.eventType.call();
        const readUserAgent = await eventContract.userAgent.call();
        const readEventCreatedAt = await eventContract.createdAt.call();

        assert.equal(readEventId, eventOneId);
        assert.equal(readEventtype, eventType);
        assert.equal(readUserAgent, userAgent);
        assert.equal(readEventCreatedAt.toNumber(), createdAt);
    });

    it("Get non existing event from the document", async () => {
        signatureContract.createEvent(
            documentId,
            eventOneId,
            eventType,
            userAgent,
            createdAt,
            {
                from: signaturitAddress
            }
        );

        try {
            await documentContract.getEvent(eventTwoId);
        } catch (error) {
            assert.include(
                error.message,
                "Returned error: VM Exception while processing transaction: revert"
            );
        }
    });
});
