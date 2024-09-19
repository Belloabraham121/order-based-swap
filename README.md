# OrderSwapContract

## Overview

OrderSwapContract is a Solidity smart contract that facilitates decentralized token swaps on the Ethereum blockchain. It allows users to create, cancel, and execute orders for swapping ERC20 tokens. This contract is designed with security in mind, implementing reentrancy guards and using OpenZeppelin's safe transfer methods.

## Features

- Create swap orders
- Cancel existing orders
- Execute orders created by other users
- View order details
- Check user balances
- Emergency withdrawal function for the contract owner

## Contract Details

- License: MIT
- Solidity Version: ^0.8.24
- Dependencies: OpenZeppelin contracts (ERC20, SafeERC20, ReentrancyGuard, Ownable)

## Key Components

### Order Struct

```solidity
struct Order {
    uint256 orderId;
    address seller;
    address tokenForSale;
    uint256 amountForSale;
    address tokenWanted;
    uint256 amountWanted;
    bool isActive;
}
```

### Main Functions

1. `createOrderAndDeposit`: Create a new swap order and deposit tokens.
2. `cancelOrder`: Cancel an existing order.
3. `executeOrder`: Execute an active order.
4. `getOrderDetails`: Retrieve details of a specific order.
5. `getUserBalance`: Check the balance of a user for a specific token.
6. `emergencyWithdraw`: Allow the owner to withdraw tokens in case of emergency.

## Usage

### Creating an Order

To create a new swap order:

1. Approve the contract to spend the tokens you want to sell.
2. Call `createOrderAndDeposit` with the following parameters:
   - `tokenForSale`: Address of the token you're selling
   - `amountForSale`: Amount of tokens you're selling
   - `tokenWanted`: Address of the token you want in exchange
   - `amountWanted`: Amount of tokens you want in exchange

### Cancelling an Order

To cancel an order you've created:

1. Call `cancelOrder` with the `orderId` of the order you want to cancel.
2. The tokens will be returned to your balance in the contract.

### Executing an Order

To execute an existing order:

1. Approve the contract to spend the tokens required by the order.
2. Call `executeOrder` with the `orderId` of the order you want to execute.
3. The tokens will be swapped between you and the order creator.

## Events

The contract emits the following events:

- `OrderCreated`: When a new order is created
- `OrderCancelled`: When an order is cancelled
- `OrderExecuted`: When an order is executed
- `TokensDeposited`: When tokens are deposited into the contract
- `TokensWithdrawn`: When tokens are withdrawn from the contract

## Security Considerations

- The contract uses OpenZeppelin's `ReentrancyGuard` to prevent reentrancy attacks.
- `SafeERC20` is used for all token transfers to prevent common ERC20 pitfalls.
- The contract is `Ownable`, allowing for an emergency withdrawal function.

## Deployment

When deploying the contract, you need to provide an initial owner address:

```solidity
constructor(address initialOwner) Ownable(initialOwner)
```

## Testing

Before using this contract in a production environment, make sure to:

1. Write comprehensive unit tests covering all functions and edge cases.
2. Perform thorough integration tests.
3. Conduct a professional security audit.

## License

This project is licensed under the MIT License. See the SPDX-License-Identifier in the contract file for details.

## Disclaimer

This smart contract is provided as-is. Users should perform their own security checks and audits before using it in a production environment. The authors and contributors are not responsible for any loss of funds or other damages that may occur from using this contract.