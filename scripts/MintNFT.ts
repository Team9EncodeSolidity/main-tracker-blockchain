import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import { 
          SVGPriceNFT__factory, 
          SVGPriceNFT, 
        } from "../typechain-types";
import { getProvider, getWallet } from "./Helpers";
dotenv.config();

let contract: SVGPriceNFT;

const BET_PRICE = 1;
const BET_FEE = 0.2;
const TOKEN_RATIO = 1n;

async function main() {
    console.log(`START\n`);

    //receiving parameters
    const parameters = process.argv.slice(2);
    if (!parameters || parameters.length < 1)
      throw new Error("Proposals not provided");
    
    let  NFTContractAddress = parameters[0];

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

    const contractFactory = new SVGPriceNFT__factory(wallet);
    contract = await contractFactory.attach(NFTContractAddress) as SVGPriceNFT;
    await contract.mint(wallet.address);

    console.log(`NFT minted to ${wallet.address}`);
    console.log(`You'll see it here: https://testnets.opensea.io/${wallet.address}`);
    console.log('END');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});