# Identity Verification Badge System

A Clarity smart contract that allows a designated verifier to confirm user identities by assigning a verification badge.

## Features
- Only the trusted verifier can assign badges.
- Each user can only be verified once.
- Anyone can read if a user is verified.

## Setup
1. Clone the repo.
2. Run `clarinet check` to verify syntax.
3. Add tests in `tests/`.

## Contract Functions
- `(verify-identity (user principal))`: Called by verifier to assign badge.
- `(is-verified (user principal))`: Read-only check if user is verified.

## Security
- Verifier access control.
- Prevents re-verification.
