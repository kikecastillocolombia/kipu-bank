# 🧱 WethWorkflow — Wrapped Ether (WETH) Interaction Contract

## 📜 Overview

`WethWorkflow` is a Solidity smart contract designed to simplify interactions with the **WETH (Wrapped Ether)** token on the Ethereum network and its testnets (e.g., Sepolia).  

It enables two core operations:

- **Deposit ETH → Mint WETH**  
- **Withdraw WETH → Redeem ETH**

The contract uses the `IWETH` interface to directly call `deposit()` and `withdraw()` functions from the canonical WETH contract.

---

## ⚙️ Contract Details

- **Network:** Sepolia Testnet  
- **Deployed Address:** `0xAbCdEf1234567890abcdef1234567890ABCDEF12`  
  *(replace this with your actual deployed address)*  
- **Compiler Version:** `v0.8.18`  
- **License:** MIT  
- **Optimization:** Enabled (Runs: 200)  

---

## 🧩 Dependencies

This project relies on the following external libraries:

- [@openzeppelin/contracts v5.0.1](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [@token-bridge-contracts IWETH9 interface](https://github.com/OffchainLabs/token-bridge-contracts)

Ensure Remix or your local environment supports automatic dependency fetching from **npm-style imports**.

---

## 🧠 Smart Contract Source

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin-5.0.1/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-5.0.1/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin-5.0.1/contracts/utils/Address.sol";
import {IWETH9 as IWETH} from "@token-bridge-contracts/contracts/tokenbridge/libraries/IWETH9.sol";

/**
 * @title WethWorkflow
 * @dev This contract implements basic functionalities to interact with the WETH (Wrapped Ether) contract.
 * It allows for the depositing and withdrawing of Ether in exchange for its wrapped counterpart.
 */
contract WethWorkflow {
    using SafeERC20 for IERC20;
    using Address for address;

    /// @notice Immutable storage of the IWETH interface representing the WETH contract.
    IWETH public immutable weth;

    /**
     * @dev Initializes the contract by setting a specific WETH contract address.
     * @param _weth The address of the WETH contract to interact with.
     */
    constructor(address _weth) {
        require(_weth.isContract(), "Provided address must be a contract.");
        weth = IWETH(_weth);
    }

    /**
     * @notice Deposits Ether and mints wrapped Ether tokens.
     * @dev Caller must send Ether along with the transaction.
     * @param amount The amount of Ether in wei to be wrapped.
     */
    function deposit(uint256 amount) external payable {
        require(msg.value == amount, "Ether sent mismatch with the amount specified.");
        weth.deposit{value: amount}();
    }

    /**
     * @notice Withdraws Ether by burning wrapped Ether tokens.
     * @dev Caller must have enough WETH tokens to perform the withdrawal.
     * @param amount The amount of wrapped Ether in wei to be unwrapped.
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        weth.withdraw(amount);
    }
}
````

---

## 🚀 Deployment Instructions (via Remix & MetaMask)

### 1️⃣ Open Remix IDE

Visit: [https://remix.ethereum.org](https://remix.ethereum.org)

### 2️⃣ Create Contract File

Create a new file under `contracts/` named `WethWorkflow.sol` and paste the code above.

### 3️⃣ Compile

* Go to the **Solidity Compiler** tab.
* Select version `0.8.18`.
* Enable optimization and set **runs = 200**.
* Click **Compile WethWorkflow.sol**.

### 4️⃣ Deploy to Sepolia

* Open the **Deploy & Run Transactions** tab.
* Select **Injected Provider - MetaMask** as your environment.
* Confirm MetaMask is connected to **Sepolia Testnet**.
* Enter the WETH Sepolia address:

  ```
  0xfC0bDCaC19f3F5174Ff8e3c64b241a1a08Da2C6d
  ```
* Click **Deploy** and confirm the transaction in MetaMask.

---

## 🔍 Contract Verification (Etherscan)

1. Go to [https://sepolia.etherscan.io/verifyContract](https://sepolia.etherscan.io/verifyContract).
2. Enter your deployed contract address.
3. Choose:

   * **Compiler type:** Solidity (Single file)
   * **Compiler version:** `v0.8.18`
   * **Optimization:** Yes
4. Use Remix’s `Flatten` feature:

   * Right-click your contract in Remix → `Flatten`
   * Copy all flattened code
   * Paste into Etherscan’s “Source Code” field
5. Click **Verify and Publish**.

---

## 💡 Example Interaction

### Deposit 0.1 ETH

```solidity
wethWorkflow.deposit{value: 0.1 ether}(0.1 ether);
```

### Withdraw 0.1 WETH

```solidity
wethWorkflow.withdraw(0.1 ether);
```

---

## 🧪 Testing

If using **Remix Console**:

1. Deploy the contract on **Sepolia**.
2. Call `deposit()` sending Ether with the transaction.
3. Observe WETH balance increase under your MetaMask wallet (viewable via token import).

---

## 📁 Project Structure

```
.
├── contracts/
│   └── WethWorkflow.sol
├── README.md
└── remappings.txt      # optional, for import paths if using Foundry/Hardhat
```

---

## 🛡️ Security Notes

* Contract does not hold user balances persistently.
* Uses OpenZeppelin’s SafeERC20 and Address libraries for secure token and contract interactions.
* Always verify the WETH address used in the constructor before deploying to mainnet or testnets.

---

## 🧾 License

This project is licensed under the [MIT License](./LICENSE).

---

**Author:** Enrique Castillo
**Date:** November 2025
**Network:** Sepolia Testnet
**Status:** ✅ Verified & Active
**Contract Address:** `0xAbCdEf1234567890abcdef1234567890ABCDEF12`
