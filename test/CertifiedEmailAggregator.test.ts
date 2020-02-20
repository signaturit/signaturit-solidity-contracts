contract('CertifiedEmailAggregator', async (accounts) => {
    const ArtifactUser = artifacts.require('SignaturitUser');
    const ArtifactCertifiedEmail = artifacts.require('CertifiedEmail');
    const ArtifactCertifiedEmailAggregator = artifacts.require('CertifiedEmailAggregator');

    const v4 = require("uuid").v4;

    const rootAddress = accounts[0];
    const ownerAddress = accounts[1];
    const invalidAccount = accounts[2];
    const deployerAddress = accounts[3];

    const nullAddress = '0x0000000000000000000000000000000000000000';

    const certifiedEmailId = v4();
    const secondCertifiedEmailId = v4();
    const certifiedEmailSubjectHash = 'certifiedEmailSubjectHash';
    const certifiedEmailDeliveryType = 'certifiedEmailDeliveryType';
    const certifiedEmailBodyHash = 'certifiedEmailBodyHash';
    const certifiedEmailCreatedAt = Date.now();

    const enumEvents = {
        FILE_CREATED_EVENT: 0,
        CERTIFIED_FILE_CREATED_EVENT: 1,
        EVENT_CREATED_EVENT: 2,
        DOCUMENT_CREATED_EVENT: 3,
        CERTIFICATE_CREATED_EVENT: 4,
        SIGNATURE_CREATED_EVENT: 5,
        CERTIFIED_EMAIL_CREATED_EVENT: 6,
        TIMELOGGER_CLAUSE_CREATED: 7,
        TIMELOG_ADDED_EVENT: 8,
        PAYMENT_CLAUSE_CREATED: 9,
        PAYMENT_CHECK_ADDED_EVENT: 10
    };

    let certifiedEmailAggregatorContract;
    let userContract;

    beforeEach(async() => {
        userContract = await ArtifactUser.new(
            ownerAddress,
            {
                from: rootAddress
            }
        );

        certifiedEmailAggregatorContract = await ArtifactCertifiedEmailAggregator.new(
            userContract.address,
            {
                from: rootAddress
            }
        );
    });

    it("Check if it deploy correctly", async () => {
        assert.ok(certifiedEmailAggregatorContract.address);
    });


    it("Retrieve certified email aggregator from user", async () => {
        const signatureAggregatorAddress = await userContract.getAddressAttribute('certified-email-aggregator');

        assert.equal(signatureAggregatorAddress, certifiedEmailAggregatorContract.address);
    });

    it("Deploy certifiedEmail aggregator contract from invalid account", async () =>{
        try {
            await ArtifactCertifiedEmailAggregator.new(
                userContract.address,
                {
                    from: invalidAccount
                }
            );
        } catch(error) {
            assert.include(
                error.message,
                "Only the owner can perform this action"
            )
        }
    });

    it("Create certified email without call notify", async () => {
        const certifiedEmailContract = await ArtifactCertifiedEmail.new(
            certifiedEmailId,
            certifiedEmailSubjectHash,
            certifiedEmailBodyHash,
            certifiedEmailDeliveryType,
            certifiedEmailCreatedAt,
            deployerAddress,
            ownerAddress,
            userContract.address
        );

        const storedCertifiedEmails = await certifiedEmailAggregatorContract.count();

        assert.equal(0, storedCertifiedEmails.toNumber());
        assert.ok(certifiedEmailContract.address);
    });

    it("Create certifiedEmail without address to notify and notify manually", async () => {
        const certifiedEmailContract = await ArtifactCertifiedEmail.new(
            certifiedEmailId,
            certifiedEmailSubjectHash,
            certifiedEmailBodyHash,
            certifiedEmailDeliveryType,
            certifiedEmailCreatedAt,
            deployerAddress,
            ownerAddress,
            userContract.address
        );

        await certifiedEmailAggregatorContract.notify(
            enumEvents.CERTIFIED_EMAIL_CREATED_EVENT,
            certifiedEmailContract.address
        );

        const storedCertifiedEmails = await certifiedEmailAggregatorContract.count();

        assert.equal(1, storedCertifiedEmails.toNumber());
        assert.ok(certifiedEmailContract.address);
    });

    it("Create certifiedEmail without address to notify and notify manually from invalid account, expect exception", async () => {
        const certifiedEmailContract = await ArtifactCertifiedEmail.new(
            certifiedEmailId,
            certifiedEmailSubjectHash,
            certifiedEmailBodyHash,
            certifiedEmailDeliveryType,
            certifiedEmailCreatedAt,
            deployerAddress,
            ownerAddress,
            userContract.address
        );
        
        try {
            const tx = await certifiedEmailAggregatorContract.notify(
                enumEvents.CERTIFIED_EMAIL_CREATED_EVENT,
                certifiedEmailContract.address,
                {
                    from: invalidAccount
                }
            );
        } catch(error) {
            assert.include(
                error.message,
                "Only Signaturit account can perform this action"
            )
        }
    });

    it("Create certifiedEmail on user with certifiedEmail aggregator", async () => {
        const certifiedEmailContract = await ArtifactCertifiedEmail.new(
            certifiedEmailId,
            certifiedEmailSubjectHash,
            certifiedEmailBodyHash,
            certifiedEmailDeliveryType,
            certifiedEmailCreatedAt,
            deployerAddress,
            ownerAddress,
            userContract.address
        );


        await certifiedEmailContract.notifyCreation();

        const storedCertifiedEmails = await certifiedEmailAggregatorContract.count();
        const certifiedEmailByIdAddress = await certifiedEmailAggregatorContract.getCertifiedEmailById(certifiedEmailId);
        const certifiedEmailByIndex = await certifiedEmailAggregatorContract.getCertifiedEmail(0);

        assert.equal(storedCertifiedEmails.toNumber(), 1);
        assert.equal(certifiedEmailByIdAddress, certifiedEmailContract.address);
        assert.equal(certifiedEmailByIndex.addr, certifiedEmailContract.address);
        assert.equal(certifiedEmailByIndex.more, false);
    });

    it("Access to not existing certifiedEmail", async () => {
        const certifiedEmailByIndex = await certifiedEmailAggregatorContract.getCertifiedEmail(0);

        assert.equal(certifiedEmailByIndex.addr, nullAddress);
        assert.equal(certifiedEmailByIndex.more, false);
    });

    it("Create two certifiedEmail on user with certifiedEmail aggregator", async () => {
        const certifiedEmailContract = await ArtifactCertifiedEmail.new(
            certifiedEmailId,
            certifiedEmailSubjectHash,
            certifiedEmailBodyHash,
            certifiedEmailDeliveryType,
            certifiedEmailCreatedAt,
            deployerAddress,
            ownerAddress,
            userContract.address
        );

        await certifiedEmailContract.notifyCreation();

        const secondCertifiedEmailContract = await ArtifactCertifiedEmail.new(
            secondCertifiedEmailId,
            certifiedEmailSubjectHash,
            certifiedEmailBodyHash,
            certifiedEmailDeliveryType,
            certifiedEmailCreatedAt,
            deployerAddress,
            ownerAddress,
            userContract.address
        );

        await secondCertifiedEmailContract.notifyCreation();

        const storedCertifiedEmails = await certifiedEmailAggregatorContract.count();
        const certifiedEmailAddressById = await certifiedEmailAggregatorContract.getCertifiedEmailById(certifiedEmailId);
        const certifiedEmailByIndex = await certifiedEmailAggregatorContract.getCertifiedEmail(0);
        const secondCertifiedEmailAddressById = await certifiedEmailAggregatorContract.getCertifiedEmailById(secondCertifiedEmailId);
        const secondCertifiedEmailByIndex = await certifiedEmailAggregatorContract.getCertifiedEmail(1);

        assert.equal(storedCertifiedEmails.toNumber(), 2);
        assert.equal(certifiedEmailAddressById, certifiedEmailContract.address);
        assert.equal(certifiedEmailByIndex.addr, certifiedEmailContract.address);
        assert.equal(certifiedEmailByIndex.more, true);

        assert.equal(secondCertifiedEmailAddressById, secondCertifiedEmailContract.address);
        assert.equal(secondCertifiedEmailByIndex.addr, secondCertifiedEmailContract.address);
        assert.equal(secondCertifiedEmailByIndex.more, false);
    });
})