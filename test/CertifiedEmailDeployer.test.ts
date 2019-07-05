contract('CertifiedEmailDeployer', async (accounts) => {
    const ArtifactDeployer = artifacts.require('CertifiedEmailDeployer');

    const v4 = require("uuid").v4;

    const signaturitAddress = accounts[0];

    let deployerContract;

    const certificateId = v4();

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

    it('Call deployCertificate function as signaturit role', async () => {
        const certificateContractAddress = await deployerContract.deployCertificate(
            certificateId,
            deployerContract.address,
            {
                from: signaturitAddress
            }
        );

        assert.ok(certificateContractAddress);
    });
})
