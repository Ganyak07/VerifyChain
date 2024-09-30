;; VerifyChain: Digital Identity Verification System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-found (err u102))

;; Define the data structure for an identity
(define-map identities
  { address: principal }
  { name: (string-utf8 50),
    email: (string-utf8 50),
    verified: bool,
    timestamp: uint })

;; Function to register a new identity
(define-public (register-identity (name (string-utf8 50)) (email (string-utf8 50)))
  (let ((caller tx-sender))
    (match (map-get? identities { address: caller })
      success err-already-registered
      failure 
        (begin
          (map-set identities
            { address: caller }
            { name: name, 
              email: email, 
              verified: false, 
              timestamp: block-height })
          (ok true)))))

;; Function to verify an identity (only contract owner can do this)
(define-public (verify-identity (address principal))
  (if (is-eq tx-sender contract-owner)
      (match (map-get? identities { address: address })
        identity (begin
                   (map-set identities
                     { address: address }
                     (merge identity { verified: true }))
                   (ok true))
        err-not-found)
      err-not-owner))

;; Function to check if an identity is verified
(define-read-only (is-verified (address principal))
  (default-to false (get verified (map-get? identities { address: address }))))

;; Function to get identity details
(define-read-only (get-identity (address principal))
  (map-get? identities { address: address }))

;; Function to get the total number of registered identities
(define-read-only (get-identity-count)
  (len (map-keys identities)))

;; Function to update email (only identity owner can do this)
(define-public (update-email (new-email (string-utf8 50)))
  (match (map-get? identities { address: tx-sender })
    identity (begin
               (map-set identities
                 { address: tx-sender }
                 (merge identity { email: new-email }))
               (ok true))
    err-not-found))