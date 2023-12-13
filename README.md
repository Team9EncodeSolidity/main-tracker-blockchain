# Sample Hardhat Project

---

# Steps Required For The Demo

## Initialise

~~Call `/deploy-token-contract`~~ assume this is already deployed

<img width="1441" alt="image" src="https://github.com/Team9EncodeSolidity/main-tracker-backend/assets/11134288/aa24d122-7b5a-44e9-93a6-c9acec4323fb">

~~Call `/deploy-tracker-contract` and pass the recently created ct address and a ration ( use default ration )~~ assume this is already deployed

<img width="1441" alt="image" src="https://github.com/Team9EncodeSolidity/main-tracker-backend/assets/11134288/22a6ce06-98e0-4acc-9377-afa93871359e">

~~Call `/grant-mint-role` and pass the tracker contract address~~ assume this is already done

<img width="1441" alt="image" src="https://github.com/Team9EncodeSolidity/main-tracker-backend/assets/11134288/8cbd95f9-18a6-418f-a0f6-e778119a918d">

```sh
npx ts-node ./scripts/01_MaintenanceToken_Deploy.ts
npx ts-node ./scripts/02_MaintenanceTracker_Deploy.ts
```

---

## The Opening Of The Task

In the gui http://localhost:3000/main-tracker-frontend

Fill in the form and hit Submit

<img width="1229" alt="image" src="https://github.com/Team9EncodeSolidity/main-tracker-backend/assets/11134288/3da6387e-1ade-4711-bb1a-de23abd22b06">

Show the fact that the list of tasks have been updated and there is now one task.

<img width="1317" alt="image" src="https://github.com/Team9EncodeSolidity/main-tracker-backend/assets/11134288/2990dd15-9dbb-48b8-9063-1e0627174f1d">

Optional, you can put an extra task.

# Completing the task and minting the NFT

In the backend and use `/complete-task` id "0"

<img width="1438" alt="image" src="https://github.com/Team9EncodeSolidity/main-tracker-backend/assets/11134288/9cc75c63-7332-45be-bc9a-a3069528ce56">

Show the fact that the execution status has been chaned

<img width="1323" alt="image" src="https://github.com/Team9EncodeSolidity/main-tracker-backend/assets/11134288/52c190af-9d86-4a49-8b4e-84623baa0b6d">

Similarly, use /certify-task with the same id , id "0"

<img width="1438" alt="image" src="https://github.com/Team9EncodeSolidity/main-tracker-backend/assets/11134288/7bd74035-7dc7-414b-95b7-c06a3e9df950">

Show the fact that both the execution and the general status has been changed

<img width="1323" alt="image" src="https://github.com/Team9EncodeSolidity/main-tracker-backend/assets/11134288/490e45dd-b4c7-4d28-bc8d-aa41c83a2be2">

# Showing The Final Step

In the backend call the `/buy-tokens`

<img width="1428" alt="image" src="https://github.com/Team9EncodeSolidity/main-tracker-backend/assets/11134288/945e780b-f8a8-4152-a4cb-088de0d85b0c">

Then show the token inside the MetaMask wallet

<img width="1060" alt="image" src="https://github.com/Team9EncodeSolidity/main-tracker-backend/assets/11134288/de2becd0-4880-4af5-b847-851d210e45b2">

Back in the backend call the `/approve` endpoint to approve the spending the tokens

<img width="1437" alt="image" src="https://github.com/Team9EncodeSolidity/main-tracker-backend/assets/11134288/42e691d7-4aeb-4f82-b58f-f8c976c8c0ea">

In the backend call the `/pay-for-task` endpoint

<img width="1437" alt="image" src="https://github.com/Team9EncodeSolidity/main-tracker-backend/assets/11134288/7d5e3e29-8841-4265-9dd5-61872a2a9124">

Finally show the list of NFTs both encoded and decoded, as in `/nfts-list` and `/nfts-list-decoded`

<img width="1426" alt="image" src="https://github.com/Team9EncodeSolidity/main-tracker-backend/assets/11134288/88a58edd-e15d-4087-ab37-2f7f0a6d3dbc">

**THE END**

---

---

The purpose of this project is to be use for prototyping smart contracts. The final contract should be placed here as well as deployment and testing scripts.

**Note**: If you are testing this in **Remix** make sure you switch on the **optimized** with **200** runs and also make sure you use the versioned imports instead of the normal imports ( see Solidity comments ).

Example ( old ):

