import { ethers } from "hardhat";
// import * as dotenv from "dotenv";
import {
          MaintenanceTracker__factory,
          MaintenanceTracker,
        } from "../typechain-types";
import { getProvider, getWallet } from "./Helpers";
// dotenv.config();

let contract: MaintenanceTracker;

// const BET_PRICE = 1;
// const BET_FEE = 0.2;
// const TOKEN_RATIO = 1n;

async function main() {
    console.log(`START\n`);

    //receiving parameters
    const parameters = process.argv.slice(2);
    if (!parameters || parameters.length < 1)
      throw new Error("Maintenance SC's Address not provided");
    const TrackerContractAddress = parameters[0];

    console.log(`MaintenanceTracker contract address: ${TrackerContractAddress}. `);

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

    const balEthBefore = await provider.getBalance(TrackerContractAddress);
    const contractFactory = new MaintenanceTracker__factory(wallet);
    contract = contractFactory.attach(TrackerContractAddress) as MaintenanceTracker;
    const balBefore = await contract.treasuryBalance();
    console.log(`The ETH balance of MaintenanceTracker before TX is ${balEthBefore.toString()} ETH`);
    console.log(`The balance of MaintenanceTracker before TX is ${balBefore.toString()} MTT`);
    const tx = await contract.withdrawTreasuryEthAndBurn();
    await tx.wait();

    const balEthAfter = await provider.getBalance(TrackerContractAddress);
    const balAfter = await contract.treasuryBalance();
    console.log(`The ETH balance of MaintenanceTracker after TX is ${balEthAfter.toString()} ETH`);
    console.log(`The balance of MaintenanceTracker after TX is ${balAfter.toString()} MTT`);

    console.log('END');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});