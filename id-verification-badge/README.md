# ID Verification Badge System

A comprehensive Clarity smart contract for managing identity verification badges on the Stacks blockchain.

## Overview

This contract provides a robust identity verification system with multiple verification levels, expiration dates, and enhanced security features. It's designed for applications requiring trusted identity verification with granular control over verification levels and duration.

## Features

### Phase 2 Enhancements

- **Bug Fix**: Fixed incorrect map definition syntax from `(map principal bool)` to `(define-map verified principal {...})`
- **Verification Levels**: Three tiers (Basic, Premium, Enterprise)
- **Expiration System**: Time-bound verifications with renewal capability
- **Enhanced Security**: Role-based access control with multiple authorized verifiers
- **Metadata Storage**: Document hashes and verification details
- **Fee System**: Configurable verification fees

## Contract Structure

### Error Constants
- `ERR-NOT-VERIFIER (u100)`: Unauthorized verifier
- `ERR-ALREADY-VERIFIED (u101)`: User already verified
- `ERR-NOT-VERIFIED (u102)`: User not verified
- `ERR-INVALID-LEVEL (u103)`: Invalid verification level
- `ERR-UNAUTHORIZED (u104)`: Unauthorized access
- `ERR-VERIFICATION-EXPIRED (u105)`: Verification expired

### Verification Levels
- **LEVEL-BASIC (u1)**: Basic identity verification
- **LEVEL-PREMIUM (u2)**: Enhanced verification with additional checks
- **LEVEL-ENTERPRISE (u3)**: Enterprise-grade verification

### Data Structures

#### Verified Users Map
```clarity
{
  is-verified: bool,
  verification-level: uint,
  verified-at: uint,
  expires-at: uint,
  verifier: principal
}
```

#### Verification Metadata Map
```clarity
{
  document-hash: (buff 32),
  verification-type: (string-ascii 50),
  notes: (string-ascii 200)
}
```

## Functions

### Admin Functions

#### `add-verifier`
Adds a new authorized verifier (contract owner only)
```clarity
(add-verifier (verifier principal))
```

#### `remove-verifier`
Removes an authorized verifier (contract owner only)
```clarity
(remove-verifier (verifier principal))
```

#### `set-verification-fee`
Updates the verification fee (contract owner only)
```clarity
(set-verification-fee (new-fee uint))
```

### Core Verification Functions

#### `verify-identity`
Verifies a user's identity with specified level and duration
```clarity
(verify-identity 
  (user principal) 
  (level uint) 
  (duration uint)
  (document-hash (buff 32))
  (verification-type (string-ascii 50))
  (notes (string-ascii 200))
)
```

#### `renew-verification`
Extends verification expiration date
```clarity
(renew-verification (user principal) (additional-duration uint))
```

#### `revoke-verification`
Revokes a user's verification
```clarity
(revoke-verification (user principal))
```

### Read-Only Functions

#### `is-verified`
Checks if a user is currently verified (not expired)
```clarity
(is-verified (user principal))
```

#### `get-verification-info`
Returns complete verification information
```clarity
(get-verification-info (user principal))
```

#### `get-verification-metadata`
Returns verification metadata
```clarity
(get-verification-metadata (user principal))
```

#### `is-authorized-verifier`
Checks if a principal is an authorized verifier
```clarity
(is-authorized-verifier (verifier principal))
```

#### `get-verification-level`
Returns user's verification level
```clarity
(get-verification-level (user principal))
```

#### `is-verification-expired`
Checks if verification has expired
```clarity
(is-verification-expired (user principal))
```

#### `get-contract-info`
Returns contract configuration
```clarity
(get-contract-info)
```

## Usage Examples

### Deploy and Initialize
```bash
clarinet deploy
```

### Add Verifier
```clarity
(contract-call? .id-badge add-verifier 'SP1ABCD...)
```

### Verify Identity
```clarity
(contract-call? .id-badge verify-identity 
  'SP1USER... 
  u2  ;; Premium level
  u52560  ;; ~10 weeks duration
  0x1234...  ;; Document hash
  "passport"  ;; Verification type
  "Verified via passport scan"  ;; Notes
)
```

### Check Verification Status
```clarity
(contract-call? .id-badge is-verified 'SP1USER...)
```

## Security Features

1. **Role-Based Access**: Only authorized verifiers can verify identities
2. **Expiration System**: Verifications automatically expire
3. **Document Integrity**: SHA-256 hashes for document verification
4. **Audit Trail**: Complete verification history and metadata
5. **Owner Controls**: Contract owner can manage verifiers and fees

## Testing

Run the test suite:
```bash
clarinet test
```

## Deployment

1. Update the contract owner address in the contract
2. Configure verification fees and duration limits
3. Deploy using Clarinet or Stacks CLI
4. Add initial authorized verifiers

## License

MIT License

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Changelog

### Version 2.0.0 (Phase 2)
- Fixed map definition bug
- Added verification levels and expiration
- Enhanced security with role-based access
- Added metadata storage
- Implemented fee system
- Added renewal and revocation capabilities
