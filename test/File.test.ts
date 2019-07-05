contract('File', async (accounts) => {
    const ArtifactFile = artifacts.require('File');

    const v4 = require("uuid").v4;

    let fileContract;

    let signaturitAddress = accounts[0];
    let notOwnerAddress = accounts[1];

    const fileId = v4();
    const fileName = 'Test.pdf';
    const fileHash = 'File hash';
    const fileSize = 123;
    const badFileSize = 0;
    const fileCreatedAt = Date.now();

    beforeEach(async () => {
        fileContract = await ArtifactFile.new(
            fileId,
            {
                from: signaturitAddress
            }
        );
    });

    it('Check if it deploy correctly', async () => {
        assert.ok(fileContract.address);
    });

    it('Try to initialize with invalid fileSize, expect exception', async() => {
        try {
             const initTransaction = await fileContract.init(
                 fileName,
                 fileHash,
                 fileCreatedAt,
                 badFileSize,
                 {
                     from: signaturitAddress
                 }
             );

             assert.fail('It should have thrown');
         } catch (error) {

             assert.include(
                 error.message,
                 'Invalid input value(s).'
             );
         }
    });

    it('Try to initialize as parent role, expect to pass and check correctness', async() => {
        const initTransaction = await fileContract.init(
            fileName,
            fileHash,
            fileCreatedAt,
            fileSize
        );

        const readId = await fileContract.id();
        const readName = await fileContract.name();
        const readCreatedAt = await fileContract.createdAt();
        const readSize = await fileContract.size();
        const readHash = await fileContract.originalFileHash();

        assert.equal(fileId, readId);
        assert.equal(fileName, readName);
        assert.equal(fileSize, readSize);
        assert.equal(fileHash, readHash);
        assert.equal(fileCreatedAt, readCreatedAt);
    });

    it('Try to initialize as not parent role, expect exception', async() => {
       try {
            const initTransaction = await fileContract.init(
                fileName,
                fileHash,
                fileCreatedAt,
                fileSize,
                {
                    from: notOwnerAddress
                }
            );

            assert.fail('Unauthorized user');
        } catch (error) {
            assert.include(
                error.message,
                'Only the parent account can perform this action.'
            );
        }
    })

})
