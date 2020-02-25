contract('Event', async (accounts) => {
    const ArtifactEvent = artifacts.require('Event');

    const v4 = require("uuid").v4;

    const signaturitAddress = accounts[0];

    let eventContract;

    const eventId   = v4();
    const eventType = 'document opened';
    const userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.90 Safari/537.36';
    const createdAt = Date.now();

    beforeEach(async () => {
        eventContract = await ArtifactEvent.new(
            eventId,
            eventType,
            userAgent,
            createdAt,
            {
                from: signaturitAddress
            }
        );
    })

    it('Check if it deploy correctly', async () => {
        assert.ok(eventContract.address);
    });

    it('Try to deploy and retrieve data', async() => {
        const readEventId = await eventContract.id();
        const readEventType = await eventContract.eventType();
        const readUserAgent = await eventContract.userAgent();
        const readEventDate = await eventContract.createdAt();
        const readEventParent = await eventContract.parent();

        assert.equal(readEventId, eventId);
        assert.equal(readEventParent, signaturitAddress);
        assert.equal(readEventType, eventType);
        assert.equal(readUserAgent, userAgent);
        assert.equal(readEventDate, createdAt);
    });
})
