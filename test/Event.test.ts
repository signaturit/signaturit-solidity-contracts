contract('Event', async (accounts) => {
    const ArtifactEvent = artifacts.require('Event');

    const v4 = require("uuid").v4;

    let signaturitAddress = accounts[0];

    let eventContract;

    const eventId   = v4();
    const eventType = 'document opened';
    const userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.90 Safari/537.36';
    const createdAt = Date.now();

    it('Check if it deploy correctly', async () => {
        eventContract = await ArtifactEvent.new(
            eventId,
            eventType,
            userAgent,
            createdAt,
            {from: signaturitAddress}
        );

        assert.ok(eventContract.address);
    });

    it('Try to deploy and retrieve data', async() => {
        eventContract = await ArtifactEvent.new(
            eventId,
            eventType,
            userAgent,
            createdAt,
            {from: signaturitAddress}
        );

        const readEventId = await eventContract.id();
        const readEventType = await eventContract.eventType();
        const readUserAgent = await eventContract.userAgent();
        const readEventDate = await eventContract.createdAt();

        assert.equal(readEventId, eventId);
        assert.equal(readEventType, eventType);
        assert.equal(readUserAgent, userAgent);
        assert.equal(readEventDate, createdAt);
    });
})
