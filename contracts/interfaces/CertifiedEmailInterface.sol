pragma solidity <0.6.0;

import "./SignaturitUserInterface.sol";
import "./CertificateInterface.sol";

contract CertifiedEmailInterface {
    address public signaturit;
    address public deployer;
    address public owner;

    string public id;
    string public subjectHash;
    string public bodyHash;
    string public deliveryType;

    string[] public certificatesId;

    uint public createdAt;

    SignaturitUserInterface public userSmartContract;

    mapping(string => CertificateInterface) private certificates;

    function notifyCreation()
        public;

    function createCertificate(
        string memory certificateId,
        uint certificateCreatedAt,
        address certificateOwner
    )
        public;

    function createEvent(
        string memory certificateId,
        string memory eventId,
        string memory eventType,
        string memory eventUserAgent,
        uint eventCreatedAt
    )
        public;

    function createFile(
        string memory certificateId,
        string memory fileHash,
        string memory fileId,
        string memory fileName,
        uint fileCreatedAt,
        uint fileSize
    )
        public;

    function getCertificate(
        string memory certificateId
    )
        public
        view
        returns (address);

    function getEvent(
        string memory certificateId,
        string memory eventId
        )
        public
        view
        returns (address);

    function getFile(
        string memory certificateId
    )
        public
        view
        returns (address);

    function getCertificatesSize()
        public
        view
        returns (uint);

    function _notifyEntityEvent (
        string memory notifiersKey,
        uint createdEvent,
        address adrToNotify
    )
        private;

    function _certificateExist(
        string memory certificateId
    )
        private
        view
        returns (bool);

    function _getCertificate(
        string memory certificateId
    )
        private
        returns (CertificateInterface);
}
