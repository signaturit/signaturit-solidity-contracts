contract('CertifiedFileChecker', async (accounts) => {
    const ArtifactCertifiedFileChecker = artifacts.require('CertifiedFileChecker');
    const ArtifactCertifiedFile = artifacts.require('CertifiedFile');
    const ArtifactUser = artifacts.require('User');

    const v4 = require("uuid").v4;

    let ownerAddress        = accounts[0];
    let signaturitAddress   = accounts[1];
    let secondOwnerAddress  = accounts[2];
    let contractAddress     = accounts[3]

    let fileContract;
    let certifiedFileChecker;
    let userContract;

    const fileId   = v4();
    const fileName = 'Test.pdf';
    const fileHash = 'File hash';
    const fileSize = 123;
    const fileDate = Date.now();

    beforeEach(async () => {
        userContract = await ArtifactUser.new(
            ownerAddress,
            {
                from: signaturitAddress
            }
        );

        certifiedFileChecker = await ArtifactCertifiedFileChecker.new(
            {
                from: signaturitAddress
            }
        );

        fileContract = await ArtifactCertifiedFile.new(
            ownerAddress,
            userContract.address,
            fileId,
            fileHash,
            fileDate,
            fileSize,
            {
                from: signaturitAddress
            }
        )
    })

    it('Check if it deploy correctly', async () => {
        assert.ok(certifiedFileChecker.address);
    });

    it('Add file to the certified file checker', async () => {
        await certifiedFileChecker.notify(
            "certified_file.contract.created",
            fileContract.address, {
            from: signaturitAddress
        });
    });

    it('Try to add a certified file from other account than signaturit', async () => {
        try {
            await certifiedFileChecker.notify(
                "certified_file.contract.created",
                fileContract.address, {
                from: ownerAddress
            });
        } catch {
            assert.ok(true);
            return;
        }

        assert.fail('This transaction must be reverted');
    });

    it('Retrieve data from the certified file checker of existent file', async () => {
        await certifiedFileChecker.notify(
            "certified_file.contract.created",
            fileContract.address, {
            from: signaturitAddress
        });

        const certifiedFile = await certifiedFileChecker.getFile(fileHash, 0);

        assert.equal(certifiedFile.id, fileId);
        assert.equal(certifiedFile.hash, fileHash);
        assert.equal(certifiedFile.size.toNumber(), fileSize);
        assert.equal(certifiedFile.createdAt.toNumber(), fileDate);
        assert.equal(certifiedFile.owner, ownerAddress);
        assert.equal(certifiedFile.more, false);
    }); 

    it('Access to non defined index', async () => {
        await certifiedFileChecker.notify(
            "certified_file.contract.created",
            fileContract.address, {
            from: signaturitAddress
        });

        const certifiedFile = await certifiedFileChecker.getFile(fileHash, 10);

        assert.equal(certifiedFile.id, '');
        assert.equal(certifiedFile.hash, '');
        assert.equal(certifiedFile.size.toNumber(), 0);
        assert.equal(certifiedFile.createdAt.toNumber(), 0);
        assert.equal(certifiedFile.owner, '0x0000000000000000000000000000000000000000');
        assert.equal(certifiedFile.more, false);
    });

    it('Access to non created certified file', async () => {
        await certifiedFileChecker.notify(
            "certified_file.contract.created",
            fileContract.address, {
            from: signaturitAddress
        });

        const certifiedFile = await certifiedFileChecker.getFile('no existent hash', 0);

        assert.equal(certifiedFile.id, '');
        assert.equal(certifiedFile.hash, '');
        assert.equal(certifiedFile.size.toNumber(), 0);
        assert.equal(certifiedFile.createdAt.toNumber(), 0);
        assert.equal(certifiedFile.owner, '0x0000000000000000000000000000000000000000');
        assert.equal(certifiedFile.more, false);
    });

    it('Access to the second certified file', async () => {
        const secondFileId   = v4();
        const secondFileHash = 'File hash';
        const secondFileSize = 12376;
        const secondFileDate = Date.now();

        await certifiedFileChecker.notify(
            "certified_file.contract.created",
            fileContract.address, {
            from: signaturitAddress
        });

        const fileContract2 = await ArtifactCertifiedFile.new(
            secondOwnerAddress,
            userContract.address,
            secondFileId,
            secondFileHash,
            secondFileDate,
            secondFileSize,
            {
                from: signaturitAddress
            }
        );

        await certifiedFileChecker.notify(
            "certified_file.contract.created",
            fileContract2.address, {
            from: signaturitAddress
        });

        const certifiedFile = await certifiedFileChecker.getFile(fileHash, 0);

        assert.equal(certifiedFile.more, true);

        const secondCertifiedFile = await certifiedFileChecker.getFile(secondFileHash, 1);

        assert.equal(secondCertifiedFile.id, secondFileId);
        assert.equal(secondCertifiedFile.hash, secondFileHash);
        assert.equal(secondCertifiedFile.size.toNumber(), secondFileSize);
        assert.equal(secondCertifiedFile.createdAt.toNumber(), secondFileDate);
        assert.equal(secondCertifiedFile.owner, secondOwnerAddress);
        assert.equal(secondCertifiedFile.more, false);
    });
})
