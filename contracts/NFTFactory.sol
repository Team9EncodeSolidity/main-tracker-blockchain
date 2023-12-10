// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts@v4.9.5/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@v4.9.5/access/Ownable.sol";
import "@openzeppelin/contracts@v4.9.5/utils/Counters.sol";

contract NFTFactory is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;

    event NFTCreated(uint256 tokenId, address owner, string ipfsHash);

    constructor() ERC721("NFTFactory", "NFTF") Ownable() {}
    // constructor() ERC721("NFTFactory", "NFTF") Ownable(msg.sender) {} // DOES NOT WORK W/ VER 4

    function createNFT(address owner, string memory ipfsHash) external onlyOwner {
        uint256 newTokenId = tokenIdCounter.current();
        tokenIdCounter.increment();

        _safeMint(owner, newTokenId);
        _setTokenURI(newTokenId, ipfsHash);

        emit NFTCreated(newTokenId, owner, ipfsHash);
    }
}
