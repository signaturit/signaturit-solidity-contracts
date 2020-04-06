pragma solidity <0.6.0;

/*
Gas to deploy: 2.461.125
*/

import "./Clause.sol";
import "./libraries/UsingConstants.sol";

contract TimeLogger is UsingConstants, Clause(
    UsingConstants.TIMELOGGER_NOTIFIERS_KEY
)
{
    struct TimeLog {
        uint timeStart;
        uint timeEnd;
        string source;
        bool valid;
    }

    struct Day {
        uint[] timelogs;
        uint total;
        bool existence;
    }

    SignaturitUserInterface public ownerContract;

    bool public expired;

    uint public endDate;
    uint public startDate;
    uint public weeklyHours;
    uint public lastOpenDay = 0;

    int public duration;

    TimeLog[] public timeLog;

    mapping(uint => Day) private day;

    constructor (
        address managerContractAddress,
        address ownerContractAddress,
        address signatureContractAddress,
        string memory id,
        string memory document,
        uint start,
        uint end,
        uint weekHours,
        int contractDuration
    )
        public
    {
        contractId = id;
        documentId = document;

        startDate = start;
        endDate = end;
        weeklyHours = weekHours;
        duration = contractDuration;

        expired = false;

        userContract = SignaturitUserInterface(managerContractAddress);
        ownerContract = SignaturitUserInterface(ownerContractAddress);
        signatureContract = NotifierInterface(signatureContractAddress);

        userContract.setMappingAddressBool(VALIDATED_NOTIFIERS_KEY, userContract.ownerAddress(), true);
        userContract.setMappingAddressBool(VALIDATED_NOTIFIERS_KEY, ownerContract.ownerAddress(), true);

        _notifySignature(uint(enumEvents.TIMELOGGER_CLAUSE_CREATED));
    }

    modifier onlyManager() {
        require(
            msg.sender == address(userContract.ownerAddress()),
            "Only the manager account can perform this action"
        );

        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == address(ownerContract.ownerAddress()),
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

    //Externals
    function externalSourceLog(
        uint time
    )
        external
        onlyManager
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

    function expireContract()
        external
        onlyManager
    {
        expired = true;
    }

    function createTimeLog(
        uint thisDay,
        uint start,
        uint end
    )
        external
        onlyManager
    {
        _setDay(thisDay);

        _createLog(thisDay, start, EXTERNAL_SOURCE);

        _closeLog(thisDay, end, EXTERNAL_SOURCE);
    }

    function editTimeLog(
        uint thisDay,
        uint logIndex,
        uint start,
        uint end,
        bool validity
    )
        external
        onlyManager
    {
        require(end >= start, "Invalid time frame");

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
        if (!day[thisDay].existence) return 0;

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
        if (startDay > endDay) return 0;

        uint totalAmount = 0;

        for (uint i = startDay; i <= endDay; i++) {
            if (day[i].existence) totalAmount += day[i].total;
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
        if (
            !day[thisDay].existence ||
            day[thisDay].timelogs.length <= index
        ) {
            return (0, 0, "", false, false);
        }

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
                _closeLog(today, time, source);
            }

            lastOpenDay = 0;

            return;
        }

        _createLog(today, time, source);

        lastOpenDay = today;

        _notify(uint(enumEvents.TIMELOG_ADDED_EVENT));
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
    }

    function _closeLog(
        uint thisDay,
        uint endTime,
        string memory source
    )
        internal
    {
        uint index = day[thisDay].timelogs[day[thisDay].timelogs.length - 1];

        require(endTime >= timeLog[index].timeStart, "Invalid time frame");

        //Assumption: if source coming from input doesnt equal the one saved, prefer the last one
        if (
            keccak256(abi.encodePacked((timeLog[index].source))) != keccak256(abi.encodePacked((source)))
        )

            timeLog[index].source = source;

        timeLog[index].timeEnd = endTime;

        day[thisDay].total += endTime - timeLog[index].timeStart;
    }

    function _completePendingDays(
        uint today,
        uint nowInSeconds,
        string memory source
    )
        internal
    {
        uint lastMidnight = (lastOpenDay*SECONDS_PER_DAY)+SECONDS_PER_DAY;

        _closeLog(lastOpenDay, lastMidnight, source);

        _completeDaysInTheGap(today, lastOpenDay);

        uint todayMidnight = today*SECONDS_PER_DAY;

        _createLog(today, todayMidnight, source);

        _closeLog(today, nowInSeconds, source);
    }

    function _completeDaysInTheGap(
        uint today,
        uint lastDay
    )
        internal
    {
        //fulfill the days in the gap with 24h single log
        for (uint i = lastDay + 1; i < today; i++) {
            _setDay(i);

            uint startOfTheDay = i*SECONDS_PER_DAY;
            uint endOfTheDay = startOfTheDay + SECONDS_PER_DAY;

            _createLog(i, startOfTheDay, SOLIDITY_SOURCE);

            _closeLog(i, endOfTheDay, SOLIDITY_SOURCE);
        }
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
    {
        if (day[today].timelogs.length == 0) {
            uint[] memory tmpArray;

            day[today] = Day(tmpArray, 0, true);
        }
    }
}
