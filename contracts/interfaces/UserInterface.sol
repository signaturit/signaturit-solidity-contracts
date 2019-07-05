pragma solidity 0.5.0;


contract UserInterface {
    address public signaturitAddress;
    address public userAddress;

    event SignatureAdded(address adr);
    event DocumentAdded(address adr);
    event FileAdded(address adr, string source);
    event EventAdded(address adr, string source);
    event CertifiedEmailAdded(address adr);
    event CertificateAdded(address adr);
    event CertifiedFileAdded(address adr);
    event PaymentCheck(
        address paymentContract,
        string referenceId,
        string receiverId,
        string statementId,
        string status,
        uint receivedAt,
        uint checkedAt
    );

    function addSignature(
        address signatureAddress,
        string memory id
    )
        public;

    function addDocument(
        address documentAddress
    )
        public;

    function addFile(
        string memory fileType,
        address fileAddress
    )
        public;

    function addEvent(
        string memory eventSource,
        address eventAddress
    )
        public;

    function addCertifiedEmail(
        address certifiedEmailAddress,
        string memory id
    )
        public;

    function addCertificate(
        address certificate
    )
        public;

    function addCertifiedFile(
        address certifiedFileAddress,
        string memory id
    )
        public;

    function getSignatureById(
        string memory id
    )
        public
        view
        returns (address);

    function getSignature(
        uint index
    )
        public
        view
        returns (address adr, bool more);

    function getDocument(
        uint index
    )
        public
        view
        returns (address adr, bool more);

    function getSignatureFile(
        uint index
    )
        public
        view
        returns (address adr, bool more);

    function getSignatureEvent(
        uint index
    )
        public
        view
        returns (address adr, bool more);

    function getCertifiedEmailById(
        string memory id
    )
        public
        view
        returns (address);

    function getCertifiedEmail(
        uint index
    )
        public
        view
        returns (address adr, bool more);

    function getCertificate(
        uint index
    )
        public
        view
        returns (address adr, bool more);

    function getCertifiedEmailFile(
        uint index
    )
        public
        view
        returns (address adr, bool more);

    function getCertifiedEmailEvent(
        uint index
    )
        public
        view
        returns (address adr, bool more);

    function getSignaturesCount()
        public
        view
        returns (uint256 count);

    function getDocumentsCount()
        public
        view
        returns (uint256 count);

    function getSignatureFilesCount()
        public
        view
        returns (uint256 count);

    function getSignatureEventsCount()
        public
        view
        returns (uint256 count);

    function getCertifiedEmailsCount()
        public
        view
        returns (uint256 count);

    function getCertificatesCount()
        public
        view
        returns(uint256 count);

    function getCertifiedEmailFilesCount()
        public
        view
        returns(uint256 count);

    function getCertifiedEmailEventsCount()
        public
        view
        returns(uint256 count);

    function getCertifiedFilesCount()
        public
        view
        returns(uint256 count);

    function getCertifiedFile(
        uint index
    )
        public
        view
        returns(address adr, bool more);

    function getCertifiedFileById(
        string memory id
    )
        public
        view
        returns(address);

    function notifyPaymentCheck(
        address paymentContract,
        string memory referenceId,
        string memory receiverId,
        string memory statementId,
        uint status,
        uint receivedAt,
        uint checkedAt
    )
        public;
}
