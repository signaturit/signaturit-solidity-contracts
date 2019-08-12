pragma solidity 0.5.0;

/*
Gas to deploy: 3.208.976 units of gas
*/

import "./Clause.sol";


contract TimeLogger is Clause("timelogger") {
    uint constant public SECONDS_PER_DAY = 86400;
    string constant public SOLIDITY_SOURCE = "solidity";
    string constant public EXTERNAL_SOURCE = "external";
    string constant public NOTIFICATION_EVENT = "time_log.added";

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

    uint lastOpenDay = 0;

    TimeLog[] public timeLog;

    mapping(uint => Day) public day;

    constructor(
        address userContractAddress,
        address signatureContractAddress,
        string memory id
    )
        public
    {
        contractId = id;
        signaturit = msg.sender;

        userContract = UserInterface(userContractAddress);
        signatureContract = SignatureInterface(signatureContractAddress);
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

        signatureContract.setClause(
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

    function setExpiration(
        bool status
    )
        external
        signaturitOnly
    {
        expired = status;
    }

    function createTimeLog(
        uint thisDay,
        uint start,
        uint end,
        bool validity
    ) external signaturitOnly {
        require(end >= start, "Invalid time frame");

        _setDay(thisDay);

        timeLog.push(TimeLog(start, end, EXTERNAL_SOURCE, validity));

        day[thisDay].timelogs.push(timeLog.length - 1);

        day[thisDay].total += (end - start);
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
        uint index = day[thisDay].timelogs[logIndex];

        timeLog[index].timeStart = start;
        timeLog[index].timeEnd = end;
        timeLog[index].valid = validity;
        timeLog[index].source = EXTERNAL_SOURCE;

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
        require(day[thisDay].timelogs.length > 0, "There are no logs on this day");
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

        _setDay(today);

        if (lastOpenDay != 0) {
            if (today > lastOpenDay) {
                _completePendingDays(today, time, source);
            } else {
                _completeLastLogOfDay(today, time, source);
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
        timeLog.push(TimeLog(startTime, 0, source, true));

        day[thisDay].timelogs.push(timeLog.length - 1);

        _publish();
    }

    function _closeLog(
        uint thisDay,
        uint endTime
    )
        internal
    {
        uint index = day[thisDay].timelogs[day[thisDay].timelogs.length - 1];

        timeLog[index].timeEnd = endTime;

        timeLog[index].valid = false;

        day[thisDay].total += endTime - timeLog[index].timeStart;
    }

    function _completePendingDays(
        uint today,
        uint nowInSeconds,
        string memory source
    )
        internal
    {
        require(nowInSeconds >= timeLog[day[lastOpenDay].timelogs.length - 1].timeStart, "Invalid time value");

        _completeLastOpenDay(lastOpenDay);

        _completeDaysInTheGap(today, lastOpenDay);

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
        //fulfill the days in the gap with 24h invalid single log
        for (uint i = lastDay + 1; i < today; i++) {
            uint[] memory tmpArray;

            timeLog.push(TimeLog(0, 0, SOLIDITY_SOURCE, false));

            day[i] = Day(tmpArray, SECONDS_PER_DAY);

            day[i].timelogs.push(timeLog.length - 1);

        }
    }

    function _completeLastOpenDay(
        uint lastDay
    )
        internal
    {
        uint lastMidnight = (lastDay*SECONDS_PER_DAY)+SECONDS_PER_DAY;

        uint index = day[lastDay].timelogs.length - 1;

        timeLog[index].timeEnd = lastMidnight;
        timeLog[index].valid = false;

        //Assumption: to update the total amount of the day with invalid timelogs
        day[lastDay].total += lastMidnight - timeLog[index].timeStart;
    }

    function _completeLastLogOfDay(
        uint thisDay,
        uint timeInSeconds,
        string memory source
    )
        internal
    {
        uint index = day[thisDay].timelogs[day[thisDay].timelogs.length - 1];

        require(timeInSeconds >= timeLog[index].timeStart, "Invalid time value");

        //Assumption: if source coming from input doesnt equal the one saved, prefer the last one
        if (
            keccak256(abi.encodePacked((timeLog[index].source))) != keccak256(abi.encodePacked((source)))
        )

            timeLog[index].source = source;

        timeLog[index].timeEnd = timeInSeconds;

        day[thisDay].total += (
            timeInSeconds - timeLog[index].timeStart
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

    function _setDay(
        uint today
    )
        internal
        returns(Day storage)
    {
        if (day[today].timelogs.length == 0) {
            uint[] memory tmpArray;

            day[today] = Day(tmpArray, 0);
        }

        return day[today];
    }

    function _publish()
        internal
    {
        publishNotification(
            NOTIFICATION_EVENT,
            ""
        );
    }
}
