pragma solidity <0.6.0;

/*
Gas to deploy: 2.379.930
*/

import "./interfaces/CertifiedEmailInterface.sol";
import "./interfaces/UserInterface.sol";
import "./interfaces/CertificateInterface.sol";
import "./interfaces/EventInterface.sol";
import "./interfaces/FileInterface.sol";
import "./libraries/Utils.sol";


contract CertifiedEmail is CertifiedEmailInterface {
    address public signaturit;
    address public deployer;
    address public owner;

    string public id;
    string public subjectHash;
    string public bodyHash;
    string public deliveryType;

    string[] public certificatesId;

    uint public createdAt;

    UserInterface public userSmartContract;

    mapping(string => CertificateInterface) private certificates;

    constructor(
        string memory certifiedEmailId,
        string memory certifiedEmailSubjectHash,
        string memory certifiedEmailBodyHash,
        string memory certifiedEmailDeliveryType,
        uint certifiedEmailCreatedAt,
        address certifiedEmailDeployer
    ) public {
        id = certifiedEmailId;
        subjectHash = certifiedEmailSubjectHash;
        bodyHash = certifiedEmailBodyHash;
        deliveryType = certifiedEmailDeliveryType;
        createdAt = certifiedEmailCreatedAt;
        deployer = certifiedEmailDeployer;
        signaturit = msg.sender;
    }

    modifier signaturitOnly () {
        require(
            signaturit == msg.sender,
            "Only Signaturit account can perform this action"
        );

        _;
    }

    function setCertifiedEmailOwner(
        address certifiedEmailOwner,
        address userSmartContractAddress
    )
        public
        signaturitOnly
    {
        owner = certifiedEmailOwner;

        userSmartContract = UserInterface(userSmartContractAddress);

        userSmartContract.addCertifiedEmail(address(this), id);
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

        userSmartContract.addCertificate(address(certificate));

        certificatesId.push(certificateId);
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

        userSmartContract.addEvent(
            "certified_email",
            address(certifiedEmailEvent)
        );
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

        userSmartContract.addFile(
            "certified_email",
            address(certifiedEmailFile)
        );
    }

    function getCertificate (
        string memory certificateId
    )
        public
        view
        returns (address)
    {
        require(
            _certificateExist(certificateId),
            "The certificate with this id doesn't exist"
        );

        return address(certificates[certificateId]);
    }

    function getEvent(
        string memory certificateId,
        string memory eventId
    )
        public
        view
        returns (EventInterface)
    {
        require(
            _certificateExist(certificateId),
            "The certificate with this id doesn't exist"
        );

        EventInterface certifiedEmailEvent = EventInterface(certificates[certificateId].getEvent(
            eventId
        ));

        require(
            address(certifiedEmailEvent) != address(0),
            "Error while retrieving event from certificate"
        );

        return certifiedEmailEvent;
    }

    function getFile(
        string memory certificateId
    )
        public
        view
        returns (FileInterface)
    {
        require(
            _certificateExist(certificateId),
            "The certificate with this id doesn't exist"
        );

        FileInterface certifiedEmailFile = certificates[certificateId].file();

        require(
            address(certifiedEmailFile) != address(0),
            "Error while retrieving event from certificate"
        );

        return certifiedEmailFile;
    }

    function getCertificatesSize()
        public
        view
        returns (uint)
    {
        return certificatesId.length;
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
