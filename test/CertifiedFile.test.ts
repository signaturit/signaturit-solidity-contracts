contract('CertifiedFile', async (accounts) => {
    const ArtifactUser = artifacts.require('SignaturitUser');
    const ArtifactCertifiedFile = artifacts.require('CertifiedFile');
    const ArtifactCertifiedFileChecker = artifacts.require('CertifiedFileChecker');

    const v4 = require("uuid").v4;

    let ownerAddress        = accounts[0];
    let signaturitAddress   = accounts[1];
    let noOwnerAddress      = accounts[2];
    let contractAddress     = accounts[3]

    let fileContract;
    let certifiedFileCheckerContract;
    let userContract;

    const fileId   = v4();
    const fileHash = 'File hash';
    const fileSize = 123;
    const fileDate = Date.now();

    it('Check if it deploy correctly', async () => {
        userContract = await ArtifactUser.new(
            ownerAddress,
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
        );

        assert.ok(fileContract.address);
    });

    it('Try to deploy and retrieve data', async() => {
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
        );

        const readFileSize = await fileContract.size();
        const readFileId = await fileContract.id();
        const readFileHash = await fileContract.hash();
        const readFileDate = await fileContract.createdAt();
        const readFileOwner = await fileContract.owner();
        const readSignaturitAddress = await fileContract.signaturit();

        assert.equal(readFileSize, fileSize);
        assert.equal(readFileId, fileId);
        assert.equal(readFileHash, fileHash);
        assert.equal(readFileDate, fileDate);
        assert.equal(readFileOwner, ownerAddress);
        assert.equal(readSignaturitAddress, signaturitAddress);
    });

    it('Try to call notify function as Signaturit account', async () => {
        certifiedFileCheckerContract = await ArtifactCertifiedFileChecker.new(
            {
                from: signaturitAddress
            }
        );

        const transaction = await fileContract.notifyEvent(
            {
                from: signaturitAddress
            }
        );

        assert.ok(transaction.receipt.status);
    });

    it('Try to call notify function as invalid account', async () => {
        certifiedFileCheckerContract = await ArtifactCertifiedFileChecker.new(
            {
                from: signaturitAddress
            }
        );

        try {
            await fileContract.notifyEvent(
                {
                    from: noOwnerAddress
                }
            );
        } catch(error) {
            assert.include(
                error.message,
                'Only Signaturit account can perform this action'
            );
        }
    });

    it('Try to call notify function with invalid certifiedFileChecker address', async () => {
        certifiedFileCheckerContract = await ArtifactCertifiedFileChecker.new(
            {
                from: signaturitAddress
            }
        );

        try {
            await fileContract.notifyEvent(
                {
                    from: signaturitAddress
                }
            );
        } catch(error) {
            assert.include(
                error.message,
                'revert'
            );
        }
    });
})
