pragma solidity <0.6.0;

/*
Gas to deploy: 2.779.989
*/

import "./interfaces/UserInterface.sol";


contract User is UserInterface {
    string public certificatePublicKey;

    address public signaturitAddress;
    address public userAddress;

    address[] public signatures;
    address[] public documents;
    address[] public signatureFiles;
    address[] public certifiedEmailFiles;
    address[] public signatureEvents;
    address[] public certifiedEmailEvents;
    address[] public certifiedEmails;
    address[] public certificates;
    address[] public certifiedFiles;

    mapping(string => address) private signaturesIndexes;
    mapping(string => address) private certifiedEmailsIndexes;
    mapping(string => address) private certifiedFilesIndexes;

    event SignatureAdded(address adr);
    event DocumentAdded(address adr);
    event FileAdded(address adr, string source);
    event EventAdded(address adr, string source);
    event CertifiedEmailAdded(address adr);
    event CertificatePublickeySet(string key);
    event CertificateAdded(address adr);
    event CertifiedFileAdded(address adr);
    event ClauseNotification(
        address clauseContract,
        string clauseType,
        string notificationType,
        string id
    );

    constructor (address _userAddress) public {
        signaturitAddress = msg.sender;
        userAddress = _userAddress;
    }

    modifier signaturitOnly() {
        require(
            tx.origin == signaturitAddress,
            "Only Signaturit account can perform this action"
        );

        _;
    }

    modifier onlyAllowed() {
        require(
            tx.origin == userAddress || tx.origin == signaturitAddress,
            "Only an allowed account can perform this action"
        );

        _;
    }

    function setCertificatePublicKey(
        string memory key
    )
        public
        signaturitOnly
    {
        certificatePublicKey = key;
        emit CertificatePublickeySet(certificatePublicKey);
    }

    function addSignature(
        address signatureAddress,
        string memory id
    )
        public
        signaturitOnly
    {
        signaturesIndexes[id] = signatureAddress;
        signatures.push(signatureAddress);

        emit SignatureAdded(signatureAddress);
    }

    function addDocument(
        address documentAddress
    )
        public
        signaturitOnly
    {
        documents.push(documentAddress);

        emit DocumentAdded(documentAddress);
    }

    function addFile(
        string memory fileType,
        address fileAddress
    )
        public
        signaturitOnly
    {
        if (
            keccak256(
                abi.encodePacked((fileType))
            ) == keccak256(
                abi.encodePacked(("signature"))
            )
        ) {
            signatureFiles.push(fileAddress);
        } else if (
            keccak256(
                abi.encodePacked((fileType))
            ) == keccak256(
                abi.encodePacked(("certified_email"))
            )
        ) {
            certifiedEmailFiles.push(fileAddress);
        }

        emit FileAdded(fileAddress, fileType);
    }

    function addEvent(
        string memory eventSource,
        address eventAddress
    )
        public
        signaturitOnly
    {
        if (
            keccak256(
                abi.encodePacked((eventSource))
            ) == keccak256(
                abi.encodePacked(("signature"))
            )
        ) {
            signatureEvents.push(eventAddress);
        } else if (
            keccak256(
                abi.encodePacked((eventSource))
            ) == keccak256(
                abi.encodePacked(("certified_email"))
            )
        ) {
            certifiedEmailEvents.push(eventAddress);
        }

        emit EventAdded(eventAddress, eventSource);
    }

    function addCertifiedEmail(
        address certifiedEmailAddress,
        string memory id
    )
        public
        signaturitOnly
    {
        certifiedEmailsIndexes[id] = certifiedEmailAddress;
        certifiedEmails.push(certifiedEmailAddress);

        emit CertifiedEmailAdded(certifiedEmailAddress);
    }

    function addCertificate(
        address certificate
    )
        public
        signaturitOnly
    {
        certificates.push(certificate);

        emit CertificateAdded(certificate);
    }

    function addCertifiedFile(
        address certifiedFileAddress,
        string memory id
    )
        public
        signaturitOnly
    {
        certifiedFilesIndexes[id] = certifiedFileAddress;
        certifiedFiles.push(certifiedFileAddress);

        emit CertifiedFileAdded(certifiedFileAddress);
    }

    function clauseNotification(
        address clauseContract,
        string memory clauseType,
        string memory notificationType,
        string memory id
    )
        public
        onlyAllowed
    {
        emit ClauseNotification(
            clauseContract,
            clauseType,
            notificationType,
            id
        );
    }

    function getSignatureById(
        string memory id
    )
        public
        view
        returns (address)
    {
        require(
            signaturesIndexes[id] != address(0),
            "This id doesnt correspond to any saved signature"
        );

        return signaturesIndexes[id];
    }

    function getSignature(
        uint index
    )
        public
        view
        returns (address adr, bool more)
    {
        _checkValidity(signatures.length, index);

        return (
            signatures[index],
            _moreIsFound(signatures.length, index)
        );
    }

    function getDocument(
        uint index
    )
        public
        view
        returns (address adr, bool more)
    {
        _checkValidity(documents.length, index);

        return (
            documents[index],
            _moreIsFound(documents.length, index)
        );
    }

    function getSignatureFile(
        uint index
    )
        public
        view
        returns (address adr, bool more)
    {
        _checkValidity(signatureFiles.length, index);

        return (
            signatureFiles[index],
            _moreIsFound(signatureFiles.length, index)
        );
    }

    function getSignatureEvent(
        uint index
    )
        public
        view
        returns (address adr, bool more)
    {
        _checkValidity(signatureEvents.length, index);

        return (
            signatureEvents[index],
            _moreIsFound(signatureEvents.length, index)
        );
    }

    function getCertifiedEmailById(
        string memory id
    )
        public
        view
        returns (address)
    {
        require(
            certifiedEmailsIndexes[id] != address(0),
            "This id doesnt correspond to any saved certified email"
        );

        return certifiedEmailsIndexes[id];
    }

    function getCertifiedEmail(
        uint index
    )
        public
        view
        returns (address adr, bool more)
    {
        _checkValidity(certifiedEmails.length, index);

        return(
            certifiedEmails[index],
            _moreIsFound(certifiedEmails.length, index)
        );
    }

    function getCertificate(
        uint index
    )
        public
        view
        returns (address adr, bool more)
    {
        _checkValidity(certificates.length, index);

        return(
            certificates[index],
            _moreIsFound(certificates.length, index)
        );
    }

    function getCertifiedEmailFile(
        uint index
    )
        public
        view
        returns (address adr, bool more)
    {
        _checkValidity(certifiedEmailFiles.length, index);

        return (
            certifiedEmailFiles[index],
            _moreIsFound(certifiedEmailFiles.length, index)
        );
    }

    function getCertifiedEmailEvent(
        uint index
    )
        public
        view
        returns (address adr, bool more)
    {
        _checkValidity(certifiedEmailEvents.length, index);

        return (
            certifiedEmailEvents[index],
            _moreIsFound(certifiedEmailEvents.length, index)
        );
    }

    function getCertifiedFileById(
        string memory id
    )
        public
        view
        returns (address)
    {
        require(
            certifiedFilesIndexes[id] != address(0),
            "This id doesnt correspond to any saved signature"
        );

        return certifiedFilesIndexes[id];
    }

    function getCertifiedFile(
        uint index
    )
        public
        view
        returns (address adr, bool more)
    {
        _checkValidity(certifiedFiles.length, index);

        return (
            certifiedFiles[index],
            _moreIsFound(certifiedFiles.length, index)
        );
    }

    function getSignaturesCount()
        public
        view
        returns (uint256 count)
    {
        return signatures.length;
    }

    function getDocumentsCount()
        public
        view
        returns (uint256 count)
    {
        return documents.length;
    }

    function getSignatureFilesCount()
        public
        view
        returns (uint256 count)
    {
        return signatureFiles.length;
    }

    function getSignatureEventsCount()
        public
        view
        returns (uint256 count)
    {
        return signatureEvents.length;
    }

    function getCertifiedEmailsCount()
        public
        view
        returns (uint256 count)
    {
        return certifiedEmails.length;
    }

    function getCertificatesCount()
        public
        view
        returns (uint256 count)
    {
        return certificates.length;
    }

    function getCertifiedEmailFilesCount()
        public
        view
        returns (uint256 count)
    {
        return certifiedEmailFiles.length;
    }

    function getCertifiedEmailEventsCount()
        public
        view
        returns (uint256 count)
    {
        return certifiedEmailEvents.length;
    }

    function getCertifiedFilesCount()
        public
        view
        returns (uint256 count)
    {
        return certifiedFiles.length;
    }

    function _checkValidity(
        uint length,
        uint index
    )
        internal
        pure
    {
        require(
            index < length,
            "This element doesn't exist"
        );
    }

    function _moreIsFound(
        uint length,
        uint index
    )
        internal
        pure
        returns (bool)
    {
        return length > index + 1 ? true : false;
    }
}
