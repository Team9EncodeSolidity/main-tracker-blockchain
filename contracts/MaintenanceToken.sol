// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts@v4.9.5/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@v4.9.5/access/Ownable.sol";

contract MaintenanceToken is ERC20, Ownable { // OWNABLE
    constructor() ERC20("MaintenanceToken", "MTT") Ownable() {} // OWNABLE

    function mint(address account, uint256 amount) external onlyOwner { // OWNABLE
        _mint(account, amount);
    }
}
