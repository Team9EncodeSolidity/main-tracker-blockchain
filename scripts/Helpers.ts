import { ethers } from "ethers";
import * as dotenv from "dotenv";
dotenv.config();

export function getProvider(){
    return new ethers.JsonRpcProvider(
        process.env.RPC_ENDPOINT_URL ?? ""
    );
}

export function getWallet(provider:ethers.JsonRpcProvider){
    //configuring the wallet
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY ?? "", provider);
    console.log(`Using wallet ${wallet.address}`);
    return wallet;
}

export function getMyTokenContractAddress(){
    return (
        process.env.MYTOKEN_CONTRACT_ADDRESS ?? ""
    );
}
