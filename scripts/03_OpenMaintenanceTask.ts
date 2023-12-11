import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import {
  MaintenanceTracker__factory,
  MaintenanceTracker,
} from "../typechain-types";
import { getProvider, getWallet } from "./Helpers";
dotenv.config();

let contract: MaintenanceTracker;

// const clientName = "Javier Montes";
// const systemName = "AIRCRAFT";
const maintenanceName = "ITP";
const systemCycles = 1000;
const ipfsHash = "ipfs://QmaVkBn2tKmjbhphU7eyztbvSQU5EXDdqRyXZtRhSGgJGo";

const estimatedTime = 3 * 24 * 60 * 60;
const startingTime = Math.floor(new Date().getTime() / 1000);

const cost = 1;
let repairman;
let qualityInspector;

async function main() {
  console.log(`START\n`);

  //receiving parameters
  const parameters = process.argv.slice(2);
  if (!parameters || parameters.length < 3)
    throw new Error("SC's Address not provided");
  const MaintenanceTokenContractAddress = parameters[0];
  const clientName = parameters[1];
  const systemName = parameters[2]; 

  console.log(
    `MaintenanceToken contract address: ${MaintenanceTokenContractAddress}. `
  );
  console.log(
    `Client name: ${clientName}. `
  );
  console.log(
    `System name: ${systemName}. `
  );

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

  //attaching the smart contract using Typechain
  const contractFactory = new MaintenanceTracker__factory(wallet);
  contract = contractFactory.attach(
    MaintenanceTokenContractAddress
  ) as MaintenanceTracker;

  // Getting the generated TokenId
  contract.on(contract.getEvent("MaintenanceTaskOpened"), (newTokenId) => {
    console.log(`Generated TokenId: ${newTokenId}`);
    contract.off(contract.getEvent("MaintenanceTaskOpened"));
  });

  repairman = wallet.address;
  qualityInspector  =wallet.address;
  
  const tx = await contract.openMaintenanceTask(
    clientName,
    systemName,
    maintenanceName,
    systemCycles,
    ipfsHash,
    estimatedTime,
    startingTime,
    cost,
    repairman,
    qualityInspector
  );
  const receipt = await tx.wait();

  console.log(`Transaction completed ${JSON.stringify(receipt?.hash)}\n`);
  console.log('END');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
