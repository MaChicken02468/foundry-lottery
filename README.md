# Foundry Lottery Project

This project is a decentralized lottery system built using Solidity and the Foundry framework. It leverages Chainlink VRF (Verifiable Random Function) for secure and tamper-proof randomness to select lottery winners.

---

## Features

- **Decentralized Lottery**: Users can enter the lottery by paying an entrance fee.
- **Random Winner Selection**: Uses Chainlink VRF to ensure randomness in winner selection.
- **Configurable Parameters**: Supports multiple networks (e.g., Sepolia, localhost) with customizable settings.
- **Automated Testing**: Includes unit and integration tests using Foundry's testing framework.

---

## Tools Used

- **Foundry**: A fast, portable, and modular toolkit for Ethereum development.
  - **Forge**: Testing framework for smart contracts.
  - **Cast**: CLI tool for interacting with Ethereum smart contracts.
  - **Anvil**: Local Ethereum node for testing and development.

- **Chainlink VRF**: Provides secure and verifiable randomness for selecting lottery winners.

---

## Project Structure

- **`src/`**: Contains the main smart contract (`Raffle.sol`) implementing the lottery logic.
- **`script/`**: Deployment and interaction scripts.
  - `DeployRaffle.s.sol`: Deploys the `Raffle` contract and sets up Chainlink VRF subscriptions.
  - `HelperConfig.s.sol`: Provides network-specific configurations.
- **`test/`**: Unit and integration tests for the contracts.
- **`lib/`**: External libraries and dependencies.

---

## Prerequisites

- Install Foundry by following the [Foundry installation guide](https://book.getfoundry.sh/getting-started/installation.html).
- Set up a Chainlink VRF subscription and fund it with LINK tokens.

---

## Usage

### Build the Project

```shell
forge build
```

### Run Tests

```shell
forge test
```

### Format Code

```shell
forge fmt
```

### Deploy the Contract

Replace `<your_rpc_url>` and `<your_private_key>` with your RPC URL and private key.

```shell
forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
```

### Run a Local Node

```shell
anvil
```

### Gas Snapshots

Generate gas