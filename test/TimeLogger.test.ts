contract('TimeLogger', async (accounts) => {
    const ArtifactUser      = artifacts.require('User');
    const ArtifactSignature = artifacts.require('Signature');
    const ArtifactTimeLogger = artifacts.require('TimeLogger');
    const ArtifactSignatureDeployer = artifacts.require('SignatureDeployer');

    const v4 = require("uuid").v4;

    let userContract;
    let signatureContract;
    let signatureDeployer;
    let timeLoggerContract;

    const signaturitAddress = accounts[0];
    const signatureOwner = accounts[1];
    const invalidAddress = accounts[2];
    const userAddress = accounts[3];

    const clauseType = "timelogger";

    const workerId = v4();
    const contractId = v4();
    const signatureId = v4();
    const documentId  = v4();

    const secondsInDay = 86400;
    const endDate = new Date().getTime();
    const timeNow = Math.floor(new Date().getTime() / 1000);

    //two days ago at midnight + 1 second
    const twoDaysAgo = new Date().setDate(new Date().getDate() - 2);
    const timeTwoDaysAgo = (Math.floor(twoDaysAgo / 1000 / secondsInDay) * secondsInDay) + 1;

    const startDate = new Date().getTime();

    const weekHours = 40;
    const contractDuration = -1;

    beforeEach(async () => {
        signatureDeployer = await ArtifactSignatureDeployer.new();

        signatureContract = await ArtifactSignature.new(
            signatureId,
            signatureDeployer.address,
            Date.now(),
            {
                from: signaturitAddress
            }
        );

        userContract = await ArtifactUser.new(signaturitAddress);

        timeLoggerContract = await ArtifactTimeLogger.new(
            userContract.address,
            signatureContract.address,
            contractId,
            {
                from: signaturitAddress
            }
        )
    });

    it('Check if it deploy correctly', async () => {
        assert.ok(timeLoggerContract.address);

        const readContractId = await timeLoggerContract.contractId();

        const readClauseType = await timeLoggerContract.clause();

        assert.equal(readClauseType, clauseType);
        assert.equal(readContractId, contractId);
    });

    it('Call init as Signaturit account, expect to pass', async() => {
        await timeLoggerContract.init(
            signatureId,
            documentId,
            workerId,
            startDate,
            endDate,
            weekHours,
            contractDuration,
            {from: signaturitAddress}
        )

        const readEndDate = await timeLoggerContract.endDate();
        const readWorkerId = await timeLoggerContract.workerId();
        const readDuration = await timeLoggerContract.duration();
        const readStartDate = await timeLoggerContract.startDate();
        const readWeekHours = await timeLoggerContract.weeklyHours();
        const readDocumentId = await timeLoggerContract.documentId();
        const readSignatureId = await timeLoggerContract.signatureId();

        const readClauseAddress = await signatureContract.getClause('timelogger');

        assert.equal(readEndDate, endDate);
        assert.equal(readWorkerId, workerId);
        assert.equal(readWeekHours, weekHours);
        assert.equal(readStartDate, startDate);
        assert.equal(readDocumentId, documentId);
        assert.equal(readSignatureId, signatureId);
        assert.equal(readClauseAddress, timeLoggerContract.address);
    });

    it('Call init as not Signaturit account, expect exception', async() => {
        try {
            await timeLoggerContract.init(
                signatureId,
                documentId,
                workerId,
                startDate,
                endDate,
                weekHours,
                contractDuration,
                {from: invalidAddress}
            )

            assert.fail("Something went wrong, it should have thrown");
        } catch(error) {
            assert.include(
                error.message,
                'Only Signaturit account can perform this action.'
            );
        }
    });

    it("Call externalSourceLog as Owner account, expect to pass", async() => {
        await timeLoggerContract.externalSourceLog(
            timeNow,
            {from: signaturitAddress}
        );

        const readArrayElement = await timeLoggerContract.daysArray(0);
        const readTimeLog = await timeLoggerContract.timeLog(0);

        const readTotal = await timeLoggerContract.getDayTime(readArrayElement);
        const readTimeLogGetter = await timeLoggerContract.getTimeLog(readArrayElement, 0);

        assert.equal(readTotal.toNumber(), 0);
        assert.equal(readTimeLog.valid, true);
        assert.equal(readTimeLog.valid, readTimeLogGetter.valid);
        assert.equal(readTimeLog.source, readTimeLogGetter.source);
        assert.equal(readTimeLog.timeEnd.toNumber(), readTimeLogGetter.end.toNumber());
        assert.equal(readTimeLog.timeStart.toNumber(), readTimeLogGetter.start.toNumber());
    });

    it("Call externalSourceLog as not Owner account, expect exception", async() =>  {
        try {
            await timeLoggerContract.externalSourceLog(
                timeNow,
                {from: invalidAddress}
            )

            assert.fail("Something went wrong, it should have thrown");
        } catch(error) {
            assert.include(
                error.message,
                "Only the owner account can perform this action"
            );
        }
    });

    it("Call externalSourceLog when expired, expect exception", async() =>  {
        await timeLoggerContract.toggleExpiration(
            true,
            {from: signaturitAddress}
        )

        try {
            await timeLoggerContract.externalSourceLog(
                timeNow,
                {from: signaturitAddress}
            )

            assert.fail("Something went wrong, it should have thrown");
        } catch(error) {
            assert.include(
                error.message,
                "This contract has expired"
            );
        }
    });

    it("Call soliditySourceLog as Owner account, expect to pass", async() => {
        await timeLoggerContract.soliditySourceLog(
            {from: signaturitAddress}
        );

        const readArrayElement = await timeLoggerContract.daysArray(0);
        const readTimeLog = await timeLoggerContract.timeLog(0);

        const readTotal = await timeLoggerContract.getDayTime(readArrayElement);
        const readTimeLogGetter = await timeLoggerContract.getTimeLog(readArrayElement, 0);

        assert.equal(readTotal.toNumber(), 0);
        assert.equal(readTimeLog.valid, true);
        assert.equal(readTimeLog.valid, readTimeLogGetter.valid);
        assert.equal(readTimeLog.source, readTimeLogGetter.source);
        assert.equal(readTimeLog.timeEnd.toNumber(), readTimeLogGetter.end.toNumber());
        assert.equal(readTimeLog.timeStart.toNumber(), readTimeLogGetter.start.toNumber());
    });

    it("Call soliditySourceLog as not Owner account, expect exception", async() =>  {
        try {
            await timeLoggerContract.soliditySourceLog(
                {from: invalidAddress}
            )

            assert.fail("Something went wrong, it should have thrown");
        } catch(error) {
            assert.include(
                error.message,
                "Only the owner account can perform this action"
            );
        }
    });

    it("Call soliditySourceLog when expired, expect exception", async() =>  {
        await timeLoggerContract.toggleExpiration(
            true,
            {from: signaturitAddress}
        )

        try {
            await timeLoggerContract.soliditySourceLog(
                {from: signaturitAddress}
            )

            assert.fail("Something went wrong, it should have thrown");
        } catch(error) {
            assert.include(
                error.message,
                "This contract has expired"
            );
        }
    });

    it("Call correctTimeLog as not Signaturit account, expect exception", async() => {
        await timeLoggerContract.externalSourceLog(
            timeNow,
            {from: signaturitAddress}
        );

        const readArrayElement = await timeLoggerContract.daysArray(0);

        try {
            await timeLoggerContract.correctTimeLog(
                readArrayElement,
                0,
                timeNow,
                timeNow + 50,
                true,
                {from: invalidAddress}
            )

            assert.fail("Something went wrong, it should have thrown");
        } catch(error) {
            assert.include(
                error.message,
                'Only Signaturit account can perform this action.'
            );
        }
    });

    it("Call toggleExpiration as not Signaturit account, expect exception", async() => {
        try {
            await timeLoggerContract.toggleExpiration(
                true,
                {from: invalidAddress}
            )

            assert.fail("Something went wrong, it should have thrown");
        } catch(error) {
            assert.include(
                error.message,
                'Only Signaturit account can perform this action.'
            );
        }
    });

    it("Log time twice, expect a timelog to be opened and closed and the total of the day updated", async() => {
        await timeLoggerContract.externalSourceLog(
            timeNow,
            {from: signaturitAddress}
        );

        await timeLoggerContract.externalSourceLog(
            timeNow + 100,
            {from: signaturitAddress}
        );


        const readArrayElement = await timeLoggerContract.daysArray(0);
        const readTimeLog = await timeLoggerContract.timeLog(0);

        const readTotal = await timeLoggerContract.getDayTime(readArrayElement);
        const readTimeLogGetter = await timeLoggerContract.getTimeLog(readArrayElement, 0);

        assert.equal(readTotal.toNumber(), 100);
        assert.equal(readTimeLog.valid, true);
        assert.equal(readTimeLog.valid, readTimeLogGetter.valid);
        assert.equal(readTimeLog.source, readTimeLogGetter.source);
        assert.ok(readTimeLog.timeEnd.toNumber() > 0);
        assert.equal(readTimeLog.timeEnd.toNumber(), readTimeLogGetter.end.toNumber());
        assert.equal(readTimeLog.timeStart.toNumber(), readTimeLogGetter.start.toNumber());
    });

    it("Log time twice, and modify a concrete timelog, expect total to be recalculated", async() => {
        await timeLoggerContract.externalSourceLog(
            timeNow,
            {from: signaturitAddress}
        );

        await timeLoggerContract.externalSourceLog(
            timeNow + 100,
            {from: signaturitAddress}
        );

        const readArrayElement = await timeLoggerContract.daysArray(0);

        await timeLoggerContract.correctTimeLog(
            readArrayElement,
            0,
            timeNow,
            timeNow + 50,
            true,
            {from: signaturitAddress}
        );

        const readTimeLog = await timeLoggerContract.timeLog(0);

        const readTotal = await timeLoggerContract.getDayTime(readArrayElement);
        const readTimeLogGetter = await timeLoggerContract.getTimeLog(readArrayElement, 0);

        assert.equal(readTotal.toNumber(), 50);
        assert.equal(readTimeLog.valid, true);
        assert.equal(readTimeLog.valid, readTimeLogGetter.valid);
        assert.equal(readTimeLog.source, readTimeLogGetter.source);
        assert.ok(readTimeLog.timeEnd.toNumber() > 0);
        assert.equal(readTimeLog.timeEnd.toNumber(), readTimeLogGetter.end.toNumber());
        assert.equal(readTimeLog.timeStart.toNumber(), readTimeLogGetter.start.toNumber());
    });

    it("Leave a day open and log time two days after, expect gap to be filled and old day closed", async() => {
        await timeLoggerContract.externalSourceLog(
            timeTwoDaysAgo,
            {from: signaturitAddress}
        );

        await timeLoggerContract.externalSourceLog(
            timeNow,
            {from: signaturitAddress}
        );

        const readFirstDay = await timeLoggerContract.daysArray(0);
        const readSecondDay = await timeLoggerContract.daysArray(1);
        const readThirdDay = await timeLoggerContract.daysArray(2);

        const readFirstTimeLog = await timeLoggerContract.timeLog(0);
        const readSecondTimeLog = await timeLoggerContract.timeLog(1);
        const readThirdTimeLog = await timeLoggerContract.timeLog(2);

        const readFirstDayTotal = await timeLoggerContract.getDayTime(readFirstDay);
        const readSecondDayTotal = await timeLoggerContract.getDayTime(readSecondDay);
        const readThirdDayTotal = await timeLoggerContract.getDayTime(readThirdDay);

        //midnight of today
        const todayMidnight = Math.floor(timeNow / secondsInDay) * secondsInDay;

        //check the total if correct
        assert.equal(readFirstDayTotal.toNumber(), secondsInDay - 1);
        assert.equal(readSecondDayTotal.toNumber(), secondsInDay);
        assert.equal(readThirdDayTotal.toNumber(), timeNow - todayMidnight);

        //check validity if false
        assert.equal(readFirstTimeLog.valid, false);
        assert.equal(readSecondTimeLog.valid, false);
        assert.equal(readThirdTimeLog.valid, false);

        //check logs are all closed
        assert.ok(readFirstTimeLog.timeEnd.toNumber() > 0);
        assert.ok(readThirdTimeLog.timeEnd.toNumber() > 0);
        assert.ok(
            readSecondTimeLog.timeEnd.toNumber() == 0 &&
            readSecondTimeLog.timeStart.toNumber() == 0
        );
    });
})
