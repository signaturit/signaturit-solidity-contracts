contract('Document: inputs validation', async (accounts) => {
    const ArtifactFile      = artifacts.require('File');
    const ArtifactEvent     = artifacts.require('Event');
    const ArtifactDocuments = artifacts.require('Document');
    const ArtifactSignatureDeployer = artifacts.require('SignatureDeployer');

    const v4 = require("uuid").v4;

    let fileContract;
    let eventContract;
    let documentContract;
    let signatureDeployer;

    const signatureAddress = accounts[0];
    const ownerAddress = accounts[1];
    const signerAddress = accounts[2];
    const invalidAddress = accounts[3];

    const documentId = v4();
    const signatureType = 'advanced';
    const cancelReason = 'Cancel reason';
    const declineReason = 'Decline reason';
    const signedAt = Date.now();
    const finishedAt = Date.now();
    const createdAt = Date.now();

    const fileId = v4();
    const fileName = 'Test.pdf';
    const fileHash = 'File hash';
    const fileSize = 123;

    const eventOneId = v4();
    const eventTwoId = v4();
    const eventType = 'document_signed';
    const userAgent = 'User Agent';

    beforeEach(async () => {
        signatureDeployer = await ArtifactSignatureDeployer.new();

        documentContract = await ArtifactDocuments.new(
            documentId,
            signatureDeployer.address,
            {
                from: signatureAddress
            }
        );
    });

    it('Check if it deploy correctly', async () => {
        assert.ok(documentContract.address);
    });

    it('Try to init with not signature role, expect exception', async() => {
        try {
            await documentContract.init(
                signatureType,
                finishedAt,
                {from: ownerAddress}
            );

            assert.fail('Invalid input parameter');
        } catch(error) {
            assert.include(
                error.message,
                'Only the Signature account can perform this action.'
            );
        }
    });

    it('Try to init as signature role, expect to pass', async() => {
        await documentContract.init(
            signatureType,
            createdAt,
            {from: signatureAddress}
        );

        const readCreatedAt = await documentContract.createdAt();

        assert.equal(createdAt, readCreatedAt);
    });

    it('Try to setFileHash as signature role, expect to pass', async() => {
        await documentContract.setFileHash(
            fileHash,
            {from: signatureAddress}
        );

        const readFileHash = await documentContract.signedFileHash();

        assert.equal(fileHash, readFileHash);
    });

    it('Try to setFileHash with not signature role, expect exception', async() => {
        try {
            await documentContract.setFileHash(
                fileHash,
                {from: signerAddress}
            );

            assert.fail('Invalid input parameter');
        } catch(error) {
            assert.include(
                error.message,
                'Only the Signature account can perform this action.'
            );
        }
    });

    it('Create an instance of file', async() => {
        await documentContract.createFile(
            fileId,
            fileName,
            fileHash,
            createdAt,
            fileSize
        );

        const readFileAddress = await documentContract.file();
        fileContract = await ArtifactFile.at(readFileAddress);

        const readFileId = await fileContract.id();
        const readFileSize = await fileContract.size();

        assert.equal(fileId, readFileId);
        assert.equal(fileSize, readFileSize.toNumber());
    });

    it("Sign a document", async () => {
        await documentContract.setOwner(ownerAddress);

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
        await documentContract.cancel(
            cancelReason,
            {
                from: signatureAddress
            }
        );

        const readDocumentCanceled = await documentContract.canceled();
        const readDocumentCancelReason = await documentContract.cancelReason();

        assert.isTrue(readDocumentCanceled);
        assert.equal(cancelReason, readDocumentCancelReason);
    });

    it("Cancel a document from other account ", async () => {
        try {
            await documentContract.cancel(
                cancelReason,
                {
                    from: invalidAddress
                }
            );

            assert.fail('This documentContract must fail');
        } catch (error) {
            assert.include(
                error.message,
                'Only the Signature account can perform this action.'
            );
        }
    });

    it("Decline a document", async () => {
        await documentContract.setOwner(ownerAddress);

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
            await documentContract.setOwner(ownerAddress);

            await documentContract.cancel('Cancel documentContract', {
                from: signatureAddress
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
                error.message,
            )
        }
    });

    it("Try to cancel a signed document", async () => {
        try {
            await documentContract.setOwner(ownerAddress);

            await documentContract.sign(
                signedAt,
                {
                    from: ownerAddress
                }
            );

            await documentContract.cancel('Cancel documentContract', {
                from: signatureAddress
            });

            assert.fail('The documentContract cant be canceled');

        } catch (error) {
            assert.include(
                error.message,
                "Document is already signed, you can't cancel it."
            );
        }
    })

    it("Try to sign the document after decline", async () => {
        try {
            await documentContract.setOwner(ownerAddress);

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
            await documentContract.setOwner(ownerAddress);

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
                "Document is already signed, you can't decline it."
            )
        }
    });

    it("Create event on the document", async () => {
        await documentContract.createEvent(
            eventOneId,
            eventType,
            userAgent,
            createdAt,
            {
                from: signatureAddress
            }
        );

        const readEventsLength = await documentContract.getEventsSize();

        assert.equal(readEventsLength, 1);
    });

    it("Create two event on the document", async () => {
        documentContract.createEvent(
            eventOneId,
            eventType,
            userAgent,
            createdAt,
            {
                from: signatureAddress
            }
        );

        documentContract.createEvent(
            eventTwoId,
            eventType,
            userAgent,
            createdAt,
            {
                from: signatureAddress
            }
        );

        const readEventsLength = await documentContract.getEventsSize();

        assert.equal(readEventsLength, 2);
    });

    it("Get existing event from the document", async () => {
        documentContract.createEvent(
            eventOneId,
            eventType,
            userAgent,
            createdAt,
            {
                from: signatureAddress
            }
        );

        documentContract.createEvent(
            eventTwoId,
            eventType,
            userAgent,
            createdAt,
            {
                from: signatureAddress
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
        documentContract.createEvent(
            eventOneId,
            eventType,
            userAgent,
            createdAt,
            {
                from: signatureAddress
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
