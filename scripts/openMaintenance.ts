import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import {
  MaintenanceTracker__factory,
  MaintenanceTracker,
} from "../typechain-types";
import { getProvider, getWallet } from "./Helpers";
dotenv.config();

let contract: MaintenanceTracker;

const BET_PRICE = 1;
const BET_FEE = 0.2;
const TOKEN_RATIO = 1n;

const clientName = "Gabriel";
const systemName = "Car";
const maintenanceName = "ITP";
const systemCycles = 1000;
const ipfsHash = "QmaVkBn2tKmjbhphU7eyztbvSQU5EXDdqRyXZtRhSGgJGo";
const estimatedTime = 3;
const startingTime = 3;
const cost = 1;
const repairman = "0xA88b158D3b99945A4b18DCf70885B3eE2a72A563";
const qualityInspector = "0xE30B0e8ee4c8BA5Ff81368f0A069DC04548dFCb3";

async function main() {
  console.log(`START\n`);

  //receiving parameters
  const parameters = process.argv.slice(2);
  if (!parameters || parameters.length < 1)
    throw new Error("SC's Address not provided");
  const MaintenanceTokenContractAddress = parameters[0];

  console.log(
    `MaintenanceToken contract address: ${MaintenanceTokenContractAddress}. `
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
  const ballotFactory = new MaintenanceTracker__factory(wallet);
  const ballotContract = ballotFactory.attach(
    MaintenanceTokenContractAddress
  ) as MaintenanceTracker;
  const tx = await ballotContract.openMaintenanceTask(
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
  console.log(`Transaction completed ${receipt?.hash}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
