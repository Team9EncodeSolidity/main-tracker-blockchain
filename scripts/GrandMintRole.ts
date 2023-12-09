import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import { 
          MaintenanceToken__factory, 
          MaintenanceToken, 
        } from "../typechain-types";
import { getProvider, getWallet } from "./Helpers";
dotenv.config();

let contract: MaintenanceToken;

const BET_PRICE = 1;
const BET_FEE = 0.2;
const TOKEN_RATIO = 1n;

async function main() {
    console.log(`START\n`);

    //receiving parameters
    const parameters = process.argv.slice(2);
    if (!parameters || parameters.length < 2)
      throw new Error("Proposals not provided");
    const TokenContractAddress = parameters[0];
    const MintGrantedAddress = parameters[1];

    console.log(`MaintenanceToken contract address: ${TokenContractAddress}. `);
    console.log(`Address that will have mint role over the token: ${MintGrantedAddress}. `);

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

    const contractFactory = new MaintenanceToken__factory(wallet);
    contract = await contractFactory.attach(TokenContractAddress) as MaintenanceToken;
    await contract.grantMint(MintGrantedAddress);

    console.log(`Mint granted to ${MintGrantedAddress} over ${TokenContractAddress} token successfuly`);
    console.log('END');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});