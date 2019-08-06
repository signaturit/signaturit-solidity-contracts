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

        userContract = await ArtifactUser.new(userAddress);

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
            {from: userAddress}
        );

        const daysSinceUnixEpoch = Math.floor(timeNow / secondsInDay);

        const readTimeLog = await timeLoggerContract.timeLog(0);

        const readTotal = await timeLoggerContract.getDayTime(daysSinceUnixEpoch);
        const readTimeLogGetter = await timeLoggerContract.getTimeLog(daysSinceUnixEpoch, 0);

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
        await timeLoggerContract.setExpiration(
            true,
            {from: signaturitAddress}
        )

        try {
            await timeLoggerContract.externalSourceLog(
                timeNow,
                {from: userAddress}
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
            {from: userAddress}
        );

        const daysSinceUnixEpoch = Math.floor(timeNow / secondsInDay);
        const readTimeLog = await timeLoggerContract.timeLog(0);

        const readTotal = await timeLoggerContract.getDayTime(daysSinceUnixEpoch);
        const readTimeLogGetter = await timeLoggerContract.getTimeLog(daysSinceUnixEpoch, 0);

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
        await timeLoggerContract.setExpiration(
            true,
            {from: signaturitAddress}
        )

        try {
            await timeLoggerContract.soliditySourceLog(
                {from: userAddress}
            )

            assert.fail("Something went wrong, it should have thrown");
        } catch(error) {
            assert.include(
                error.message,
                "This contract has expired"
            );
        }
    });

    it("Call createTimeLog as Signaturit account, expect to pass", async() => {
        const daysSinceUnixEpoch = Math.floor(timeNow / secondsInDay);

        await timeLoggerContract.createTimeLog(
            daysSinceUnixEpoch,
            timeNow,
            timeNow + 100,
            {from: signaturitAddress}
        );

        const readTimeLog = await timeLoggerContract.getTimeLog(daysSinceUnixEpoch,0);
        const readTotal = await timeLoggerContract.getDayTime(daysSinceUnixEpoch);

        assert.equal(readTimeLog.start.toNumber(), timeNow);
        assert.equal(readTimeLog.end.toNumber(), timeNow + 100);
        assert.equal(readTotal.toNumber(), 100);
    });

    it("Call createTimeLog as not Signaturit account, expect exception", async() => {
        const daysSinceUnixEpoch = Math.floor(timeNow / secondsInDay);

        try {
            await timeLoggerContract.createTimeLog(
                daysSinceUnixEpoch,
                timeNow,
                timeNow + 100,
                {from: invalidAddress}
            );

            assert.fail("Something went wrong, it should have thrown");
        } catch(error) {
            assert.include(
                error.message,
                'Only Signaturit account can perform this action.'
            );
        }
    });

    it("Call correctTimeLog as Signaturit account, expect to pass", async() => {
        await timeLoggerContract.externalSourceLog(
            timeNow,
            {from: userAddress}
        );

        const daysSinceUnixEpoch = Math.floor(timeNow / secondsInDay);

        const logBeforeModification = await timeLoggerContract.getTimeLog(daysSinceUnixEpoch, 0);
        const totalBeforeModification = await timeLoggerContract.getDayTime(daysSinceUnixEpoch);

        await timeLoggerContract.correctTimeLog(
            daysSinceUnixEpoch,
            0,
            timeNow,
            timeNow + 50,
            true,
            {from: signaturitAddress}
        );

        const logAfterModification = await timeLoggerContract.getTimeLog(daysSinceUnixEpoch, 0);
        const totalAfterModification = await timeLoggerContract.getDayTime(daysSinceUnixEpoch);

        assert.equal(logBeforeModification.start.toNumber(), logAfterModification.start.toNumber());
        assert.equal(logBeforeModification.end.toNumber(), 0);
        assert.equal(logAfterModification.end.toNumber(), timeNow + 50);
        assert.equal(totalBeforeModification.toNumber(), 0);
        assert.equal(totalAfterModification.toNumber(), 50);
    });

    it("Call correctTimeLog as not Signaturit account, expect exception", async() => {
        await timeLoggerContract.externalSourceLog(
            timeNow,
            {from: userAddress}
        );

        const daysSinceUnixEpoch = Math.floor(timeNow / secondsInDay);

        try {
            await timeLoggerContract.correctTimeLog(
                daysSinceUnixEpoch,
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

    it("Call setExpiration as Signaturit account, expect to pass", async() => {
        await timeLoggerContract.setExpiration(
            true,
            {from: signaturitAddress}
        )

        const readExpirationState = await timeLoggerContract.expired();

        assert.equal(readExpirationState, true);
    });

    it("Call setExpiration as not Signaturit account, expect exception", async() => {
        try {
            await timeLoggerContract.setExpiration(
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

    it("Log time three times into two different days", async() => {
        await timeLoggerContract.externalSourceLog(
            timeTwoDaysAgo,
            {from: userAddress}
        );

        await timeLoggerContract.externalSourceLog(
            timeTwoDaysAgo + 100,
            {from: userAddress}
        );

        await timeLoggerContract.externalSourceLog(
            timeNow,
            {from: userAddress}
        );

        const daysOneSinceUnixEpoch = Math.floor(timeTwoDaysAgo / secondsInDay);
        const daysTwoSinceUnixEpoch = daysOneSinceUnixEpoch + 1;
        const daysThreeSinceUnixEpoch = Math.floor(timeNow / secondsInDay);

        const readFirstTimeLog = await timeLoggerContract.getTimeLog(daysOneSinceUnixEpoch,0);
        try {
            const readSecondTimeLog = await timeLoggerContract.getTimeLog(daysTwoSinceUnixEpoch,0);
        }catch(error) {
            assert.include(
                error.message,
                "There is no log for this day"
            );
        }
        const readThirdTimeLog = await timeLoggerContract.getTimeLog(daysThreeSinceUnixEpoch,0);

        const readFirstDayTotal = await timeLoggerContract.getDayTime(daysOneSinceUnixEpoch);
        const readSecondDayTotal = await timeLoggerContract.getDayTime(daysThreeSinceUnixEpoch);

        //midnight of today
        const todayMidnight = Math.floor(timeNow / secondsInDay) * secondsInDay;

        //check the total if correct
        assert.equal(readFirstDayTotal.toNumber(), 100);
        assert.equal(readSecondDayTotal.toNumber(), 0);

        //check validity if true
        assert.equal(readFirstTimeLog.valid, true);
        assert.equal(readThirdTimeLog.valid, true);

        // check logs are all closed
        assert.ok(readFirstTimeLog.end.toNumber() > 0);
        assert.ok(readThirdTimeLog.end.toNumber() == 0);
    });

    it("Log time twice, expect a timelog to be opened and closed and the total of the day updated", async() => {
        await timeLoggerContract.externalSourceLog(
            timeNow,
            {from: userAddress}
        );

        await timeLoggerContract.externalSourceLog(
            timeNow + 100,
            {from: userAddress}
        );


        const daysSinceUnixEpoch = Math.floor(timeNow / secondsInDay);
        const readTimeLog = await timeLoggerContract.timeLog(0);

        const readTotal = await timeLoggerContract.getDayTime(daysSinceUnixEpoch);
        const readTimeLogGetter = await timeLoggerContract.getTimeLog(daysSinceUnixEpoch, 0);

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
            {from: userAddress}
        );

        await timeLoggerContract.externalSourceLog(
            timeNow + 100,
            {from: userAddress}
        );

        const daysSinceUnixEpoch = Math.floor(timeNow / secondsInDay);

        await timeLoggerContract.correctTimeLog(
            daysSinceUnixEpoch,
            0,
            timeNow,
            timeNow + 50,
            true,
            {from: signaturitAddress}
        );

        const readTimeLog = await timeLoggerContract.timeLog(0);

        const readTotal = await timeLoggerContract.getDayTime(daysSinceUnixEpoch);
        const readTimeLogGetter = await timeLoggerContract.getTimeLog(daysSinceUnixEpoch, 0);

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
            {from: userAddress}
        );

        await timeLoggerContract.externalSourceLog(
            timeNow,
            {from: userAddress}
        );

        const daysOneSinceUnixEpoch = Math.floor(timeTwoDaysAgo / secondsInDay);
        const daysTwoSinceUnixEpoch = daysOneSinceUnixEpoch + 1;
        const daysThreeSinceUnixEpoch = Math.floor(timeNow / secondsInDay);

        const readFirstTimeLog = await timeLoggerContract.getTimeLog(daysOneSinceUnixEpoch,0);
        const readSecondTimeLog = await timeLoggerContract.getTimeLog(daysTwoSinceUnixEpoch,0);
        const readThirdTimeLog = await timeLoggerContract.getTimeLog(daysThreeSinceUnixEpoch,0);

        const readFirstDayTotal = await timeLoggerContract.getDayTime(daysOneSinceUnixEpoch);
        const readSecondDayTotal = await timeLoggerContract.getDayTime(daysTwoSinceUnixEpoch);
        const readThirdDayTotal = await timeLoggerContract.getDayTime(daysThreeSinceUnixEpoch);

        //midnight of today
        const todayMidnight = Math.floor(timeNow / secondsInDay) * secondsInDay;

        //check the total if correct
        assert.equal(readFirstDayTotal.toNumber(), secondsInDay - 1);
        assert.equal(readSecondDayTotal.toNumber(), secondsInDay);
        assert.equal(readThirdDayTotal.toNumber(), timeNow - todayMidnight);

        //check validity if false
        assert.equal(readFirstTimeLog.valid, true);
        assert.equal(readSecondTimeLog.valid, true);
        assert.equal(readThirdTimeLog.valid, true);

        const startOfSecondDay = timeTwoDaysAgo + secondsInDay - 1;

        // check logs are all closed
        assert.ok(readFirstTimeLog.end.toNumber() > 0);
        assert.ok(readThirdTimeLog.end.toNumber() > 0);
        assert.ok(
            readSecondTimeLog.end.toNumber() ==  todayMidnight &&
            readSecondTimeLog.start.toNumber() == startOfSecondDay
        );
    });
})
