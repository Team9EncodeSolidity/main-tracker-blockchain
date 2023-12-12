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

  const contractFactory = new MaintenanceTracker__factory(wallet);
  contract = contractFactory.attach(TrackerContractAddress) as MaintenanceTracker;

  const idCounter = await contract.tokenIdCounter();
  console.log(`The current tokenIdCounter is ${idCounter.toString()}`);

  for (let i=0; i < Number(idCounter); i++) {
    const id = i;
    const task = await contract.maintenanceTasks(id);
    const {
      clientName,
      systemName,
      maintenanceName,
      systemCycles,
      estimatedTime,
      startTime,
      cost,
      generalStatus,
      executionStatus,
      repairman,
      qualityInspector,
    } = task;
    console.log(`Task #${i}: \n
      cName ${clientName} | sysName ${systemName} | mainName ${maintenanceName}
      sysCycles ${systemCycles.toString} | esTime ${estimatedTime} | startTime ${startTime}
      cost ${ethers.parseUnits(cost.toString())}
      generalStatus ${generalStatus.toString()} (0-InProgress 1-CompletedUnpaid, 2-CompletedPaid)
      executionStatus ${executionStatus.toString()} (0-None 1-CompletedByRepairman 2-CertifiedByQualityInspector)
      repairman ${repairman}
      qualityInspector ${qualityInspector}
    `)
  }

  console.log('END');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});