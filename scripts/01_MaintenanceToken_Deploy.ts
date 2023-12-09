import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import { 
          MaintenanceToken__factory, 
          MaintenanceToken, 
        } from "../typechain-types";
import { getProvider, getWallet } from "./Helpers";
dotenv.config();

let contract: MaintenanceToken;

async function main() {
    console.log(`START\n`);

    //receiving parameters
    const parameters = process.argv.slice(2);
    if (!parameters || parameters.length < 0)
      throw new Error("Proposals not provided");
    // const myTokenContractAddress = parameters[0];

    // const proposals = process.argv.slice(3);
    // console.log("Deploying Ballot contract");
    // console.log(`MyToken contract address: ${myTokenContractAddress}`);
    // console.log("Proposals: ");
    // proposals.forEach((element, index) => {
    //   console.log(`Proposal N. ${index + 1}: ${element}`);
    // });

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
    const contractFactory = new MaintenanceToken__factory(wallet);
    contract = await contractFactory.deploy();
    await contract.waitForDeployment();
    const tokenAddress = contract.target;

    console.log(`Token deployed to ${tokenAddress}\n`);
    console.log('END');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});