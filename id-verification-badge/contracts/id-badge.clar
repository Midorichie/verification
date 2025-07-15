;; Enhanced ID Verification Badge Contract
;; Phase 2 - Bug fixes and new functionality

;; Error constants
(define-constant ERR-NOT-VERIFIER (err u100))
(define-constant ERR-ALREADY-VERIFIED (err u101))
(define-constant ERR-NOT-VERIFIED (err u102))
(define-constant ERR-INVALID-LEVEL (err u103))
(define-constant ERR-UNAUTHORIZED (err u104))
(define-constant ERR-VERIFICATION-EXPIRED (err u105))

;; Contract owner/admin
(define-constant contract-owner tx-sender)

;; Verification levels
(define-constant LEVEL-BASIC u1)
(define-constant LEVEL-PREMIUM u2)
(define-constant LEVEL-ENTERPRISE u3)

;; Data structures
(define-map verified principal 
  {
    is-verified: bool,
    verification-level: uint,
    verified-at: uint,
    expires-at: uint,
    verifier: principal
  }
)

(define-map authorized-verifiers principal bool)
(define-map verification-metadata principal 
  {
    document-hash: (buff 32),
    verification-type: (string-ascii 50),
    notes: (string-ascii 200)
  }
)

;; Configuration
(define-data-var verification-fee uint u1000000) ;; 1 STX in microSTX
(define-data-var max-verification-duration uint u5256000) ;; ~1 year in blocks

;; Initialize contract owner as authorized verifier
(map-set authorized-verifiers contract-owner true)

;; Admin functions
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
    (asserts! (not (is-eq verifier contract-owner)) ERR-INVALID-LEVEL) ;; Prevent duplicate owner
    (map-set authorized-verifiers verifier true)
    (ok true)
  )
)

(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
    (asserts! (not (is-eq verifier contract-owner)) ERR-INVALID-LEVEL) ;; Prevent removing owner
    (map-delete authorized-verifiers verifier)
    (ok true)
  )
)

(define-public (set-verification-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
    (asserts! (<= new-fee u100000000) ERR-INVALID-LEVEL) ;; Max 100 STX fee
    (var-set verification-fee new-fee)
    (ok true)
  )
)

;; Core verification functions
(define-public (verify-identity 
  (user principal) 
  (level uint) 
  (duration uint)
  (document-hash (buff 32))
  (verification-type (string-ascii 50))
  (notes (string-ascii 200))
)
  (let 
    (
      (current-block block-height)
      (expires-at (+ current-block duration))
      (is-authorized (default-to false (map-get? authorized-verifiers tx-sender)))
      (existing-verification (map-get? verified user))
    )
    (begin
      ;; Check if sender is authorized verifier
      (asserts! is-authorized ERR-NOT-VERIFIER)
      
      ;; Check if user is already verified
      (asserts! (is-none existing-verification) ERR-ALREADY-VERIFIED)
      
      ;; Validate verification level
      (asserts! (and (>= level LEVEL-BASIC) (<= level LEVEL-ENTERPRISE)) ERR-INVALID-LEVEL)
      
      ;; Check duration doesn't exceed maximum and is not zero
      (asserts! (and (> duration u0) (<= duration (var-get max-verification-duration))) ERR-INVALID-LEVEL)
      
      ;; Validate document hash is not empty
      (asserts! (> (len document-hash) u0) ERR-INVALID-LEVEL)
      
      ;; Validate verification type is not empty
      (asserts! (> (len verification-type) u0) ERR-INVALID-LEVEL)
      
      ;; Validate notes field (can be empty, but check for reasonable length)
      (asserts! (<= (len notes) u200) ERR-INVALID-LEVEL)
      
      ;; Prevent self-verification
      (asserts! (not (is-eq tx-sender user)) ERR-UNAUTHORIZED)
      
      ;; Set verification data
      (map-set verified user {
        is-verified: true,
        verification-level: level,
        verified-at: current-block,
        expires-at: expires-at,
        verifier: tx-sender
      })
      
      ;; Set metadata
      (map-set verification-metadata user {
        document-hash: document-hash,
        verification-type: verification-type,
        notes: notes
      })
      
      (ok true)
    )
  )
)

(define-public (renew-verification (user principal) (additional-duration uint))
  (let 
    (
      (verification-data (unwrap! (map-get? verified user) ERR-NOT-VERIFIED))
      (is-authorized (default-to false (map-get? authorized-verifiers tx-sender)))
      (new-expires-at (+ (get expires-at verification-data) additional-duration))
    )
    (begin
      (asserts! is-authorized ERR-NOT-VERIFIER)
      (asserts! (and (> additional-duration u0) (<= additional-duration (var-get max-verification-duration))) ERR-INVALID-LEVEL)
      
      ;; Prevent self-renewal
      (asserts! (not (is-eq tx-sender user)) ERR-UNAUTHORIZED)
      
      ;; Check that new expiration doesn't exceed reasonable limits
      (asserts! (< new-expires-at (+ block-height (* u2 (var-get max-verification-duration)))) ERR-INVALID-LEVEL)
      
      (map-set verified user (merge verification-data {
        expires-at: new-expires-at,
        verifier: tx-sender
      }))
      
      (ok true)
    )
  )
)

(define-public (revoke-verification (user principal))
  (let 
    (
      (verification-data (unwrap! (map-get? verified user) ERR-NOT-VERIFIED))
      (is-authorized (default-to false (map-get? authorized-verifiers tx-sender)))
    )
    (begin
      (asserts! is-authorized ERR-NOT-VERIFIER)
      
      ;; Prevent self-revocation
      (asserts! (not (is-eq tx-sender user)) ERR-UNAUTHORIZED)
      
      (map-delete verified user)
      (map-delete verification-metadata user)
      (ok true)
    )
  )
)

;; Read-only functions
(define-read-only (is-verified (user principal))
  (match (map-get? verified user)
    verification-data 
      (and 
        (get is-verified verification-data)
        (< block-height (get expires-at verification-data))
      )
    false
  )
)

(define-read-only (get-verification-info (user principal))
  (map-get? verified user)
)

(define-read-only (get-verification-metadata (user principal))
  (map-get? verification-metadata user)
)

(define-read-only (is-authorized-verifier (verifier principal))
  (default-to false (map-get? authorized-verifiers verifier))
)

(define-read-only (get-verification-level (user principal))
  (match (map-get? verified user)
    verification-data (some (get verification-level verification-data))
    none
  )
)

(define-read-only (is-verification-expired (user principal))
  (match (map-get? verified user)
    verification-data (>= block-height (get expires-at verification-data))
    true
  )
)

(define-read-only (get-contract-info)
  {
    owner: contract-owner,
    verification-fee: (var-get verification-fee),
    max-duration: (var-get max-verification-duration)
  }
)

;; Public utility functions
(define-public (pay-verification-fee)
  (stx-transfer? (var-get verification-fee) tx-sender contract-owner)
)

;; Input validation helpers
(define-private (is-valid-verification-level (level uint))
  (and (>= level LEVEL-BASIC) (<= level LEVEL-ENTERPRISE))
)

(define-private (is-valid-duration (duration uint))
  (and (> duration u0) (<= duration (var-get max-verification-duration)))
)

(define-private (is-non-empty-buffer (buffer (buff 32)))
  (> (len buffer) u0)
)

(define-private (is-non-empty-string (str (string-ascii 50)))
  (> (len str) u0)
)

(define-private (is-valid-notes (notes (string-ascii 200)))
  (<= (len notes) u200)
)
