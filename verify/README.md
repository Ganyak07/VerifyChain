# VerifyChain: Digital Identity Verification System

VerifyChain is a Clarity smart contract that implements a digital identity verification system on the Stacks blockchain. It allows users to register their identities, which can then be verified by the contract owner.

## Features

1. **Identity Registration**: Users can register their identity by providing a name and email address.
2. **Identity Verification**: The contract owner can verify registered identities.
3. **Verification Check**: Anyone can check if a given address has a verified identity.
4. **Identity Retrieval**: Allows retrieval of identity details for a given address.
5. **Identity Count**: Provides the total number of registered identities.
6. **Email Update**: Users can update their email address.

## Smart Contract Functions

### `register-identity`
- **Parameters**: `name` (string-utf8 50), `email` (string-utf8 50)
- **Description**: Allows a user to register their identity.
- **Returns**: `ok true` if successful, `err u101` if the identity already exists.

### `verify-identity`
- **Parameters**: `address` (principal)
- **Description**: Allows the contract owner to verify a registered identity.
- **Returns**: `ok true` if successful, `err u102` if the identity doesn't exist, `err u100` if not called by the owner.

### `is-verified`
- **Parameters**: `address` (principal)
- **Description**: Checks if an identity is verified.
- **Returns**: `true` if verified, `false` otherwise.

### `get-identity`
- **Parameters**: `address` (principal)
- **Description**: Retrieves the identity details for a given address.
- **Returns**: Identity data if it exists, `none` otherwise.

### `get-identity-count`
- **Parameters**: None
- **Description**: Returns the total number of registered identities.
- **Returns**: Unsigned integer representing the count.

### `update-email`
- **Parameters**: `new-email` (string-utf8 50)
- **Description**: Allows a user to update their registered email address.
- **Returns**: `ok true` if successful, `err u102` if the identity doesn't exist.

## Usage

1. Deploy the VerifyChain smart contract to the Stacks blockchain.
2. Users can call `register-identity` to create their identity.
3. The contract owner can call `verify-identity` to verify registered identities.
4. Anyone can use `is-verified` to check an identity's verification status.
5. Use `get-identity` to retrieve identity details.
6. Call `get-identity-count` to get the total number of registered identities.
7. Users can update their email using the `update-email` function.

## Security Considerations

- Only the contract owner can verify identities.
- Users can only register one identity per address.
- The contract does not store sensitive information on-chain.
- Users can only update their own email address.

## Future Improvements

- Implement a multi-step verification process.
- Add functionality to revoke identities.
- Integrate with off-chain identity verification services.
- Implement a reputation system.
- Add support for additional identity attributes.
