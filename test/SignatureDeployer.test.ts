
contract('SignatureDeployer', async (accounts) => {
    const ArtifactDeployer = artifacts.require('SignatureDeployer');

    const v4 = require("uuid").v4;

    let deployerContract;

    const signaturitAddress = accounts[0];
    const invalidAddress = accounts[1];
    const parentAddress = accounts[2];

    const fileId = v4();

    beforeEach(async () => {
        deployerContract = await ArtifactDeployer.new(
            {
                from: signaturitAddress
            }
        )
    });

    it('Check if it deploy correctly', async () => {
        assert.ok(deployerContract.address);
    });

    it('Call deployFile function', async () => {
        const fileContractAddress = await deployerContract.deployFile(
            fileId
        );

        assert.ok(fileContractAddress);
    });
})
