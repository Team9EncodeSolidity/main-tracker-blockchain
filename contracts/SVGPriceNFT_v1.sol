// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;


// Importing OpenZeppelin contracts
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";


// Importing Chainlink contracts
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract SVGPriceNFT_v1 is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter public tokenIdCounter;

    // Create price feed
    AggregatorV3Interface internal priceFeed;
    uint256 public lastPrice = 0;

    string public priceIndicator;

    struct ChainStruct {
        uint64 code;
        string name;
        string color;
    }
    mapping (uint256 => ChainStruct) chain;


    //https://docs.chain.link/ccip/supported-networks/testnet
    constructor() ERC721("MaintenanceTracker", "MT") Ownable() {
        //https://docs.chain.link/data-feeds/price-feeds/addresses        
        priceFeed = AggregatorV3Interface(
            // Sepolia BTC/USD
            0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43  
        );
    }


    function mint(address to, string memory _ipfsHash, string memory _nftImageIpfsHash) public {
        mintFrom(to, _ipfsHash, _nftImageIpfsHash);
    }


    function mintFrom(address to, string memory _ipfsHash, string memory _nftImageIpfsHash) public {
        // sourceId 0 Sepolia, 1 Fuji, 2 Mumbai
        uint256 tokenId = tokenIdCounter.current();
        _safeMint(to, tokenId);
        updateMetaData(tokenId, _ipfsHash, _nftImageIpfsHash);    
        tokenIdCounter.increment();
    }


    // Update MetaData
    function updateMetaData(uint256 tokenId, string memory _ipfsHash, string memory _nftImageIpfsHash) public {
        // Base64 encode the SVG
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Maintenance Certificate",',
                        '"description": "This digital certificate serves as authentic evidence that the specified maintenance operations were performed under specific conditions",',
                        '"external_url": "', _ipfsHash, '",',
                        '"image": "', _nftImageIpfsHash, '",',
                        '"attributes": [',
                            '{"trait_type": "clientName",',
                            '"value": "Javier"},',
                            '{"trait_type": "systemName",',
                            '"value": "AIRCRAFT"}',
                        ']}'
                    )
                )
            )
        );
        // Create token URI
        string memory finalTokenURI = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        // Set token URI
        _setTokenURI(tokenId, finalTokenURI);
    }

    // Compare new price to previous price
    function comparePrice() public returns (string memory) {
        uint256 currentPrice = getChainlinkDataFeedLatestAnswer();
        // if (currentPrice > lastPrice) {
        //     priceIndicator = priceIndicatorUp;
        // } else if (currentPrice < lastPrice) {
        //     priceIndicator = priceIndicatorDown;
        // } else {
        //     priceIndicator = priceIndicatorFlat;
        // }
        lastPrice = currentPrice;
        return priceIndicator;
    }


    function getChainlinkDataFeedLatestAnswer() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }


    // The following function is an override required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721URIStorage)
    {
        super._burn(tokenId);
    }


    function tokenURI(uint256 tokenId)
        public view override(ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}