// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Importing OpenZeppelin contracts
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// Special versioned imports ( usefull when testing using Remix )
// import "@openzeppelin/contracts@v4.9.5/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts@v4.9.5/access/Ownable.sol";
// import "@openzeppelin/contracts@v4.9.5/utils/Counters.sol";
// import "@openzeppelin/contracts@v4.9.5/utils/Base64.sol";

// Importing Chainlink contracts
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./MaintenanceToken.sol";

contract MaintenanceTracker is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter public tokenIdCounter;

    // Create price feed
    // AggregatorV3Interface internal priceFeed;
    // uint256 public lastPrice = 0;

    // string public priceIndicator;

    /// @notice Amount of tokens given per ETH paid
    uint256 public purchaseRatio;

    enum TaskStatus { InProgress, CompletedUnpaid, CompletedPaid }
    enum ExecutionStatus { None, CompletedByRepairman, CertifiedByQualityInspector }

    struct MaintenanceTask {
        string clientName;
        string systemName;
        string maintenanceName;
        string systemCycles;
        // string ipfsHash;
        string estimatedTime;
        string startTime;
        uint256 cost;
        TaskStatus generalStatus;
        ExecutionStatus executionStatus;
        address repairman;
        address qualityInspector;
    }

    mapping(uint256 => MaintenanceTask) public maintenanceTasks;
    // mapping(uint256 => address) public onProgressTasks;

    MaintenanceToken public tokenContract;

    event MaintenanceTaskOpened(uint256 newTokenId);
    event TaskCertified(uint256 tokenId, address certifier);
    event TaskCompletedPaid(uint256 tokenId, uint256 cost);
    event FundsWithdrawn(uint256 amount);

    // struct ChainStruct {
    //     uint64 code;
    //     string name;
    //     string color;
    // }
    // mapping (uint256 => ChainStruct) chain;


    //https://docs.chain.link/ccip/supported-networks/testnet
    constructor(address _tokenContractAddress, uint256 _purchaseRatio) ERC721("MaintenanceTracker", "MT") Ownable() {
        tokenContract = MaintenanceToken(_tokenContractAddress);
        purchaseRatio = _purchaseRatio;

        //https://docs.chain.link/data-feeds/price-feeds/addresses
        // priceFeed = AggregatorV3Interface(
        //     // Sepolia BTC/USD
        //     0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
        // );
    }

    modifier onlyRepairman(uint256 tokenId) {
        require(msg.sender == maintenanceTasks[tokenId].repairman, "Not the repairman");
        _;
    }

    modifier onlyQualityInspector(uint256 tokenId) {
        require(msg.sender == maintenanceTasks[tokenId].qualityInspector, "Not the quality inspector");
        _;
    }

    modifier taskInProgress(uint256 tokenId) {
        require(maintenanceTasks[tokenId].generalStatus == TaskStatus.InProgress, "Task not in progress");
        _;
    }

    modifier taskCompletedUnpaid(uint256 tokenId) {
        require(maintenanceTasks[tokenId].generalStatus == TaskStatus.CompletedUnpaid, "Task not completed or already paid");
        _;
    }

    function openMaintenanceTask(
        string memory _clientName,
        string memory _systemName,
        string memory _maintenanceName,
        string memory _systemCycles,
        // string memory _ipfsHash,
        string memory _estimatedTime,
        string memory _startTime,
        uint256 _cost,
        address _repairman,
        address _qualityInspector
    ) external returns (uint256)
    {
        uint256 newTokenId = tokenIdCounter.current();
        tokenIdCounter.increment();

        maintenanceTasks[newTokenId] = MaintenanceTask({
            clientName: _clientName,
            systemName: _systemName,
            maintenanceName: _maintenanceName,
            systemCycles: _systemCycles,
            // ipfsHash: _ipfsHash,
            estimatedTime: _estimatedTime,
            startTime: _startTime,
            cost: _cost,
            generalStatus: TaskStatus.InProgress,
            executionStatus: ExecutionStatus.None,
            repairman: _repairman,
            qualityInspector: _qualityInspector
        });

        emit MaintenanceTaskOpened(newTokenId);
        return (newTokenId);

    }

    function completeTask(uint256 tokenId)
        external onlyRepairman(tokenId) taskInProgress(tokenId)
    {
        emit TaskCertified(tokenId, msg.sender);
        maintenanceTasks[tokenId].executionStatus = ExecutionStatus.CompletedByRepairman;
        // The general status remains "InProgress" until payment is made
    }

    function certifyTask(uint256 tokenId)
        external onlyQualityInspector(tokenId) taskInProgress(tokenId)
    {
        emit TaskCertified(tokenId, msg.sender);
        maintenanceTasks[tokenId].executionStatus = ExecutionStatus.CertifiedByQualityInspector;
        maintenanceTasks[tokenId].generalStatus = TaskStatus.CompletedUnpaid;
    }

    function payForTask(
        uint256 tokenId,
        uint256 _amount,
        string memory _ipfsHash,
        string memory _nftImageIpfsHash
    ) external taskCompletedUnpaid(tokenId) {
        // Anyone can pay for the task

        require(bytes(_ipfsHash).length > 0, "Metadata IPFS hash needed");

        require(bytes(_nftImageIpfsHash).length > 0, "NFT Image IPFS hash needed");

        uint256 taskCost = maintenanceTasks[tokenId].cost;

        // Ensure that the caller pays at least the specified cost
        require(_amount >= taskCost, "Insufficient payment");

        // Make sure that the user has approved the contract to spend the required amount of tokens
        require(tokenContract.allowance(msg.sender, address(this)) >= taskCost, "Token approval required");

        // Update task status to "Completed Paid"
        maintenanceTasks[tokenId].generalStatus = TaskStatus.CompletedPaid;

        // Mint an NFT certificate for the completed task and transfer it to the payer
        mint(msg.sender, tokenId, _ipfsHash, _nftImageIpfsHash);

        // Transfer the specified cost to the owner
        // Before this, the transfer amount needs to be aproved from the backend TokenContract.approve(address spender, uint256 amount)
        tokenContract.transferFrom(msg.sender, address(this), taskCost);

        emit TaskCompletedPaid(tokenId, taskCost);
    }


    function mint(address to, uint256 tokenId, string memory _ipfsHash, string memory _nftImageIpfsHash) public onlyOwner {
        mintFrom(to, tokenId, _ipfsHash, _nftImageIpfsHash);
    }

    function mintFrom(address to, uint256 tokenId, string memory _ipfsHash, string memory _nftImageIpfsHash) internal {
        // sourceId 0 Sepolia, 1 Fuji, 2 Mumbai
        // uint256 tokenId = tokenIdCounter.current();
        _safeMint(to, tokenId);
        updateMetaData(tokenId, _ipfsHash, _nftImageIpfsHash);
    }

    // Util Conversoin Function
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = uint8(hi) < 10 ? bytes1(uint8(hi) + 0x30) : bytes1(uint8(hi) + 0x57);
            s[2*i+1] = uint8(lo) < 10 ? bytes1(uint8(lo) + 0x30) : bytes1(uint8(lo) + 0x57);
            // s[2*i] = char(hi);
            // s[2*i+1] = char(lo);
        }
        return string(s);
    }

    // function char(bytes1 b) internal pure returns (bytes1 c) { return (uint8(b) < 10) ? bytes1(uint8(b) + 0x30) : bytes1(uint8(b) + 0x57); }

    // Update MetaData
    function updateMetaData(uint256 tokenId, string memory _ipfsHash, string memory _nftImageIpfsHash) internal {
        MaintenanceTask memory taskData = maintenanceTasks[tokenId];

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
                            '"value": "', taskData.clientName ,'"},',
                            '{"trait_type": "systemName",',
                            '"value": "', taskData.systemName ,'"},',
                            '{"trait_type": "maintenanceName",',
                            '"value": "', taskData.maintenanceName ,'"},',
                            '{"trait_type": "systemCycles",',
                            '"value": "', taskData.systemCycles ,'"},',
                            '{"trait_type": "estimatedTime",',
                            '"value": "', taskData.estimatedTime ,'"},',
                            '{"trait_type": "startTime",',
                            '"value": "', taskData.startTime ,'"},',
                            '{"trait_type": "repairman",',
                            '"value": "0x', toAsciiString(taskData.repairman) ,'"},',
                            '{"trait_type": "qualityInspector",',
                            '"value": "0x', toAsciiString(taskData.qualityInspector) ,'"}'
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
    // function comparePrice() public returns (string memory) {
    //     uint256 currentPrice = getChainlinkDataFeedLatestAnswer();
        // if (currentPrice > lastPrice) {
        //     priceIndicator = priceIndicatorUp;
        // } else if (currentPrice < lastPrice) {
        //     priceIndicator = priceIndicatorDown;
        // } else {
        //     priceIndicator = priceIndicatorFlat;
        // }
    //     lastPrice = currentPrice;
    //     return priceIndicator;
    // }


    // function getChainlinkDataFeedLatestAnswer() public view returns (uint256) {
    //     (, int256 price, , , ) = priceFeed.latestRoundData();
    //     return uint256(price);
    // }


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

    /// @notice Gives tokens based on the amount of ETH sent
    /// @dev This implementation is prone to rounding problems
    function buyTokens() external payable {
        tokenContract.mint(msg.sender, msg.value * purchaseRatio);
    }

    ///// @notice This serves as the first step in doing withdraw
    ///// @dev This calls the approve meaning the sender can later withdraw
    // function approveTreasuryTknWithdraw() external onlyOwner {
    //     tokenContract.approve(msg.sender, treasuryBalance());
    // }

    /// @notice This serves as a way to withdraw all the accumulated Eth
    /// @dev This could better, as in made to allow the caller to be a contract
    function withdrawTreasuryEthAndBurn() public onlyOwner {
        address payable to = payable(msg.sender);
        // tokenContract.approve(address(this), treasuryBalance());
        tokenContract.burn(address(this), treasuryBalance());
        to.transfer(address(this).balance);
    }

    /// @notice Shows the amount of tokens inside the main treasury
    /// @dev This can also be viewed directly using the ERC20 balanceOf
    function treasuryBalance() public view returns(uint256) {
        return tokenContract.balanceOf(address(this));
    }
}
