// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./MaintenanceToken.sol";

contract MaintenanceTracker is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;

    /// @notice Amount of tokens given per ETH paid
    uint256 public purchaseRatio;

    enum TaskStatus { InProgress, CompletedUnpaid, CompletedPaid }
    enum ExecutionStatus { None, CompletedByRepairman, CertifiedByQualityInspector }

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

    event TaskCertified(uint256 tokenId, address certifier);
    event TaskCompletedPaid(uint256 tokenId, uint256 cost);
    event FundsWithdrawn(uint256 amount);

    constructor(address _tokenContractAddress, uint256 _purchaseRatio) ERC721("MaintenanceTracker", "MT") Ownable() {
        tokenContract = MaintenanceToken(_tokenContractAddress);
        purchaseRatio = _purchaseRatio;
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

    function payForTask(uint256 tokenId, uint256 _amount, string memory _metadataIpfsHash, string memory _nftImageIpfsHash) external taskCompletedUnpaid(tokenId) {
        // Anyone can pay for the task
        
        require(bytes(_metadataIpfsHash).length > 0, "Metadata IPFS hash needed");  

        require(bytes(_nftImageIpfsHash).length > 0, "NFT Image IPFS hash needed");
        
        uint256 taskCost = maintenanceTasks[tokenId].cost;

        // Ensure that the caller pays at least the specified cost
        require(_amount >= taskCost, "Insufficient payment");

        // Make sure that the user has approved the contract to spend the required amount of tokens
        require(tokenContract.allowance(msg.sender, address(this)) >= taskCost, "Token approval required");

        // Update task status to "Completed Paid"
        maintenanceTasks[tokenId].generalStatus = TaskStatus.CompletedPaid;

        // Mint an NFT certificate for the completed task and transfer it to the payer
        _safeMint(msg.sender, tokenIdCounter.current());
        tokenIdCounter.increment();

        // Transfer the specified cost to the owner
        // Before this, the transfer amount needs to be aproved from the backend TokenContract.approve(address spender, uint256 amount)
        tokenContract.transferFrom(msg.sender, address(this), taskCost);

        emit TaskCompletedPaid(tokenId, taskCost);
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
    function viewCertificate(uint256 tokenId) external view returns (string memory) {
        return tokenURI(tokenId);
    }

    /// @notice Gives tokens based on the amount of ETH sent
    /// @dev This implementation is prone to rounding problems
    function buyTokens() external payable {
        tokenContract.mint(msg.sender, msg.value * purchaseRatio);
    }
    
}
