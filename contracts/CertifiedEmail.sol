pragma solidity <0.6.0;

/*
Gas to deploy: 2.707.646
*/

import "./interfaces/CertifiedEmailInterface.sol";
import "./interfaces/SignaturitUserInterface.sol";
import "./interfaces/CertificateInterface.sol";
import "./interfaces/EventInterface.sol";
import "./interfaces/FileInterface.sol";
import "./libraries/Utils.sol";


contract CertifiedEmail is CertifiedEmailInterface {
    string constant private CERTIFIED_EMAIL_CREATED_EVENT = "certified_email.contract.created";
    string constant private CERTIFICATE_CREATED_EVENT = "certificate.contract.created";
    string constant private FILE_CREATED_EVENT = "file.contract.created";
    string constant private EVENT_CREATED_EVENT = "event.contract.created";

    string constant private CERTIFIED_EMAIL_NOTIFIERS_KEY = "certified-email-notifiers";
    string constant private CERTIFICATE_NOTIFIERS_KEY = "certificate-notifiers";
    string constant private FILE_NOTIFIERS_KEY = "file-notifiers";
    string constant private EVENT_NOTIFIERS_KEY = "event-notifiers";

    address public signaturit;
    address public deployer;
    address public owner;

    string public id;
    string public subjectHash;
    string public bodyHash;
    string public deliveryType;

    string[] public certificatesId;

    uint public createdAt;

    SignaturitUserInterface public userContract;

    mapping(string => CertificateInterface) private certificates;

    constructor(
        string memory certifiedEmailId,
        string memory certifiedEmailSubjectHash,
        string memory certifiedEmailBodyHash,
        string memory certifiedEmailDeliveryType,
        uint certifiedEmailCreatedAt,
        address certifiedEmailDeployer,
        address certifiedEmailOwner,
        address userSmartContractAddress
    ) public {
        id = certifiedEmailId;
        subjectHash = certifiedEmailSubjectHash;
        bodyHash = certifiedEmailBodyHash;
        deliveryType = certifiedEmailDeliveryType;
        createdAt = certifiedEmailCreatedAt;
        deployer = certifiedEmailDeployer;
        signaturit = msg.sender;

        owner = certifiedEmailOwner;

        userContract = SignaturitUserInterface(userSmartContractAddress);
    }

    modifier signaturitOnly () {
        require(
            tx.origin == signaturit,
            "Only Signaturit account can perform this action"
        );

        _;
    }

    function notifyCreation()
        public
        signaturitOnly
    {
        notifyEntityEvent(CERTIFIED_EMAIL_NOTIFIERS_KEY, CERTIFIED_EMAIL_CREATED_EVENT, address(this));
    }

    function createCertificate(
        string memory certificateId,
        uint certificateCreatedAt,
        address certificateOwner
    )
        public
        signaturitOnly
    {
        CertificateInterface certificate = _getCertificate(certificateId);

        certificate.init(certificateOwner, certificateCreatedAt);

        certificatesId.push(certificateId);

        notifyEntityEvent(CERTIFICATE_NOTIFIERS_KEY, CERTIFICATE_CREATED_EVENT, address(certificate));
    }

    function createEvent(
        string memory certificateId,
        string memory eventId,
        string memory eventType,
        string memory eventUserAgent,
        uint eventCreatedAt
    )
        public
        signaturitOnly
    {
        CertificateInterface certificate = _getCertificate(certificateId);

        certificate.createEvent(
            eventId,
            eventType,
            eventUserAgent,
            eventCreatedAt
        );

        EventInterface certifiedEmailEvent = EventInterface(certificate.getEvent(eventId));

        require(
            address(certifiedEmailEvent) != address(0),
            "Error while retrieving event from certificate"
        );

        notifyEntityEvent(EVENT_NOTIFIERS_KEY, EVENT_CREATED_EVENT, address(certifiedEmailEvent));
    }

    function createFile(
        string memory certificateId,
        string memory fileHash,
        string memory fileId,
        string memory fileName,
        uint fileCreatedAt,
        uint fileSize
    )
        public
        signaturitOnly
    {
        CertificateInterface certificate = _getCertificate(certificateId);

        certificate.createFile(
            fileHash,
            fileId,
            fileName,
            fileCreatedAt,
            fileSize
        );

        FileInterface certifiedEmailFile = certificate.file();

        require(
            address(certifiedEmailFile) != address(0),
            "Error while retrieving file from certificate"
        );

        notifyEntityEvent(FILE_NOTIFIERS_KEY, FILE_CREATED_EVENT, address(certifiedEmailFile));
    }

    function getCertificate (
        string memory certificateId
    )
        public
        view
        returns (address)
    {
        if (!_certificateExist(certificateId)) return address(0);

        return address(certificates[certificateId]);
    }

    function getCertificateByIndex(
        uint index
    )
        public
        view
        returns (address)
    {
        if (index > certificatesId.length - 1) return address(0);

        return address(certificates[certificatesId[index]]);
    }


    function getEvent(
        string memory certificateId,
        string memory eventId
    )
        public
        view
        returns (address)
    {
        if (!_certificateExist(certificateId)) return address(0);

        EventInterface certifiedEmailEvent = EventInterface(certificates[certificateId].getEvent(
            eventId
        ));

        if (address(certifiedEmailEvent) == address(0)) return address(0);

        return address(certifiedEmailEvent);
    }

    function getFile(
        string memory certificateId
    )
        public
        view
        returns (address)
    {
        if (!_certificateExist(certificateId)) return address(0);

        FileInterface certifiedEmailFile = certificates[certificateId].file();

        if (address(certifiedEmailFile) == address(0)) return address(0);

        return address(certifiedEmailFile);
    }

    function getCertificatesSize()
        public
        view
        returns (uint)
    {
        return certificatesId.length;
    }

    function notifyEntityEvent (
        string memory notifiersKey,
        string memory createdEvent,
        address adrToNotify
    )
        public
        signaturitOnly
    {
        address contractToNofify;
        uint notificationIndex = 0;

        do {
            contractToNofify = userContract.getAddressArrayAttribute(notifiersKey, notificationIndex);
            ++notificationIndex;

            if (contractToNofify != address(0)) {
                contractToNofify.call(
                    abi.encodeWithSignature(
                        "notify(string,address)",
                        createdEvent,
                        adrToNotify
                    )
                );
            }
        } while (contractToNofify != address(0));
    }


    function _certificateExist(
        string memory certificateId
    )
        private
        view
        returns (bool)
    {
        return address(certificates[certificateId]) != address(0);
    }

    function _getCertificate(
        string memory certificateId
    )
        private
        returns (CertificateInterface)
    {
        if (_certificateExist(certificateId))
            return certificates[certificateId];

        (
            bool success,
            bytes memory returnData
        ) = deployer.delegatecall(
            abi.encodeWithSignature(
                "deployCertificate(string,address)",
                certificateId,
                deployer
            )
        );

        require(
            success,
            "Error while deploying certificate"
        );

        certificates[certificateId] = CertificateInterface(
            Utils._bytesToAddress(returnData)
        );

        return certificates[certificateId];
    }
}
