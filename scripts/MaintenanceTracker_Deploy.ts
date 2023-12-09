import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import { 
          MaintenanceToken__factory, 
          MaintenanceToken, 
          MaintenanceTracker__factory, 
          MaintenanceTracker,
        } from "../typechain-types";
import { getProvider, getWallet } from "./Helpers";
dotenv.config();

let trackercontract: MaintenanceTracker;
let tokenContract: MaintenanceToken;

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
    const trackerContractFactory = new MaintenanceTracker__factory(wallet);
    trackercontract = await trackerContractFactory.deploy(TokenContractAddress);
    await trackercontract.waitForDeployment();
    const trackerContractAddress = trackercontract.target;
    console.log(`Tracker contract deployed to ${trackerContractAddress}`);

    //granting mint role to the deployed tracker contract over the token contract
    const tokenContractFactory = new MaintenanceToken__factory(wallet);
    tokenContract = await tokenContractFactory.attach(TokenContractAddress) as MaintenanceToken;
    await tokenContract.grantMint(trackerContractAddress);
    console.log(`Mint granted to ${trackerContractAddress} over ${TokenContractAddress} token successfuly\n`);
    
    console.log('END');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});