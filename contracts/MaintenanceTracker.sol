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
        uint256 systemCycles;
        // string ipfsHash;
        uint256 estimatedTime;
        uint256 startTime;
        uint256 cost;
        TaskStatus generalStatus;
        ExecutionStatus executionStatus;
        address repairman;
        address qualityInspector;
    }

    mapping(uint256 => MaintenanceTask) public maintenanceTasks;

    MaintenanceToken public tokenContract;

    event MaintenanceTaskOpened(uint256 newTokenId);
    event TaskCertified(uint256 tokenId, address certifier);
    event TaskCompletedPaid(uint256 tokenId, uint256 cost);
    event FundsWithdrawn(uint256 amount);

    struct ChainStruct {
        uint64 code;
        string name;
        string color;
    }
    mapping (uint256 => ChainStruct) chain;


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
        uint256 _systemCycles,
        // string memory _ipfsHash,
        uint256 _estimatedTime,
        uint256 _startTime,
        uint256 _cost,
        address _repairman,
        address _qualityInspector
    ) external onlyOwner returns (uint256)
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


    function mint(address to, uint256 tokenId, string memory _ipfsHash, string memory _nftImageIpfsHash) internal {
        mintFrom(to, tokenId, _ipfsHash, _nftImageIpfsHash);
    }

    function mintFrom(address to, uint256 tokenId, string memory _ipfsHash, string memory _nftImageIpfsHash) internal {
        // sourceId 0 Sepolia, 1 Fuji, 2 Mumbai
        // uint256 tokenId = tokenIdCounter.current();
        _safeMint(to, tokenId);
        updateMetaData(tokenId, _ipfsHash, _nftImageIpfsHash);
    }

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
                            '"value": "', taskData.systemName ,'"}',
                            '{"trait_type": "maintenanceName",',
                            '"value": "', taskData.maintenanceName ,'"}',
                            '{"trait_type": "estimatedTime",',
                            '"value": "', taskData.estimatedTime ,'"}',
                            '{"trait_type": "startTime",',
                            '"value": "', taskData.startTime ,'"}',
                            '{"trait_type": "repairman",',
                            '"value": "', taskData.repairman ,'"}',
                            '{"trait_type": "qualityInspector",',
                            '"value": "', taskData.qualityInspector ,'"}',
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

    /// @notice This serves as the first step in doing withdraw
    /// @dev This calls the approve meaning the sender can later withdraw
    function approveTresuryTknWithdraw() external onlyOwner {
        tokenContract.approve(msg.sender, tresuryBalance());
    }

    /// @notice This serves as a way to withdraw all the accumulated Eth
    /// @dev This could better, as in made to allow the caller to be a contract
    function withdrawTresuryEth() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    /// @notice Shows the amount of tokens inside the main tresury
    /// @dev This can also be viewed directly using the ERC20 balanceOf
    function tresuryBalance() public view returns(uint256) {
        return tokenContract.balanceOf(address(this));
    }
}