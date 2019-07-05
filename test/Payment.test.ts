contract('Payment', async (accounts) => {
    const ArtifactUser      = artifacts.require('User');
    const ArtifactPayment   = artifacts.require('Payment');
    const ArtifactSignature = artifacts.require('Signature');
    const ArtifactSignatureDeployer = artifacts.require('SignatureDeployer');

    const v4 = require("uuid").v4;

    const signaturitAddress = accounts[0];
    const invalidAddress = accounts[1];

    let userContract;
    let paymentContract;
    let signatureContract;
    let signatureDeployerContract;

    const contractId = v4();
    const documentId = v4();
    const signatureId = v4();
    const period = 30;
    const endDate = Date.now();
    const startDate = Date.now();

    const receiverId = v4();
    const secondReceiverId = v4();

    const referenceId = v4();
    const secondReferenceId = v4();
    const referenceValue = 'rent';
    const referencePrice = 100;

    const statementId = v4();
    const secondStatementId = v4();
    const statementStatus = 2;
    const statementCheckedAt = Date.now();
    const statementReceivedAt = Date.now();

    beforeEach(async () => {
        signatureDeployerContract = await ArtifactSignatureDeployer.new();

        signatureContract = await ArtifactSignature.new(
            signatureId,
            signatureDeployerContract.address,
            Date.now(),
            {
                from: signaturitAddress
            }
        );

        userContract = await ArtifactUser.new(signaturitAddress);

        paymentContract = await ArtifactPayment.new(
            userContract.address,
            signatureContract.address,
            contractId,
            {
                from: signaturitAddress
            }
        )
    });

    it('Check if it deploy correctly', async () => {
        assert.ok(paymentContract.address);

        const readContractId = await paymentContract.contractId();

        assert.equal(readContractId, contractId);
    });

    it('Call init and check the correctness of parameters and if Signature has been called', async () => {
        await paymentContract.init(
            signatureId,
            documentId,
            startDate,
            endDate,
            period,
            {from: signaturitAddress}
        )

        const readSignatureId = await paymentContract.signatureId();
        const readDocumentId = await paymentContract.documentId();
        const readStartDate = await paymentContract.startDate();
        const readEndDate = await paymentContract.endDate();
        const readPeriod = await paymentContract.period();

        const readClauseAddress = await signatureContract.getClause('payment');

        assert.equal(readSignatureId, signatureId);
        assert.equal(readDocumentId, documentId);
        assert.equal(readStartDate, startDate);
        assert.equal(readEndDate, endDate);
        assert.equal(readPeriod, period);
        assert.equal(readClauseAddress, paymentContract.address);
    });

    it('Call setReceiver and check correctness', async () => {
        await paymentContract.setReceiver(
            receiverId,
            {from: signaturitAddress}
        );

        const readReceiverId = await paymentContract.receiversArray(0);

        assert.equal(readReceiverId, receiverId);
    });

    it('Add two receivers, call getters and check correctness', async () => {
        await paymentContract.setReceiver(
            receiverId,
            {from: signaturitAddress}
        );

        await paymentContract.setReceiver(
            secondReceiverId,
            {from: signaturitAddress}
        );

        const readFirstReceiver = await paymentContract.getReceiverId(0);
        const readSecondReceiver = await paymentContract.getReceiverId(1);

        assert.ok(readFirstReceiver.more);
        assert.notOk(readSecondReceiver.more);

        assert.equal(readFirstReceiver.id, receiverId);
        assert.equal(readSecondReceiver.id, secondReceiverId);
    });


    it('Call setReceiver as not signaturit, expect exception', async () => {
        try {
            await paymentContract.setReceiver(
                receiverId,
                {from: invalidAddress}
            );

            assert.fail("Something bad happened");

        } catch(error) {
            assert.include(
                error.message,
                'Only Signaturit account can perform this action.'
            );
        }
    });

    it('Call setReference without a receiver, expect receiver to be created and check correctness', async () => {
        await paymentContract.setReference(
            receiverId,
            referenceId,
            referenceValue,
            referencePrice,
            {
                from: signaturitAddress
            }
        );


        const readReference = await paymentContract.getReferenceById(referenceId);
        const readReferenceFromReceiver = await paymentContract.getReferenceFromReceiver(receiverId,0);
        const readReferenceSizeFromReceiver = await paymentContract.getReferenceSizeFromReceiver(receiverId);

        const readReceiverId = await paymentContract.receiversArray(0);

        assert.equal(readReferenceSizeFromReceiver, 1);

        assert.equal(readReceiverId, receiverId);

        assert.equal(readReference.id, referenceId);
        assert.equal(readReference.id, readReferenceFromReceiver.id);

        assert.equal(readReference.value, referenceValue);
        assert.equal(readReference.value, readReferenceFromReceiver.value);

        assert.equal(readReference.price.toNumber(), readReferenceFromReceiver.price.toNumber());
        assert.equal(readReference.price.toNumber(), referencePrice);
    });

    it('Set two references to the same receiver and check correctness', async () => {
        await paymentContract.setReference(
            receiverId,
            referenceId,
            referenceValue,
            referencePrice,
            {
                from: signaturitAddress
            }
        );

        await paymentContract.setReference(
            receiverId,
            secondReferenceId,
            referenceValue,
            referencePrice,
            {
                from: signaturitAddress
            }
        );

        const readReference = await paymentContract.getReferenceById(referenceId);
        const readFirstReferenceFromReceiver = await paymentContract.getReferenceFromReceiver(receiverId,0);
        const readSecondReferenceFromReceiver = await paymentContract.getReferenceFromReceiver(receiverId,1);
        const readReferenceSizeFromReceiver = await paymentContract.getReferenceSizeFromReceiver(receiverId);

        const readReceiverId = await paymentContract.receiversArray(0);

        assert.ok(readFirstReferenceFromReceiver.more);
        assert.notOk(readSecondReferenceFromReceiver.more);

        assert.equal(readReferenceSizeFromReceiver, 2);

        assert.equal(readReceiverId, receiverId);

        assert.equal(readReference.id, referenceId);
        assert.equal(readReference.id, readFirstReferenceFromReceiver.id);

        assert.equal(readReference.value, referenceValue);
        assert.equal(readReference.value, readFirstReferenceFromReceiver.value);
        assert.equal(readFirstReferenceFromReceiver.value, readSecondReferenceFromReceiver.value);

        assert.equal(readReference.price.toNumber(), referencePrice);
        assert.equal(readReference.price.toNumber(), readFirstReferenceFromReceiver.price.toNumber());
        assert.equal(readFirstReferenceFromReceiver.price.toNumber(), readSecondReferenceFromReceiver.price.toNumber());
    });

    it('Call addStatement without reference and receiver, expect both to be created and check correctness', async () => {
        await paymentContract.addStatement(
            receiverId,
            referenceId,
            statementId,
            statementStatus,
            statementReceivedAt,
            statementCheckedAt,
            {
                from: signaturitAddress
            }
        );

        const readReceiver = await paymentContract.getReceiverId(0);

        const readReference = await paymentContract.getReferenceById(referenceId);

        const readStatement = await paymentContract.getStatementById(statementId);

        const readLastStatementFromReference = await paymentContract.getLastStatementFromReference(referenceId);

        const readStatementSizeFromReference = await paymentContract.getStatementSizeFromReference(referenceId)

        assert.equal(readStatementSizeFromReference, 1);

        assert.equal(receiverId, readReceiver.id);
        assert.equal(referenceId, readReference.id);

        assert.equal(statementId, readStatement.id);
        assert.equal(readStatement.id, readLastStatementFromReference.id);

        assert.equal(statementStatus, readStatement.status);
        assert.equal(readStatement.status.toNumber(), readLastStatementFromReference.status.toNumber());

        assert.equal(statementReceivedAt, readStatement.receivedAt.toNumber());
        assert.equal(readStatement.receivedAt.toNumber(), readLastStatementFromReference.receivedAt.toNumber());

        assert.equal(statementCheckedAt, readStatement.createdAt.toNumber());
        assert.equal(readStatement.createdAt.toNumber(), readLastStatementFromReference.createdAt.toNumber());
    });

    it('Call addStatement twice, and check correctness', async () => {
        await paymentContract.addStatement(
            receiverId,
            referenceId,
            statementId,
            statementStatus,
            statementReceivedAt,
            statementCheckedAt,
            {
                from: signaturitAddress
            }
        );

        await paymentContract.addStatement(
            receiverId,
            referenceId,
            secondStatementId,
            statementStatus,
            statementReceivedAt,
            statementCheckedAt,
            {
                from: signaturitAddress
            }
        );

        const readReceiver = await paymentContract.getReceiverId(0);

        const readReference = await paymentContract.getReferenceById(referenceId);

        const readStatement = await paymentContract.getStatementById(statementId);

        const readFirstStatementFromReference = await paymentContract.getStatementFromReference(referenceId, 0);
        const readSecondStatementFromReference = await paymentContract.getStatementFromReference(referenceId, 1);

        assert.equal(readFirstStatementFromReference.status.toNumber(), readSecondStatementFromReference.status.toNumber());
        assert.equal(readFirstStatementFromReference.receivedAt.toNumber(), readSecondStatementFromReference.receivedAt.toNumber());
        assert.equal(readFirstStatementFromReference.createdAt.toNumber(), readSecondStatementFromReference.createdAt.toNumber());

        assert.ok(readFirstStatementFromReference.more);
        assert.notOk(readSecondStatementFromReference.more);
    });

})
