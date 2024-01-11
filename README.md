# Sample ERC20 Vault

## Overview

The Vault contract is a Solidity smart contract designed to enable users to deposit and withdraw ERC20 tokens that are whitelisted on the given contract. This contract includes admin access control so that the current owner of the contract can pause and unpause it, whitelist ERC20 token addresses, as well as transfer ownership of the contract (inherits OpenZeppelins' Ownable contract).

## Features

- **Deposit and Withdrawal**: Users can deposit and withdraw whitelisted ERC20 tokens.
- **ERC20 Token Whitelisting**: The owner of the contract can whitelist ERC20 token addresses so that users can deposit those given tokens into the Vault.
- **Pausing**: The owner of the contract can pause or unpause the contract, controlling the access flow to its user-facing functions.
- **Access Control**: Only the owner of the contract can pause/unpause the contract and whitelist tokens.

## Requirements

- The testing suite was drafted using Foundry. To run it, the Foundry framework should be installed. Refer to the Foundry Book at:
[Foundry](https://getfoundry.sh/)

## Setup

1. **Clone the repository**:
   ```bash
   git clone [REPOSITORY_URL]
   cd [REPOSITORY_DIRECTORY]
   ```

2. **Compile the contract and testing suite**:
   ```bash
   forge build
   ```

## Running Tests

To run the testing suite:

```bash
forge test
```

To run a specific test:
```bash
forge test --match-contract VaultTest --match-test NAME_OF_TEST
```

(To check calldata stack for a given test add the ``` -vvvv ``` modifier after your test command.)

To check testing coverage:
```bash
forge coverage
```

### Expected user flow

- User calls ```approve()``` on a whitelisted token and approves the amount to deposit to the Vault
- User calls ```deposit(WHITELISTED_TOKEN_ADDRESS, APPROVED_AMOUNT``` to deposit up to the previously approved amount of whitelisted token
- User calls ```withdraw(WHITELISTED_TOKEN_ADDRESS, AMOUNT_TO_WITHDRAW)``` to withdraw the requested amount of previously deposited token

### Expected owner flow

- Owner calls ```whitelistToken(ERC20_ADDRESS)``` to whitelist a given ERC20 token address
- Owner calls ```pause()``` to restrict user access flow to the contract
- Owner calls ```unpause()``` to restore user access flow to the contract
- Owner calls ```transferOwnership(NEW_OWNER)``` to give ownership of the contract to a new address
