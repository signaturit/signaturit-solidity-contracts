contract('SignatureAggregator', async (accounts) => {
    const ArtifactUser = artifacts.require('SignaturitUser');
    const ArtifactSignature = artifacts.require('Signature');
    const ArtifactSignatureAggregator = artifacts.require('SignatureAggregator');

    const v4 = require("uuid").v4;

    const rootAddress = accounts[0];
    const ownerAddress = accounts[1];
    const invalidAccount = accounts[2];
    const deployerAddress = accounts[3];

    const signatureId = v4();
    const signatureSecondId = v4();
    const signatureCreatedAt = Date.now();

    let signatureAggregatorContract;
    let userContract;

    beforeEach(async() => {
        userContract = await ArtifactUser.new(
            ownerAddress,
            {
                from: rootAddress
            }
        );

        signatureAggregatorContract = await ArtifactSignatureAggregator.new(
            userContract.address,
            {
                from: rootAddress
            }
        );
    });

    it("Check if it deploy correctly", async () => {
        assert.ok(signatureAggregatorContract.address);
    });


    it("Retrieve signature aggregator from user", async () => {
        const signatureAggregatorAddress = await userContract.getAddressAttribute('signature-aggregator');

        assert.equal(signatureAggregatorAddress, signatureAggregatorContract.address);
    });

    it("Deploy signature aggregator contract from invalid account", async () =>{
        try {
            await ArtifactSignatureAggregator.new(
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

    it("Create signature without call notify", async () => {
        const signatureContract = await ArtifactSignature.new(
            signatureId,
            deployerAddress,
            signatureCreatedAt,
            ownerAddress,
            userContract.address
        );

        const storedSignatures = await signatureAggregatorContract.count();

        assert.equal(0, storedSignatures.toNumber());
        assert.ok(signatureContract.address);
    });

    it("Create signature without address to notify and notify manually", async () => {
        const signatureContract = await ArtifactSignature.new(
            signatureId,
            deployerAddress,
            signatureCreatedAt,
            ownerAddress,
            userContract.address
        );

        await signatureAggregatorContract.notify(
            'signature.contract.created',
            signatureContract.address
        );

        const storedSignatures = await signatureAggregatorContract.count();

        assert.equal(1, storedSignatures.toNumber());
        assert.ok(signatureContract.address);
    });

    it("Create signature without address to notify and notify manually from invalid account, expect exception", async () => {
        const signatureContract = await ArtifactSignature.new(
            signatureId,
            deployerAddress,
            signatureCreatedAt,
            ownerAddress,
            userContract.address
        );

        try {
            await signatureAggregatorContract.notify(
                'signature.contract.created',
                signatureContract.address,
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

    it("Create signature on user with signature aggregator", async () => {
        const signatureContract = await ArtifactSignature.new(
            signatureId,
            deployerAddress,
            signatureCreatedAt,
            ownerAddress,
            userContract.address
        );

        await signatureContract.notifyCreation();

        const storedSignatures = await signatureAggregatorContract.count();
        const signatureByIdAddress = await signatureAggregatorContract.getSignatureById(signatureId);
        const signatureByIndex = await signatureAggregatorContract.getSignature(0);

        assert.equal(storedSignatures.toNumber(), 1);
        assert.equal(signatureByIdAddress, signatureContract.address);
        assert.equal(signatureByIndex.addr, signatureContract.address);
        assert.equal(signatureByIndex.more, false);
    });

    it("Create signature from invalid user and try to notify", async () => {
        const signatureContract = await ArtifactSignature.new(
            signatureId,
            deployerAddress,
            signatureCreatedAt,
            ownerAddress,
            userContract.address,
            {
                from: invalidAccount
            }
        );

        try {
            await signatureContract.notifyEntityEvent("signature-notifiers", "signature.contract.created", signatureContract.address);
        } catch(error) {
            assert.include(
                error.message,
                "Only Signaturit account can perform this action"
            )
        }
    });

    it("Create two signatures on user with signature aggregator", async () => {
        const signatureContract = await ArtifactSignature.new(
            signatureId,
            deployerAddress,
            signatureCreatedAt,
            ownerAddress,
            userContract.address
        );

        await signatureContract.notifyCreation();

        const signatureContractTwo = await ArtifactSignature.new(
            signatureSecondId,
            deployerAddress,
            signatureCreatedAt,
            ownerAddress,
            userContract.address
        );

        await signatureContractTwo.notifyCreation();

        const storedSignatures = await signatureAggregatorContract.count();
        const signatureAddressById = await signatureAggregatorContract.getSignatureById(signatureId);
        const signatureByIndex = await signatureAggregatorContract.getSignature(0);
        const secondSignatureAddressById = await signatureAggregatorContract.getSignatureById(signatureSecondId);
        const secondSignatureByIndex = await signatureAggregatorContract.getSignature(1);

        assert.equal(storedSignatures.toNumber(), 2);
        assert.equal(signatureAddressById, signatureContract.address);
        assert.equal(signatureByIndex.addr, signatureContract.address);
        assert.equal(signatureByIndex.more, true);

        assert.equal(secondSignatureAddressById, signatureContractTwo.address);
        assert.equal(secondSignatureByIndex.addr, signatureContractTwo.address);
        assert.equal(secondSignatureByIndex.more, false);
    });
})