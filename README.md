# Sample Hardhat Project

The purpose of this project is to be use for prototyping smart contracts. The final contract should be placed here as well as deployment and testing scripts.

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

---
