# Aiken HTLC Contract

This repository contains an implementation of a Hashed Time-Locked Contract (HTLC) using the Aiken language.

## Introduction

The HTLC contract allows for secure and conditional payment using a secret key and a timeout mechanism. This ensures that funds are only transferred if a specific condition is met within a given timeframe.

## Prerequisites

- Aiken language installed
- Git installed
- Basic knowledge of smart contracts and blockchain

## Structure

- `src/`: Contains the main contract and utility functions
- `tests/`: Contains test cases for the contract

## Usage

1. Clone the repository:

    ```sh
    git clone https://github.com/angeYobo/htlc-contract-aiken.git
    cd REPO_NAME
    ```

2. Build the project:

    Follow the Aiken build instructions to compile the contract.

3. Run tests:

    ```sh
    aiken test
    ```

## Contract Details

### HTLCDatum

The `HTLCDatum` type encapsulates the essential data for the HTLC contract, including the hash of the secret, the timeout, and the owner's public key hash.

### HTLCRedeemer

The `HTLCRedeemer` type defines the possible actions that can be performed on the contract: `Claim` with a secret or `Refund`.

### Functions

- `fee_value()`: Calculates the fee required for the transaction.
- `fee_paid()`: Checks if the required fee has been paid to the specified team address.
- `signed_by_owner()`: Verifies if the transaction is signed by the owner.
- `deadline_passed()`: Checks if the deadline has passed.
- `get_current_time()`: Retrieves the current time from the `ScriptContext`.

### Validator

Defines the main validator logic for the HTLC contract, handling both `Claim` and `Refund` redeemers.

## Testing

The repository includes several tests to ensure the contract behaves as expected:

- `deadline_passed_test()`
- `deadline_not_passed_test()`
- `fee_paid_test()`
- `fee_not_paid_test()`
- `signed_by_owner_test()`
- `not_signed_by_owner_test()`

## Contribution

Feel free to fork this repository, make improvements, and submit pull requests.

## License

This project is licensed under the MIT License.
