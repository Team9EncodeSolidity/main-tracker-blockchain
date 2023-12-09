import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import { 
          MaintenanceTracker__factory, 
          MaintenanceTracker 
        } from "../typechain-types";
import { getProvider, getWallet } from "./Helpers";
dotenv.config();

let contract: MaintenanceTracker;

async function main() {
    console.log(`START\n`);

    //receiving parameters
    const parameters = process.argv.slice(2);
    if (!parameters || parameters.length < 1)
      throw new Error("Proposals not provided");
    const TokenContractAddress = parameters[0];

    console.log(`MaintenanceToken contract address: ${TokenContractAddress}. `);
    
    //inspecting data from public blockchains using RPC connections (configuring the provider)
    const provider = getProvider();
    const lastBlock = await provider.getBlock("latest");
    const lastBlockNumber = lastBlock?.number;
    console.log(`Last block number: ${lastBlockNumber}`);
    const lastBlockTimestamp = lastBlock?.timestamp ?? 0;
    const lastBlockDate = new Date(lastBlockTimestamp * 1000);
    console.log(
      `Last block timestamp: ${lastBlockTimestamp} (${lastBlockDate.toLocaleDateString()} ${lastBlockDate.toLocaleTimeString()})`
    );

    //configuring the wallet 
    const wallet = getWallet(provider);
    const balanceBN = await provider.getBalance(wallet.address);
    const balance = Number(ethers.formatUnits(balanceBN));
    console.log(`Wallet balance ${balance} ETH`);
    if (balance < 0.01) {
      throw new Error("Not enough ether");
    }

    //deploying the smart contract using Typechain
    const contractFactory = new MaintenanceTracker__factory(wallet);
    contract = await contractFactory.deploy(TokenContractAddress);
    await contract.waitForDeployment();
    const tokenAddress = contract.target;

    console.log(`Tracker contract deployed to ${tokenAddress}\n`);
    console.log('END');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});