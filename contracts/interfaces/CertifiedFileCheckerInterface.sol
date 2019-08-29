pragma solidity <0.6.0;

contract CertifiedFileCheckerInterface {
    function addFile(
        address certifiedFileAddree
    ) public;

    function getFile(
        string memory fileHash,
        uint index
    )  public view returns(
        string memory id,
        string memory name,
        string memory hash,
        uint size,
        uint createdAt,
        address  owner,
        bool more
    );
}