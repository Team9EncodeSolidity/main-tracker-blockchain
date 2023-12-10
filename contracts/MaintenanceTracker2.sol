// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IMPORT SECTION NOT NEEDED
// import "@openzeppelin/contracts@v4.9.5/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts@v4.9.5/access/Ownable.sol";
// import "@openzeppelin/contracts@v4.9.5/utils/Counters.sol";

import "./MaintenanceToken.sol";
import "./NFTFactory.sol";

/*
nft-metadata-sample.json
*/

/*
{
  "description": "This digital certificate serves as authentic evidence that the specified maintenance operations were performed under specific conditions",
  "external_url": "https://google.com",
  "image": "https://ipfs.io/ipfs/bafybeifj3wz462zils26mztyepwfzhxlxe557k3sptm3yfcplorw7xlpoi",
  "name": "Maintenance certificate",
  "attributes": [
    { "trait_type": "ClientName", "value": "Gabriel" },
    { "trait_type": "SystemName", "value": "Jet" },
    { "trait_type": "maintenanceName", "value": "Engine xyz Replacement" },
    { "trait_type": "systemCycles (flying hours)", "value": "10000" },
    { "trait_type": "estimatedTime (days)", "value": "3" },
    { "trait_type": "startingTime (days)", "value": "1" },
    { "display_type": "cost(wei)", "value": "1" },
    { "display_type": "repair (engineer)", "value": "0xA88b158D3b99945A4b18DCf70885B3eE2a72A563" },
    { "display_type": "quality inspector (engineer)", "value": "0xE30B0e8ee4c8BA5Ff81368f0A069DC04548dFCb3" }
  ]
}
*/

contract MaintenanceTracker2 is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;

    enum TaskStatus {
        InProgress,
        CompletedUnpaid,
        CompletedPaid
    }

    enum ExecutionStatus {
        None,
        CompletedByRepairman,
        CertifiedByQualityInspector
    }

    struct MaintenanceTask {
        string clientName;
        string systemName;
        string maintenanceName;
        uint256 systemCycles;
        string ipfsHash;
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
    NFTFactory public nftFactory;

    event TaskCertified(uint256 tokenId, address certifier);
    event TaskCompletedPaid(uint256 tokenId, uint256 cost);
    event FundsWithdrawn(uint256 amount);

    // constructor(
    //     address _tokenContractAddress,
    //     address _nftFactoryAddress
    // ) ERC721("MaintenanceTracker", "MT") Ownable(msg.sender) { // DOES NOT WORK W/ V4
    //     tokenContract = MaintenanceToken(_tokenContractAddress);
    //     nftFactory = NFTFactory(_nftFactoryAddress);
    // }

    constructor(
        address _tokenContractAddress,
        address _nftFactoryAddress
    ) ERC721("MaintenanceTracker", "MT") Ownable() {
        tokenContract = MaintenanceToken(_tokenContractAddress);
        nftFactory = NFTFactory(_nftFactoryAddress);
    }

    modifier onlyRepairman(uint256 tokenId) {
        require(
            msg.sender == maintenanceTasks[tokenId].repairman,
            "Not the repairman"
        );
        _;
    }

    modifier onlyQualityInspector(uint256 tokenId) {
        require(
            msg.sender == maintenanceTasks[tokenId].qualityInspector,
            "Not the quality inspector"
        );
        _;
    }

    modifier taskInProgress(uint256 tokenId) {
        require(
            maintenanceTasks[tokenId].generalStatus == TaskStatus.InProgress,
            "Task not in progress"
        );
        _;
    }

    modifier taskCompletedUnpaid(uint256 tokenId) {
        require(
            maintenanceTasks[tokenId].generalStatus ==
                TaskStatus.CompletedUnpaid,
            "Task not completed or already paid"
        );
        _;
    }

    function openMaintenanceTask(
        string memory _clientName,
        string memory _systemName,
        string memory _maintenanceName,
        uint256 _systemCycles,
        string memory _ipfsHash,
        uint256 _estimatedTime,
        uint256 _startTime,
        uint256 _cost,
        address _repairman,
        address _qualityInspector
    ) external onlyOwner {
        uint256 newTokenId = tokenIdCounter.current();
        tokenIdCounter.increment();

        maintenanceTasks[newTokenId] = MaintenanceTask({
            clientName: _clientName,
            systemName: _systemName,
            maintenanceName: _maintenanceName,
            systemCycles: _systemCycles,
            ipfsHash: _ipfsHash,
            estimatedTime: _estimatedTime,
            startTime: _startTime,
            cost: _cost,
            generalStatus: TaskStatus.InProgress,
            executionStatus: ExecutionStatus.None,
            repairman: _repairman,
            qualityInspector: _qualityInspector
        });
    }

    function completeTask(uint256 tokenId) external onlyRepairman(tokenId) taskInProgress(tokenId) {
        emit TaskCertified(tokenId, msg.sender);
        maintenanceTasks[tokenId].executionStatus = ExecutionStatus.CompletedByRepairman;
        // The general status remains "InProgress" until payment is made
    }

    function certifyTask(uint256 tokenId) external onlyQualityInspector(tokenId) taskInProgress(tokenId) {
        emit TaskCertified(tokenId, msg.sender);
        maintenanceTasks[tokenId].executionStatus = ExecutionStatus.CertifiedByQualityInspector;
        maintenanceTasks[tokenId].generalStatus = TaskStatus.CompletedUnpaid;
    }

    function payForTask(uint256 tokenId) external payable taskCompletedUnpaid(tokenId) {
        require(msg.value >= maintenanceTasks[tokenId].cost, "Insufficient payment");

        maintenanceTasks[tokenId].generalStatus = TaskStatus.CompletedPaid;

        // Mint an NFT certificate for the completed task and transfer it to the payer
        nftFactory.createNFT(msg.sender, maintenanceTasks[tokenId].ipfsHash);

        // Transfer the excess funds back to the payer
        uint256 excessFunds = msg.value - maintenanceTasks[tokenId].cost;
        if (excessFunds > 0) {
            payable(msg.sender).transfer(excessFunds);
        }

        // Transfer the specified cost to the owner
        payable(owner()).transfer(maintenanceTasks[tokenId].cost);

        emit TaskCompletedPaid(tokenId, maintenanceTasks[tokenId].cost);
    }

    function withdrawFunds() external onlyOwner {
        uint256 totalFunds = address(this).balance;
        require(totalFunds > 0, "No funds to withdraw");

        // Transfer the funds to the owner
        payable(owner()).transfer(totalFunds);

        emit FundsWithdrawn(totalFunds);
    }

    // function _baseURI() internal view virtual override returns (string memory) { // NOT NEEDED
    //     return "https://ipfs.io/ipfs/";
    // }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        MaintenanceTask storage task = maintenanceTasks[tokenId];

        string memory baseURI = _baseURI();

        // Combine the base URI and IPFS hash
        return string(abi.encodePacked(baseURI, task.ipfsHash));
    }

    function viewCertificate(uint256 tokenId) external view returns (string memory) {
        return tokenURI(tokenId);
    }
}
