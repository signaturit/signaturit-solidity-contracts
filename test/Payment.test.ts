var truffleAssert = require('truffle-assertions');
var truffleEvent  = require('truffle-events');

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

    const clauseType = "payment";

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

    const paymentCheckId = v4();
    const secondPaymentCheckId = v4();
    const paymentCheckStatus = 2;
    const paymentCheckCheckedAt = Date.now();
    const paymentCheckCreatedAt = Date.now();

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

        const readClauseType = await paymentContract.clause();

        assert.equal(readClauseType, clauseType);
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

    it('Call addPaymentCheck without reference and receiver, expect both to be created and check correctness', async () => {
        await paymentContract.addPaymentCheck(
            receiverId,
            referenceId,
            paymentCheckId,
            paymentCheckStatus,
            paymentCheckCheckedAt,
            paymentCheckCreatedAt,
            {
                from: signaturitAddress
            }
        );

        const readReceiver = await paymentContract.getReceiverId(0);

        const readReference = await paymentContract.getReferenceById(referenceId);

        const readPaymentCheck = await paymentContract.getPaymentCheckById(paymentCheckId);

        const readLastPaymentCheckFromReference = await paymentContract.getLastPaymentCheckFromReference(referenceId);

        const readPaymentCheckSizeFromReference = await paymentContract.getPaymentCheckSizeFromReference(referenceId)

        assert.equal(readPaymentCheckSizeFromReference, 1);

        assert.equal(receiverId, readReceiver.id);
        assert.equal(referenceId, readReference.id);

        assert.equal(paymentCheckId, readPaymentCheck.id);
        assert.equal(readPaymentCheck.id, readLastPaymentCheckFromReference.id);

        assert.equal(paymentCheckStatus, readPaymentCheck.status);
        assert.equal(readPaymentCheck.status.toNumber(), readLastPaymentCheckFromReference.status.toNumber());

        assert.equal(paymentCheckCreatedAt, readPaymentCheck.createdAt.toNumber());
        assert.equal(readPaymentCheck.checkedAt.toNumber(), readLastPaymentCheckFromReference.checkedAt.toNumber());

        assert.equal(paymentCheckCheckedAt, readPaymentCheck.checkedAt.toNumber());
        assert.equal(readPaymentCheck.createdAt.toNumber(), readLastPaymentCheckFromReference.createdAt.toNumber());
    });

    it('Call addPaymentCheck twice, and check correctness', async () => {
        await paymentContract.addPaymentCheck(
            receiverId,
            referenceId,
            paymentCheckId,
            paymentCheckStatus,
            paymentCheckCheckedAt,
            paymentCheckCreatedAt,
            {
                from: signaturitAddress
            }
        );

        await paymentContract.addPaymentCheck(
            receiverId,
            referenceId,
            secondPaymentCheckId,
            paymentCheckStatus,
            paymentCheckCheckedAt,
            paymentCheckCreatedAt,
            {
                from: signaturitAddress
            }
        );

        const readReceiver = await paymentContract.getReceiverId(0);

        const readReference = await paymentContract.getReferenceById(referenceId);

        const readPaymentCheck = await paymentContract.getPaymentCheckById(paymentCheckId);

        const readFirstPaymentCheckFromReference = await paymentContract.getPaymentCheckFromReference(referenceId, 0);
        const readSecondPaymentCheckFromReference = await paymentContract.getPaymentCheckFromReference(referenceId, 1);

        assert.equal(readFirstPaymentCheckFromReference.status.toNumber(), readSecondPaymentCheckFromReference.status.toNumber());
        assert.equal(readFirstPaymentCheckFromReference.checkedAt.toNumber(), readSecondPaymentCheckFromReference.checkedAt.toNumber());
        assert.equal(readFirstPaymentCheckFromReference.createdAt.toNumber(), readSecondPaymentCheckFromReference.createdAt.toNumber());

        assert.ok(readFirstPaymentCheckFromReference.more);
        assert.notOk(readSecondPaymentCheckFromReference.more);
    });

})
