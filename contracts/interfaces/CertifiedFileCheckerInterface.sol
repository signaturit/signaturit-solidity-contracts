pragma solidity <0.6.0;

import "./NotifierInterface.sol";

contract CertifiedFileCheckerInterface is NotifierInterface {
    address public signaturit;

    function getFile(
        string memory fileHash,
        uint index
    )
        public
        view
        returns(
            string memory id,
            string memory hash,
            uint size,
            uint createdAt,
            address  owner,
            address contract_address,
            bool more
        );
}