# Hardhat project for all the Solidity contracts used to implement the ERC20 Faucet on TAC Turin.

There are 3 sets of contracts:

- Vanilla ERC20 with AccessControl (testnetERC20.sol)
- a Treasury Contract (treasurySwap.sol) used in the Faucet. Drip method: users lock some wTON tokens (ERC20) and get an equivalent amount of the ERC20. They can burn the ERC20 tokens to get back wTON. The swap is done at a fixed rate (like wETH) that is set in the config file and it's static. It's an anti-abuse mechanism, does not require any throttling or ratelimit.
- A ProxyApp to work with the TAC Adapter (CCL) and let transaction flowing from and to TON wallets.

Relationship between contract is 1:1:1. It needs a deployment of:
- ERC20 contract
- Associated TreasurySwap contract
- ProxyApp Associated to the TreasurySwap
for each ERC20 Token included in the faucet.

Deployment scripts must be run manually and modified according to the output of the previous run.

This software is provided as it is, being a testnet project this code was not audited. Use it at your own risk.

# Instructions to deploy:

1) git clone this repo

2) npm i

3) EXPORT MNEMONIC = "test test test test test test test test test test test junk"

4) npx hardhat run deploy/1_deploy_Token.ts --network tacTurin

5) Now change all tokenAddress of contracts in the deploy/2_deploy_treasury.ts script with the one deployed in step 4)

6) npx hardhat run deploy/2_deploy_treasury.ts --network tacTurin

7) Now change all the treasuryAddress in the deploy/3_deploy_proxy.ts script with the one deployed in step 6)

8) npx hardhat run deploy/3_deploy_proxy.ts --network tacTurin

step 3 gives ERC20 token addresses -> this is needed to calculate the JettonAddress (TVMTokenAddress) with the TAC SDK. JettonAddress are required in the TAC SDK for the Crosschain operations with tokens.

step 6 gives all the TreasurySwap addresses for each ERC20 deployed -> this is not used in the TAC SDK

step 8 gives all the ProxyApp addresses for each TreasurySwap deployed -> this is needed in the TAC SDK (EVMProxyApp)

for verification of contract : npx hardhat verify --network tac_testnet 0xf96AFa7ef678bbf66a6cC185400315F777b61A61

# Treasury Swap & ERC20 Token Modification Documentation

## Overview
This document outlines the modifications made to the TreasurySwap contract and TestnetERC20 token contract to improve security, streamline minting and burning operations, and restrict token creation to the TreasurySwap contract.

## Summary of Changes

### 1. Restricted Minting & Burning in TestnetERC20
**Before:** Only admins could mint tokens.  
**Now:** Only the TreasurySwap contract can mint and burn tokens.  
**Why?** To prevent unauthorized minting and ensure controlled token supply.  
**Implementation:**  
- Introduced `setTreasurySwap()` to assign the TreasurySwap contract address once.
- Modified `mint()` and `burn()` to allow only TreasurySwap to execute these functions.

### 2. Removed User Allowance Requirement for wTON in TreasurySwap
**Before:** Users needed to approve TreasurySwap to spend their wTON.  
**Now:** TreasurySwap directly transfers wTON from the user without requiring approval.  
**Why?** To simplify user interactions and remove unnecessary approvals.  
**Implementation:** TreasurySwap now directly transfers wTON from the sender without requiring prior approval.

### 3. Ensured Only TreasurySwap Can Mint TestnetERC20
**Before:** Any admin could mint tokens.  
**Now:** Minting is only possible through TreasurySwap.  
**Why?** To restrict unauthorized token creation.  
**Implementation:**  
- `mint()` now checks `msg.sender == treasurySwap` before execution.

### 4. Added Withdrawal Functions to TestnetERC20
**Before:** TreasurySwap had withdrawal functions, but TestnetERC20 did not.  
**Now:** TestnetERC20 has functions to withdraw tokens and ETH.  
**Why?** To allow admins to manage contract balances efficiently.  
**Implementation:** Added `adminWithdraw()`, `adminWithdrawETH()`, and `adminWithdrawTON()` functions to TestnetERC20.

### 5. Fixed Explicit Type Conversion Issue
**Before:** `TestnetERC20 private payable token;` caused an error.  
**Now:** The contract correctly references TestnetERC20 without incorrect payable conversion.  
**Why?** Solidity does not allow non-payable to payable conversion directly.  
**Implementation:** Removed `payable` from TestnetERC20 variable declaration.

### 6. Grant Role Adjustments for Access Control
**Before:** Granting roles required bytes conversion manually.  
**Now:** Role assignment explicitly uses `keccak256("ROLE_NAME")` to convert strings to bytes.  
**Why?** To ensure proper role management without manual byte conversion.  
**Implementation:** Used `keccak256("ROLE_NAME")` for granting roles.

## How It Works Now

### 1. Token Minting Process
1. User sends wTON to TreasurySwap.
2. TreasurySwap calculates the equivalent ERC20 token amount.
3. TreasurySwap calls `mint()` on TestnetERC20.
4. User receives the new ERC20 tokens.

### 2. Token Burning Process
1. User sends ERC20 tokens to TreasurySwap.
2. TreasurySwap calculates the equivalent wTON refund amount.
3. TreasurySwap calls `burn()` on TestnetERC20.
4. User receives the wTON refund.

### 3. Treasury Withdrawals
- Admin can withdraw TestnetERC20 tokens, wTON, or ETH from the TreasurySwap and TestnetERC20 contracts.

### 4. Role & Access Control
- TreasurySwap is the only entity allowed to mint and burn ERC20 tokens.
- Admins have access to withdraw funds and set the TreasurySwap contract address.

## Conclusion
The updated system improves security by restricting minting and burning to TreasurySwap, enhances user experience by removing the need for wTON approval, and adds essential withdrawal functions for fund management. These changes collectively strengthen the TreasurySwap ecosystem and ensure controlled token operations.

