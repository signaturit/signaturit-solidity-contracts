pragma solidity <0.6.0;

/*
Gas to deploy: 2.561.586
*/

contract UsingConstants {
    
    string constant internal FILE_NOTIFIERS_KEY = "file-notifiers";
    string constant internal EVENT_NOTIFIERS_KEY = "event-notifiers";
    string constant internal DOCUMENT_NOTIFIERS_KEY = "document-notifiers";
    string constant internal SIGNATURE_NOTIFIERS_KEY = "signature-notifiers";
    string constant internal TIMELOGGER_NOTIFIERS_KEY = "timelogger-clause-notifiers";
    string constant internal CERTIFICATE_NOTIFIERS_KEY = "certificate-notifiers";
    string constant internal PAYMENT_CHECKS_NOTIFIERS_KEY = "payment-clause-notifiers";
    string constant internal CERTIFIED_FILE_NOTIFIERS_KEY = "certified-file-notifiers";
    string constant internal CERTIFIED_EMAIL_NOTIFIERS_KEY = "certified-email-notifiers";
    string constant internal VALIDATED_NOTIFIERS_KEY = "validated-notifiers";

    string constant internal USER_EVENTS = "user_events";

    string constant internal PAYMENT_CLAUSE_KEY = "payment";
    string constant internal TIMELOGGER_CLAUSE_KEY = "timelogger";

    uint constant internal SECONDS_PER_DAY = 86400;

    string constant internal SOLIDITY_SOURCE = "Solidity";
    string constant internal EXTERNAL_SOURCE = "External";
    
    enum enumEvents {
        FILE_CREATED_EVENT,
        CERTIFIED_FILE_CREATED_EVENT,
        EVENT_CREATED_EVENT,
        DOCUMENT_CREATED_EVENT,
        CERTIFICATE_CREATED_EVENT,
        SIGNATURE_CREATED_EVENT,
        CERTIFIED_EMAIL_CREATED_EVENT,
        TIMELOGGER_CLAUSE_CREATED,
        TIMELOG_ADDED_EVENT,
        PAYMENT_CLAUSE_CREATED,
        PAYMENT_CHECK_ADDED_EVENT
    }

    enum keys {
        PAYMENT_CLAUSE_KEY,
        TIMELOGGER_CLAUSE_KEY
    }

    constructor() public {}
}