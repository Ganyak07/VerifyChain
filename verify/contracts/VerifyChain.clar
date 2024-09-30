;; VerifyChain:  Digital Identity Verification System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-found (err u102))
(define-constant err-already-verified (err u103))
(define-constant err-not-verified (err u104))
(define-constant err-invalid-attestation (err u105))

;; Define the data structure for an identity
(define-map identities
  { address: principal }
  { name: (string-utf8 50),
    email: (string-utf8 50),
    verified: bool,
    timestamp: uint,
    reputation: uint,
    revoked: bool })

;; Define map for identity attributes
(define-map identity-attributes
  { address: principal, key: (string-utf8 50) }
  { value: (string-utf8 100) })

;; Define map for attestations
(define-map attestations
  { attester: principal, subject: principal }
  { timestamp: uint, valid: bool })

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
              timestamp: block-height,
              reputation: u0,
              revoked: false })
          (ok true)))))

;; Function to verify an identity (only contract owner can do this)
(define-public (verify-identity (address principal))
  (if (is-eq tx-sender contract-owner)
      (match (map-get? identities { address: address })
        identity (if (get verified identity)
                     err-already-verified
                     (begin
                       (map-set identities
                         { address: address }
                         (merge identity { verified: true }))
                       (ok true)))
        err-not-found)
      err-not-owner))

;; Function to revoke an identity (only contract owner can do this)
(define-public (revoke-identity (address principal))
  (if (is-eq tx-sender contract-owner)
      (match (map-get? identities { address: address })
        identity (begin
                   (map-set identities
                     { address: address }
                     (merge identity { revoked: true }))
                   (ok true))
        err-not-found)
      err-not-owner))

;; Function to check if an identity is verified
(define-read-only (is-verified (address principal))
  (match (map-get? identities { address: address })
    identity (and (get verified identity) (not (get revoked identity)))
    false))

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

;; Function to add or update an identity attribute
(define-public (set-identity-attribute (key (string-utf8 50)) (value (string-utf8 100)))
  (match (map-get? identities { address: tx-sender })
    identity (begin
               (map-set identity-attributes
                 { address: tx-sender, key: key }
                 { value: value })
               (ok true))
    err-not-found))

;; Function to get an identity attribute
(define-read-only (get-identity-attribute (address principal) (key (string-utf8 50)))
  (map-get? identity-attributes { address: address, key: key }))

;; Function to make an attestation
(define-public (make-attestation (subject principal))
  (let ((attester tx-sender))
    (if (is-verified attester)
        (begin
          (map-set attestations
            { attester: attester, subject: subject }
            { timestamp: block-height, valid: true })
          (ok true))
        err-not-verified)))

;; Function to revoke an attestation
(define-public (revoke-attestation (subject principal))
  (let ((attester tx-sender))
    (match (map-get? attestations { attester: attester, subject: subject })
      attestation (begin
                    (map-set attestations
                      { attester: attester, subject: subject }
                      (merge attestation { valid: false }))
                    (ok true))
      err-invalid-attestation)))

;; Function to check if an attestation is valid
(define-read-only (is-attestation-valid (attester principal) (subject principal))
  (match (map-get? attestations { attester: attester, subject: subject })
    attestation (get valid attestation)
    false))

;; Function to update reputation (only contract owner can do this)
(define-public (update-reputation (address principal) (change int))
  (if (is-eq tx-sender contract-owner)
      (match (map-get? identities { address: address })
        identity (let ((new-reputation (+ (get reputation identity) change)))
                   (map-set identities
                     { address: address }
                     (merge identity { reputation: (if (< new-reputation u0) u0 new-reputation) }))
                   (ok true))
        err-not-found)
      err-not-owner))

;; Function to get reputation
(define-read-only (get-reputation (address principal))
  (match (map-get? identities { address: address })
    identity (get reputation identity)
    u0))