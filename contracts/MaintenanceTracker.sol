// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./MaintenanceToken.sol";

contract MaintenanceTracker is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;

    enum TaskStatus { InProgress, CompletedUnpaid, CompletedPaid }

    struct MaintenanceTask {
        string clientName;
        string systemName;
        string maintenanceName;
        uint256 systemCycles;
        string ipfsHash; // Storing the IPFS hash directly
        uint256 estimatedTime;
        uint256 startTime;
        uint256 cost;
        TaskStatus status;
        address repairman;
        address qualityInspector;
    }

    mapping(uint256 => MaintenanceTask) public maintenanceTasks;

    MaintenanceToken public tokenContract;

    event TaskCertified(uint256 tokenId, address certifier);
    event TaskCompletedPaid(uint256 tokenId, uint256 cost);
    event FundsWithdrawn(uint256 amount);

    constructor(address _tokenContractAddress) ERC721("MaintenanceTracker", "MT") Ownable() {
        tokenContract = MaintenanceToken(_tokenContractAddress);
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
        require(maintenanceTasks[tokenId].status == TaskStatus.InProgress, "Task not in progress");
        _;
    }

    modifier taskCompletedUnpaid(uint256 tokenId) {
        require(maintenanceTasks[tokenId].status == TaskStatus.CompletedUnpaid, "Task not completed or already paid");
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
        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();

        maintenanceTasks[tokenId] = MaintenanceTask({
            clientName: _clientName,
            systemName: _systemName,
            maintenanceName: _maintenanceName,
            systemCycles: _systemCycles,
            ipfsHash: _ipfsHash,
            estimatedTime: _estimatedTime,
            startTime: _startTime,
            cost: _cost,
            status: TaskStatus.InProgress,
            repairman: _repairman,
            qualityInspector: _qualityInspector
        });
    }

    function certifyTask(uint256 tokenId) external onlyRepairman(tokenId) taskInProgress(tokenId) {
        emit TaskCertified(tokenId, msg.sender);
        if (msg.sender == maintenanceTasks[tokenId].repairman && msg.sender == maintenanceTasks[tokenId].qualityInspector) {
            maintenanceTasks[tokenId].status = TaskStatus.CompletedUnpaid;
        }
    }

    function completeTask(uint256 tokenId) external onlyQualityInspector(tokenId) taskInProgress(tokenId) {
        emit TaskCertified(tokenId, msg.sender);
        if (msg.sender == maintenanceTasks[tokenId].repairman && msg.sender == maintenanceTasks[tokenId].qualityInspector) {
            maintenanceTasks[tokenId].status = TaskStatus.CompletedUnpaid;
        }
    }

    function payForTask(uint256 tokenId) external taskCompletedUnpaid(tokenId) {
        require(msg.sender == ownerOf(tokenId), "Only the client can pay for the task");

        // Assume there is a transfer of tokens from the client to the contract here
        // Implement your token transfer logic based on your token contract

        // Update task status to "Completed Paid"
        maintenanceTasks[tokenId].status = TaskStatus.CompletedPaid;

        // Mint an NFT certificate for the completed task
        _safeMint(msg.sender, tokenIdCounter.current());
        tokenIdCounter.increment();

        emit TaskCompletedPaid(tokenId, maintenanceTasks[tokenId].cost);
    }

    function withdrawFunds() external onlyOwner {
        uint256 totalFunds = address(this).balance;
        require(totalFunds > 0, "No funds to withdraw");

        // Transfer the funds to the owner
        payable(owner()).transfer(totalFunds);

        emit FundsWithdrawn(totalFunds);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        MaintenanceTask storage task = maintenanceTasks[tokenId];

        string memory baseURI = _baseURI();

        // Combine the base URI and IPFS hash
        return string(abi.encodePacked(baseURI, task.ipfsHash));
    }
}