**[https://testnets.opensea.io/es/assets/sepolia/0x6bd7e668bd89f6ea52e8be0d6e2a48b18185f66c/0](https://testnets.opensea.io/es/assets/sepolia/0x6bd7e668bd89f6ea52e8be0d6e2a48b18185f66c/0)**

**Note**: Make sure you clean hardhat with **`npm hardhat clean`** and make sure you start with a clean hardhat node that starts at **Block 0**.

Prerequisites:

```shell
npm install
```

Try running some of the following:

In the first bash terminal:

```shell
npx hardhat node
```

In the second terminal:

```shell
# CreateYourDevDotEnvFile
cp .env.example.development .env
# Compile
npx hardhat compile
# StartThenContractSaveAddress
npx ts-node ./scripts/01_MaintenanceToken_Deploy.ts && TOKEN_CT_ADDR=0x5FbDB2315678afecb367f032d93F642f64180aa3
npx ts-node ./scripts/02_MaintenanceTracker_Deploy.ts $TOKEN_CT_ADDR && MAIN_CT_ADDR=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
npx ts-node ./scripts/03_OpenMaintenanceTask.ts $MAIN_CT_ADDR John Jet EngineMaintenance && ID=0
npx ts-node ./scripts/04_CompleteTask.ts $MAIN_CT_ADDR $ID
npx ts-node ./scripts/05_CertifyTask.ts $MAIN_CT_ADDR $ID
npx ts-node ./scripts/06_BuyTokens.ts $MAIN_CT_ADDR 1
npx ts-node ./scripts/07_TokenApproval.ts $TOKEN_CT_ADDR $MAIN_CT_ADDR 1
npx ts-node ./scripts/08_PayForTask.ts $MAIN_CT_ADDR $ID
npx ts-node ./scripts/09_WithdrawTreasury.ts $MAIN_CT_ADDR
```

```shell
# ViewAllTheTasks
npx ts-node ./scripts/90_QueryMaintenanceTasks.ts $MAIN_CT_ADDR
# ViewOneSingleNFT
npx ts-node ./scripts/91_QueryNftMetadata.ts $MAIN_CT_ADDR $ID
```

```shell
# VerifyContractWith
npx hardhat verify --network sepolia $TOKEN_CT_ADDR
npx hardhat verify --network sepolia $MAIN_CT_ADDR $TOKEN_CT_ADDR "1000000000000000000"
```

Test the query of all tasks w/ **`90_QueryMaintenanceTasks.ts`**:

```shell
npx ts-node ./scripts/90_QueryMaintenanceTasks.ts $MAIN_CT_ADDR
```

```
START

The current tokenIdCounter is 1
Task #0:

      cName John | sysName Jet | mainName EngineMaintenance
      sysCycles function toString() { [native code] } | esTime 259200 | startTime 1702315075
      cost 1000000000000000000000000000000000000
      generalStatus 2 (0-InProgress 1-CompletedUnpaid, 2-CompletedPaid)
      executionStatus 2 (0-None 1-CompletedByRepairman 2-CertifiedByQualityInspector)
      repairman 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
      qualityInspector 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

END
```

Thest the query of one single nft w/ **`91_QueryNftMetadata.ts`**:

```shell
npx ts-node ./scripts/91_QueryNftMetadata.ts $MAIN_CT_ADDR $ID
```

```
START

MaintenanceTracker contract address: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512.
Last block number: 10
Last block timestamp: 1702315115 (11/12/2023 17:18:35)
Using wallet 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Wallet balance 9999.990774430196 ETH
The uriEncoded is data:application/json;base64,eyJuYW1lIjogIk1haW50ZW5hbmNlIENlcnRpZmljYXRlIiwiZGVzY3JpcHRpb24iOiAiVGhpcyBkaWdpdGFsIGNlcnRpZmljYXRlIHNlcnZlcyBhcyBhdXRoZW50aWMgZXZpZGVuY2UgdGhhdCB0aGUgc3BlY2lmaWVkIG1haW50ZW5hbmNlIG9wZXJhdGlvbnMgd2VyZSBwZXJmb3JtZWQgdW5kZXIgc3BlY2lmaWMgY29uZGl0aW9ucyIsImV4dGVybmFsX3VybCI6ICJodHRwczovL2lwZnMuaW8vaXBmcy9RbVdoanN2Q1NoVHRvS0hWVEFUVlVaMzU5cW40cTlFSFFRWFVFclBMenB2Q2h6I2V4dGVybmFsTGluayIsImltYWdlIjogImlwZnM6Ly9iYWZ5YmVpZmozd3o0NjJ6aWxzMjZtenR5ZXB3ZnpoeGx4ZTU1N2szc3B0bTN5ZmNwbG9ydzd4bHBvaSIsImF0dHJpYnV0ZXMiOiBbeyJ0cmFpdF90eXBlIjogImNsaWVudE5hbWUiLCJ2YWx1ZSI6ICJKb2huIn0seyJ0cmFpdF90eXBlIjogInN5c3RlbU5hbWUiLCJ2YWx1ZSI6ICJKZXQifSx7InRyYWl0X3R5cGUiOiAibWFpbnRlbmFuY2VOYW1lIiwidmFsdWUiOiAiRW5naW5lTWFpbnRlbmFuY2UifV19

The decoded JSON metadata is:

{
  "...": '...',
}
END
```

---
