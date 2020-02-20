contract('CertifiedFileAggregator', async (accounts) => {
    const ArtifactUser = artifacts.require('SignaturitUser');
    const ArtifactCertifiedFile = artifacts.require('CertifiedFile');
    const ArtifactCertifiedFileAggregator = artifacts.require('CertifiedFileAggregator');
    const ArtifactCertifiedFileChecker = artifacts.require('CertifiedFileChecker');

    const v4 = require("uuid").v4;

    const rootAddress = accounts[0];
    const ownerAddress = accounts[1];
    const invalidAccount = accounts[2];

    const certifiedFileId = v4();
    const certifiedFile2Id = v4();
    const certifiedFileHash = "sdfjqñwefpzdlfjañsldjf232wfa";
    const certifiedFile2Hash = "sdfzvzc2pzdlfzxsldjf232wfa";
    const certifiedFileCreatedAt = Date.now();
    const certifiedFile2CreatedAt = Date.now() + 40;
    const certifiedFileSize = 1223414;
    const certifiedFile2Size = 9932414;

    const nullAddress = '0x0000000000000000000000000000000000000000';

    const enumEvents = {
        FILE_CREATED_EVENT: 0,
        CERTIFIED_FILE_CREATED_EVENT: 1,
        EVENT_CREATED_EVENT: 2,
        DOCUMENT_CREATED_EVENT: 3,
        DOCUMENT_SIGNED_EVENT: 4,
        DOCUMENT_DECLINED_EVENT: 5,
        DOCUMENT_CANCELED_EVENT: 6,
        CERTIFICATE_CREATED_EVENT: 7,
        SIGNATURE_CREATED_EVENT: 8,
        CERTIFIED_EMAIL_CREATED_EVENT: 9,
        TIMELOGGER_CLAUSE_CREATED: 10,
        TIMELOG_ADDED_EVENT: 11,
        PAYMENT_CLAUSE_CREATED: 12,
        PAYMENT_CHECK_ADDED_EVENT: 13
    };

    let certifiedFileAggregatorContract;
    let userContract;

    beforeEach(async() => {
        userContract = await ArtifactUser.new(
            ownerAddress,
            {
                from: rootAddress
            }
        );

        certifiedFileAggregatorContract = await ArtifactCertifiedFileAggregator.new(
            userContract.address,
            {
                from: rootAddress
            }
        );
    });

    it("Check if it deploy correctly", async () => {
        assert.ok(certifiedFileAggregatorContract.address);
    });


    it("Retrieve certified file aggregator from user", async () => {
        const certifiedFileAggregatorAddress = await userContract.getAddressAttribute('certified-file-aggregator');

        assert.equal(certifiedFileAggregatorAddress, certifiedFileAggregatorContract.address);
    });

    it("Deploy certified file contract from invalid account, expect exception", async () =>{
        try {
            await ArtifactCertifiedFileAggregator.new(
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

    it("Create certified file without call notify", async () => {
        const certifiedFileContract = await ArtifactCertifiedFile.new(
            ownerAddress,
            userContract.address,
            certifiedFileId,
            certifiedFileHash,
            certifiedFileCreatedAt,
            certifiedFileSize
        );

        const storedFiles = await certifiedFileAggregatorContract.count();

        assert.equal(0, storedFiles.toNumber());
        assert.ok(certifiedFileContract.address);
    });

    it("Create certified file without address to notify and notify manually", async () => {
        const certifiedFileContract = await ArtifactCertifiedFile.new(
            ownerAddress,
            userContract.address,
            certifiedFileId,
            certifiedFileHash,
            certifiedFileCreatedAt,
            certifiedFileSize
        );

        await certifiedFileAggregatorContract.notify(
            enumEvents.CERTIFIED_FILE_CREATED_EVENT,
            certifiedFileContract.address
        );

        const storedFiles = await certifiedFileAggregatorContract.count();

        assert.equal(1, storedFiles.toNumber());
        assert.ok(certifiedFileContract.address);
    });

    it("Create certified file without address to notify and notify manually with invalid account, expect exception", async () => {
        const certifiedFileContract = await ArtifactCertifiedFile.new(
            ownerAddress,
            userContract.address,
            certifiedFileId,
            certifiedFileHash,
            certifiedFileCreatedAt,
            certifiedFileSize
        );

        try {
            await certifiedFileAggregatorContract.notify(
                enumEvents.CERTIFIED_FILE_CREATED_EVENT,
                certifiedFileContract.address,
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

    it("Create certified file on user with certified file aggregator", async () => {
        const certifiedFileContract = await ArtifactCertifiedFile.new(
            ownerAddress,
            userContract.address,
            certifiedFileId,
            certifiedFileHash,
            certifiedFileCreatedAt,
            certifiedFileSize
        );

        await certifiedFileContract.notifyEvent();

        const storedFiles = await certifiedFileAggregatorContract.count();
        const certifiedFileByIdAddress = await certifiedFileAggregatorContract.getCertifiedFileById(certifiedFileId);
        const certifiedFileByIndex = await certifiedFileAggregatorContract.getCertifiedFile(0);

        assert.equal(storedFiles.toNumber(), 1);
        assert.equal(certifiedFileByIdAddress, certifiedFileContract.address);
        assert.equal(certifiedFileByIndex.addr, certifiedFileContract.address);
        assert.equal(certifiedFileByIndex.more, false);
    });

    it("Access to not existing certifiedFile", async () => {
        const certifiedFileByIndex = await certifiedFileAggregatorContract.getCertifiedFile(0);

        assert.equal(certifiedFileByIndex.addr, nullAddress);
        assert.equal(certifiedFileByIndex.more, false);
    });


    it("Create certified file from invalid user and try to notify", async () => {
        const certifiedFileContract = await ArtifactCertifiedFile.new(
            ownerAddress,
            userContract.address,
            certifiedFileId,
            certifiedFileHash,
            certifiedFileCreatedAt,
            certifiedFileSize,
            {
                from: invalidAccount
            }
        );

        try {
            await certifiedFileContract.notifyEvent();

        } catch {
            return;
        }

        assert.fail("This account can't do this acction");
    });

    it("Create two certified file on user with certified file aggregator", async () => {
        const certifiedFileContract = await ArtifactCertifiedFile.new(
            ownerAddress,
            userContract.address,
            certifiedFileId,
            certifiedFileHash,
            certifiedFileCreatedAt,
            certifiedFileSize
        );

        await certifiedFileContract.notifyEvent();

        const certifiedFileContractTwo = await ArtifactCertifiedFile.new(
            ownerAddress,
            userContract.address,
            certifiedFile2Id,
            certifiedFile2Hash,
            certifiedFile2CreatedAt,
            certifiedFile2Size
        );

        await certifiedFileContractTwo.notifyEvent();

        const storedFiles = await certifiedFileAggregatorContract.count();
        const certifiedFileByIdAddress = await certifiedFileAggregatorContract.getCertifiedFileById(certifiedFileId);
        const certifiedFileByIndex = await certifiedFileAggregatorContract.getCertifiedFile(0);
        const certifiedFile2ByIdAddress = await certifiedFileAggregatorContract.getCertifiedFileById(certifiedFile2Id);
        const certifiedFile2ByIndex = await certifiedFileAggregatorContract.getCertifiedFile(1);

        assert.equal(storedFiles.toNumber(), 2);
        assert.equal(certifiedFileByIdAddress, certifiedFileContract.address);
        assert.equal(certifiedFileByIndex.addr, certifiedFileContract.address);
        assert.equal(certifiedFileByIndex.more, true);

        assert.equal(certifiedFile2ByIdAddress, certifiedFileContractTwo.address);
        assert.equal(certifiedFile2ByIndex.addr, certifiedFileContractTwo.address);
        assert.equal(certifiedFile2ByIndex.more, false);
    });

    it("Add the address of the notify checker and expect to be notified", async () => {
        const certifiedFileChecker = await ArtifactCertifiedFileChecker.new(
            {
                from: rootAddress
            }
        );

        await userContract.setAddressArrayAttribute(
            'certified-file-notifiers',
            certifiedFileChecker.address
        );

        const certifiedFileContract = await ArtifactCertifiedFile.new(
            ownerAddress,
            userContract.address,
            certifiedFileId,
            certifiedFileHash,
            certifiedFileCreatedAt,
            certifiedFileSize
        );

        await certifiedFileContract.notifyEvent();

        const certifiedFile = await certifiedFileChecker.getFile(
            certifiedFileHash,
            0
        );

        assert.equal(certifiedFile.id, certifiedFileId);
        assert.equal(certifiedFile.more, false);
    })
})