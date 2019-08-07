contract('User', async (accounts) => {
    const ArtifactUser = artifacts.require('User');

    const v4 = require("uuid").v4;

    let userContract;

    const signaturitAddress = accounts[0];
    const signatureAddress = accounts[1];
    const invalidAddress = accounts[2];
    const userAddress = accounts[3];
    const documentAddress = accounts[4];
    const fileAddress = accounts[5];
    const certifiedEmailAddress = accounts[6];
    const certificateAddress = accounts[7];
    const certifiedFileAddress = accounts[8];
    const anotherCertifiedFileAddress = accounts[9];
    const eventAddress = certifiedFileAddress;

    const clauseType = "clauseType";
    const notificationType = "notificationType";

    const signatureId = v4();

    const certifiedFileId = v4();
    const anotherCertifiedFileId = v4();

    const certifiedEmailId = v4();

    const certificateUserKey = 'key'

    const fileSignatureType = 'signature';
    const fileCertifiedEmailType = 'certified_email';

    const eventSignatureSource = 'signature';
    const eventCertifiedEmailSource = 'certified_email'

    beforeEach(async () => {
        userContract = await ArtifactUser.new(
            userAddress,
            {
                from: signaturitAddress
            }
        )
    });

    it('Check if it deploy correctly', async () => {
        assert.ok(userContract.address);
    });

    it('Call setCertificatePublicKey from Signaturit account', async () => {
        const transaction = await userContract.setCertificatePublicKey(
            certificateUserKey,
            {
                from: signaturitAddress
            }
        );

        assert.ok(transaction.receipt.status);

        const readKey = await userContract.certificatePublicKey();

        assert.equal(certificateUserKey, readKey);
    });

    it('Call setCertificatePublicKey from not Signaturit account', async () => {
        try {
            const transaction = await userContract.setCertificatePublicKey(
                certificateUserKey,
                {
                    from: invalidAddress
                }
            );

            assert.fail('Unexpected behaviour, it should have thrown');
        } catch (error) {
            assert.include(
                error.message,
                "Only Signaturit account can perform this action."
            )
        }

    });

    it('Call addSignature from Signaturit account', async () => {
        const transaction = await userContract.addSignature(
            signatureAddress,
            signatureId,
            {
                from: signaturitAddress
            }
        );

        assert.ok(transaction.receipt.status);

        const readSignatureFromArray = await userContract.getSignature(0);
        const readAddressFromId = await userContract.getSignatureById(signatureId);
        const readArraySize = await userContract.getSignaturesCount();

        assert.equal(readSignatureFromArray.adr, readAddressFromId);
        assert.equal(readAddressFromId, signatureAddress);
        assert.equal(readArraySize.toNumber(), 1);
    });

    it('Call addSignature from not Signaturit account', async () => {
        try {
            const transaction = await userContract.addSignature(
                signatureAddress,
                signatureId,
                {
                    from: invalidAddress
                }
            );

            assert.fail('Unexpected behaviour, it should have thrown');
        } catch (error) {
            assert.include(
                error.message,
                "Only Signaturit account can perform this action."
            )
        }

    });

    it('Call addDocument from Signaturit account', async () => {
        const transaction = await userContract.addDocument(
            documentAddress,
            {
                from: signaturitAddress
            }
        );

        assert.ok(transaction.receipt.status);

        const readDocumentFromArray = await userContract.getDocument(0);
        const readArraySize = await userContract.getDocumentsCount();

        assert.equal(readDocumentFromArray.adr, documentAddress);
        assert.equal(readArraySize.toNumber(), 1);
    });

    it('Call addDocument from not Signaturit account', async () => {
        try {
            const transaction = await userContract.addDocument(
                documentAddress,
                {
                    from: invalidAddress
                }
            );

            assert.fail('Unexpected behaviour, it should have thrown');
        } catch (error) {
            assert.include(
                error.message,
                "Only Signaturit account can perform this action."
            )
        }

    });

    it('Call addFile from Signaturit account', async () => {
        const firstTransaction = await userContract.addFile(
            fileSignatureType,
            fileAddress,
            {
                from: signaturitAddress
            }
        );

        const secondTransaction = await userContract.addFile(
            fileCertifiedEmailType,
            fileAddress,
            {
                from: signaturitAddress
            }
        );

        assert.ok(firstTransaction.receipt.status);
        assert.ok(secondTransaction.receipt.status);

        const readFileFromSignatureArray = await userContract.getSignatureFile(0);
        const readSignatureFilesArraySize = await userContract.getSignatureFilesCount();

        const readFileFromCertifiedEmailArray = await userContract.getCertifiedEmailFile(0);
        const readCertifiedEmailFilesArraySize = await userContract.getCertifiedEmailFilesCount();

        assert.equal(readFileFromSignatureArray.adr, fileAddress);
        assert.equal(readSignatureFilesArraySize.toNumber(), 1);
        assert.equal(readFileFromCertifiedEmailArray.adr, fileAddress);
        assert.equal(readCertifiedEmailFilesArraySize.toNumber(), 1);
    });

    it('Call addFile from not Signaturit account', async () => {
        try {
            const transaction = await userContract.addFile(
                fileSignatureType,
                fileAddress,
                {
                    from: invalidAddress
                }
            );

            assert.fail('Unexpected behaviour, it should have thrown');
        } catch (error) {
            assert.include(
                error.message,
                "Only Signaturit account can perform this action."
            )
        }

    });

    it('Call addEvent from Signaturit account', async () => {
        const firstTransaction = await userContract.addEvent(
            eventSignatureSource,
            eventAddress,
            {
                from: signaturitAddress
            }
        );

        const secondTransaction = await userContract.addEvent(
            eventCertifiedEmailSource,
            eventAddress,
            {
                from: signaturitAddress
            }
        );


        assert.ok(firstTransaction.receipt.status);
        assert.ok(secondTransaction.receipt.status);

        const readSignatureEventFromArray = await userContract.getSignatureEvent(0);
        const readEventFromSignatureArraySize = await userContract.getSignatureEventsCount();
        const readCertifiedEmailEventFromArray = await userContract.getCertifiedEmailEvent(0);
        const readEventFromCertifiedEmailArraySize = await userContract.getCertifiedEmailEventsCount();

        assert.equal(readSignatureEventFromArray.adr, eventAddress);
        assert.equal(readCertifiedEmailEventFromArray.adr, eventAddress);
        assert.equal(readEventFromSignatureArraySize.toNumber(), 1);
        assert.equal(readEventFromCertifiedEmailArraySize.toNumber(), 1);
    });

    it('Call addEvent from not Signaturit account', async () => {
        try {
            const transaction = await userContract.addEvent(
                eventSignatureSource,
                eventAddress,
                {
                    from: invalidAddress
                }
            );

            assert.fail('Unexpected behaviour, it should have thrown');
        } catch (error) {
            assert.include(
                error.message,
                "Only Signaturit account can perform this action."
            )
        }

    });

    it('Call addCertifiedEmail from Signaturit account', async () => {
        const transaction = await userContract.addCertifiedEmail(
            certifiedEmailAddress,
            certifiedEmailId,
            {
                from: signaturitAddress
            }
        );

        assert.ok(transaction.receipt.status);

        const readCertifiedEmailFromArray = await userContract.getCertifiedEmail(0);
        const readAddressFromId = await userContract.getCertifiedEmailById(certifiedEmailId);
        const arraySize = await userContract.getCertifiedEmailsCount();

        assert.equal(readCertifiedEmailFromArray.adr, readAddressFromId);
        assert.equal(readAddressFromId, certifiedEmailAddress);
        assert.equal(arraySize.toNumber(), 1);
    });

    it('Call addCertifiedEmail from not Signaturit account', async () => {
        try {
            const transaction = await userContract.addCertifiedEmail(
                certifiedEmailAddress,
                certifiedEmailId,
                {
                    from: invalidAddress
                }
            );

            assert.fail('Unexpected behaviour, it should have thrown');
        } catch (error) {
            assert.include(
                error.message,
                "Only Signaturit account can perform this action."
            );
        }

    });

    it('Call addCertificate from Signaturit account', async () => {
        const transaction = await userContract.addCertificate(
            certificateAddress,
            {
                from: signaturitAddress
            }
        );

        assert.ok(transaction.receipt.status);

        const readCertificateFromArray = await userContract.getCertificate(0);
        const readArraySize = await userContract.getCertificatesCount();

        assert.equal(readCertificateFromArray.adr, certificateAddress);
        assert.equal(readArraySize.toNumber(), 1);
    });

    it('Call addCertificate from not Signaturit account', async () => {
        try {
            const transaction = await userContract.addCertificate(
                certificateAddress,
                {
                    from: invalidAddress
                }
            );

            assert.fail('Unexpected behaviour, it should have thrown');
        } catch (error) {
            assert.include(
                error.message,
                "Only Signaturit account can perform this action."
            )
        }

    });

    it('Call addCertifiedFile from Signaturit account', async () => {
        const transaction = await userContract.addCertifiedFile(
            certifiedFileAddress,
            certifiedFileId,
            {
                from: signaturitAddress
            }
        );

        assert.ok(transaction.receipt.status);

        const readCertifiedFileFromArray = await userContract.getCertifiedFile(0);
        const readAddressFromId = await userContract.getCertifiedFileById(certifiedFileId);
        const arraySize = await userContract.getCertifiedFilesCount();

        assert.equal(readCertifiedFileFromArray.adr, readAddressFromId);
        assert.equal(readAddressFromId, certifiedFileAddress);
        assert.equal(arraySize.toNumber(), 1);
    });

    it('Call addCertifiedFile from not Signaturit account', async () => {
        try {
            const transaction = await userContract.addCertifiedFile(
                certifiedFileAddress,
                certifiedFileId,
                {
                    from: invalidAddress
                }
            );

            assert.fail('Unexpected behaviour, it should have thrown');
        } catch (error) {
            assert.include(
                error.message,
                "Only Signaturit account can perform this action.",
            );
        }

    });

    it('Call addCertifiedFile two times and recover both', async () => {
        await userContract.addCertifiedFile(
            certifiedFileAddress,
            certifiedFileId,
            {
                from: signaturitAddress
            }
        );

        await userContract.addCertifiedFile(
            anotherCertifiedFileAddress,
            anotherCertifiedFileId,
            {
                from: signaturitAddress
            }
        );

        const readFirstCertifiedFileFromArray = await userContract.getCertifiedFile(0);
        const readFirstAddressFromId = await userContract.getCertifiedFileById(certifiedFileId);

        const readSecondCertifiedFileFromArray = await userContract.getCertifiedFile(1);
        const readSecondAddressFromId = await userContract.getCertifiedFileById(anotherCertifiedFileId);

        const readArraySize = await userContract.getCertifiedFilesCount();

        assert.equal(readFirstCertifiedFileFromArray.adr, readFirstAddressFromId);
        assert.equal(readSecondCertifiedFileFromArray.adr, readSecondAddressFromId);
        assert.equal(readFirstAddressFromId, certifiedFileAddress);
        assert.equal(readSecondAddressFromId, anotherCertifiedFileAddress);
        assert.equal(readArraySize.toNumber(), 2);
    });

    it('try to recover not existing certified file', async () => {

        try{
            await userContract.getCertifiedFile(0);

            assert.fail('Unexpected behaviour, it should have thrown');
        } catch (error) {
            assert.include(
                error.message,
                "Returned error: VM Exception while processing transaction: revert",
            )
        }
    });

    it('Call clauseNotification from Signaturit account', async () => {
        const transaction = await userContract.clauseNotification(
            signatureAddress,
            clauseType,
            notificationType,
            signatureId,
            {
                from: signaturitAddress
            }
        );

        assert.ok(transaction.receipt.status);
    });

    it('Call clauseNotification from not Signaturit account', async () => {
        try {
            const transaction = await userContract.clauseNotification(
                signatureAddress,
                clauseType,
                notificationType,
                signatureId,
                {
                    from: invalidAddress
                }
            );

            assert.fail('Unexpected behaviour, it should have thrown');
        } catch (error) {
            assert.include(
                error.message,
                "Only Signaturit account can perform this action.",
            );
        }

    });
})
