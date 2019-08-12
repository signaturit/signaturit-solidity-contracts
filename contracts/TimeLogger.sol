pragma solidity 0.5.0;

/*
Gas to deploy: 3.208.976 units of gas
*/

import "./Clause.sol";


contract TimeLogger is Clause("timelogger") {
    uint constant public SECONDS_PER_DAY = 86400;
    string constant public SOLIDITY_SOURCE = "solidity";
    string constant public EXTERNAL_SOURCE = "external";
    string constant public NOTIFICATION = "time_log.added";

    struct TimeLog {
        uint timeStart;
        uint timeEnd;
        string source;
        bool valid;
    }

    struct Day {
        uint[] timelogs;
        uint total;
    }

    string public workerId;

    bool public expired;

    uint public endDate;
    uint public startDate;
    uint public weeklyHours;

    int public duration;

    uint public lastOpenDay = 0;
    uint public timeLogIndex = 0;

    uint[] public daysArray;

    mapping(uint => Day) public day;

    mapping(uint => TimeLog) public timeLog;

    constructor(
        address userContractAddress,
        address signatureContract,
        string memory id
    )
        public
    {
        contractId = id;
        signaturit = msg.sender;

        userContract = UserInterface(userContractAddress);
        signatureSmartContract = SignatureInterface(signatureContract);
    }

    modifier signaturitOnly() {
        require(
            msg.sender == signaturit,
            "Only Signaturit account can perform this action"
        );

        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == address(userContract.userAddress()),
            "Only the owner account can perform this action"
        );

        _;
    }

    modifier notExpired() {
        require(
            expired == false,
            "This contract has expired"
        );

        _;
    }

    function init(
        string memory signature,
        string memory document,
        string memory worker,
        uint start,
        uint end,
        uint weekHours,
        int contractDuration
    )
        public
        signaturitOnly
    {
        expired = false;

        endDate = end;
        startDate = start;
        workerId = worker;
        documentId = document;
        weeklyHours = weekHours;
        signatureId = signature;
        duration = contractDuration;

        signatureSmartContract.setClause(
            clause,
            address(this)
        );
    }

    //Externals

    function externalSourceLog(
        uint time
    )
        external
        onlyOwner
        notExpired
    {
        _logTime(time, EXTERNAL_SOURCE);
    }

    function soliditySourceLog()
        external
        onlyOwner
        notExpired
    {
        _logTime(block.timestamp, SOLIDITY_SOURCE);
    }

    function toggleExpiration(
        bool status
    )
        external
        signaturitOnly
    {
        expired = status;
    }

    function correctTimeLog(
        uint thisDay,
        uint logIndex,
        uint start,
        uint end,
        bool validity
    )
        external
        signaturitOnly
    {
        timeLog[day[thisDay].timelogs[logIndex]].timeStart = start;
        timeLog[day[thisDay].timelogs[logIndex]].timeEnd = end;
        timeLog[day[thisDay].timelogs[logIndex]].valid = validity;
        timeLog[day[thisDay].timelogs[logIndex]].source = EXTERNAL_SOURCE;

        _recalculateTotal(thisDay);
    }

    //Getters

    function getDayTime(
        uint thisDay
    )
        external
        view
        returns(uint total)
    {
        return day[thisDay].total;
    }

    function getTotalLoggedTime(
        uint startDay,
        uint endDay
    )
        external
        view
        returns(uint total)
    {
        require(startDay >= endDay, "Invalid time frame");

        uint totalAmount;

        for (uint i = startDay; i <= endDay; i++) {
            total += day[i].total;
        }

        return totalAmount;
    }

    function getTimeLog(
        uint thisDay,
        uint index
    )
        external
        view
        returns(
            uint start,
            uint end,
            string memory source,
            bool valid,
            bool more
        )
    {
        require(day[thisDay].timelogs.length > 0, "There is no log for this day");
        require(index < day[thisDay].timelogs.length, "There are less log than this index");

        bool thereIsMore = false;

        if (index < day[thisDay].timelogs.length - 1) thereIsMore = true;

        return (
            timeLog[day[thisDay].timelogs[index]].timeStart,
            timeLog[day[thisDay].timelogs[index]].timeEnd,
            timeLog[day[thisDay].timelogs[index]].source,
            timeLog[day[thisDay].timelogs[index]].valid,
            thereIsMore
        );
    }

    //Internals

    function _logTime(
        uint time,
        string memory source
    )
        internal
    {
        uint today = time / SECONDS_PER_DAY;

        _getToday(today);

        if (lastOpenDay != 0) {
            if (today > lastOpenDay) {
                _completePendingDays(today, time, source);
            } else {
                _completeLastLog(today, time, source);
            }

            lastOpenDay = 0;

            return;
        }

        _createLog(today, time, source);

        lastOpenDay = today;
    }

    function _createLog(
        uint thisDay,
        uint startTime,
        string memory source
    )
        internal
    {
        timeLog[timeLogIndex] = TimeLog(startTime, 0, source, true);

        day[thisDay].timelogs.push(timeLogIndex);

        _publish();

        timeLogIndex++;
    }

    function _closeLog(
        uint thisDay,
        uint endTime
    )
        internal
    {
        timeLog[day[thisDay].timelogs[day[thisDay].timelogs.length - 1]].timeEnd = endTime;

        timeLog[day[thisDay].timelogs[day[thisDay].timelogs.length - 1]].valid = false;

        day[thisDay].total += endTime - timeLog[day[thisDay].timelogs[day[thisDay].timelogs.length - 1]].timeStart;
    }

    function _completePendingDays(
        uint today,
        uint nowInSeconds,
        string memory source
    )
        internal
    {
        uint lastDay = daysArray[daysArray.length - 2];

        require(nowInSeconds >= timeLog[day[lastDay].timelogs.length - 1].timeStart, "Invalid time value");

        _completeLastOpenDay(lastDay);

        _completeDaysInTheGap(today, lastDay);

        uint todayMidnight = today*SECONDS_PER_DAY;

        _createLog(today, todayMidnight, source);

        _closeLog(today, nowInSeconds);

        _publish();
    }

    function _completeDaysInTheGap(
        uint today,
        uint lastDay
    )
        internal
    {
        //remove from the array temporarly the last day to save the days
        //in between in order
        uint tmpDay = daysArray[daysArray.length - 1];
        daysArray.length--;

        //fulfill the days in the gap with 24h invalid single log
        for (uint i = lastDay + 1; i < today; i++) {
            uint[] memory tmpArray;

            timeLog[timeLogIndex] = TimeLog(0, 0, SOLIDITY_SOURCE, false);

            day[i] = Day(tmpArray, SECONDS_PER_DAY);

            day[i].timelogs.push(timeLogIndex);

            daysArray.push(i);

            timeLogIndex++;
        }

        //restore the last day into the array
        daysArray.push(tmpDay);
    }

    function _completeLastOpenDay(
        uint lastDay
    )
        internal
    {
        uint lastMidnight = (lastDay*SECONDS_PER_DAY)+SECONDS_PER_DAY;

        timeLog[day[lastDay].timelogs.length - 1].timeEnd = lastMidnight;
        timeLog[day[lastDay].timelogs.length - 1].valid = false;

        //Assumption: to update the total amount of the day with invalid timelogs
        day[lastDay].total += lastMidnight - timeLog[day[lastDay].timelogs.length - 1].timeStart;
    }

    function _completeLastLog(
        uint today,
        uint timeInSeconds,
        string memory source
    )
        internal
    {
        require(timeInSeconds >= timeLog[day[today].timelogs.length - 1].timeStart, "Invalid time value");

        //Assumption: if source coming from input doesnt equal the one saved, prefer the last one
        if (
            keccak256(abi.encodePacked((timeLog[day[today].timelogs.length - 1].source))) != keccak256(abi.encodePacked((source)))
        )

            timeLog[day[today].timelogs.length - 1].source = source;

        timeLog[day[today].timelogs.length - 1].timeEnd = timeInSeconds;

        day[today].total += (
            timeInSeconds - timeLog[day[today].timelogs.length - 1].timeStart
        );

        _publish();
    }

    function _recalculateTotal(
        uint thisDay
    )
        internal
    {
        uint totalAmount;

        for (uint i = 0; i < day[thisDay].timelogs.length; i++) {
            totalAmount += (
                    timeLog[day[thisDay].timelogs[i]].timeEnd - timeLog[day[thisDay].timelogs[i]].timeStart
            );
        }

        day[thisDay].total = totalAmount;
    }

    function _getToday(
        uint today
    )
        internal
        returns(Day storage)
    {
        if (day[today].timelogs.length == 0) {
            uint[] memory tmpArray;

            daysArray.push(today);

            day[today] = Day(tmpArray, 0);
        }

        return day[today];
    }

    function _publish()
        internal
    {
        publishNotification(
            address(this),
            clause,
            NOTIFICATION,
            ""
        );
    }
}
