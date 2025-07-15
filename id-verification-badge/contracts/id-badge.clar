(define-constant ERR-NOT-VERIFIER (err u100))
(define-constant ERR-ALREADY-VERIFIED (err u101))

(define-data-var verified (map principal bool))
(define-constant verifier 'SP3K8BC0PPEVCV...XY8HQ0) ;; Replace with your verifier address

(define-public (verify-identity (user principal))
  (begin
    (if (is-eq tx-sender verifier)
        (if (is-some (map-get? verified user))
            ERR-ALREADY-VERIFIED
            (begin
              (map-set verified user true)
              (ok true)))
        ERR-NOT-VERIFIER)))
        
(define-read-only (is-verified (user principal))
  (default-to false (map-get? verified user)))
