;; VerifyChain: Enhanced Digital Identity Verification System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-found (err u102))
(define-constant err-already-verified (err u103))
(define-constant err-not-verified (err u104))
(define-constant err-invalid-attestation (err u105))
(define-constant err-insufficient-reputation (err u106))
(define-constant err-expired (err u107))

;; Data vars
(define-data-var governance-enabled bool false)

;; Define the data structure for an identity
(define-map identities
  { address: principal }
  { name: (string-utf8 50),
    email: (string-utf8 50),
    verification-tier: uint,
    verified: bool,
    timestamp: uint,
    expiration: uint,
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

;; Define map for disputes
(define-map disputes
  { disputant: principal, subject: principal }
  { reason: (string-utf8 100), resolved: bool })

;; Events
(define-public (print-event (event-type (string-ascii 50)) (data (string-ascii 100)))
  (ok (print { event-type: event-type, data: data })))

;; Function to register a new identity
(define-public (register-identity (name (string-utf8 50)) (email (string-utf8 50)))
  (let ((caller tx-sender))
    (match (map-get? identities { address: caller })
      success (err err-already-registered)
      failure 
        (begin
          (map-set identities
            { address: caller }
            { name: name, 
              email: email, 
              verification-tier: u0,
              verified: false, 
              timestamp: block-height,
              expiration: (+ block-height u52560), ;; Set expiration to ~1 year (assuming 10 min blocks)
              reputation: u0,
              revoked: false })
          (try! (print-event "IdentityRegistered" (concat (concat "Address: " (to-ascii caller)) (concat ", Name: " name))))
          (ok true)))))

;; Function to verify an identity (only contract owner or governance can do this)
(define-public (verify-identity (address principal) (tier uint))
  (if (or (is-eq tx-sender contract-owner) (var-get governance-enabled))
      (match (map-get? identities { address: address })
        identity (if (get verified identity)
                     (err err-already-verified)
                     (begin
                       (map-set identities
                         { address: address }
                         (merge identity { verified: true, verification-tier: tier, expiration: (+ block-height u52560) }))
                       (try! (print-event "IdentityVerified" (concat "Address: " (to-ascii address))))
                       (ok true)))
        (err err-not-found))
      (err err-not-owner)))

;; Function to renew verification
(define-public (renew-verification)
  (match (map-get? identities { address: tx-sender })
    identity (begin
               (map-set identities
                 { address: tx-sender }
                 (merge identity { expiration: (+ block-height u52560) }))
               (try! (print-event "VerificationRenewed" (concat "Address: " (to-ascii tx-sender))))
               (ok true))
    (err err-not-found)))

;; Function to check if an identity is verified and not expired
(define-read-only (is-verified (address principal))
  (match (map-get? identities { address: address })
    identity (and (get verified identity) 
                  (not (get revoked identity))
                  (>= (get expiration identity) block-height))
    false))

;; Function to get identity details
(define-read-only (get-identity (address principal))
  (map-get? identities { address: address }))

;; Function to update email (only identity owner can do this)
(define-public (update-email (new-email (string-utf8 50)))
  (match (map-get? identities { address: tx-sender })
    identity (begin
               (map-set identities
                 { address: tx-sender }
                 (merge identity { email: new-email }))
               (try! (print-event "EmailUpdated" (concat "Address: " (to-ascii tx-sender))))
               (ok true))
    (err err-not-found)))

;; Function to make an attestation
(define-public (make-attestation (subject principal))
  (let ((attester tx-sender))
    (if (is-verified attester)
        (begin
          (map-set attestations
            { attester: attester, subject: subject }
            { timestamp: block-height, valid: true })
          (try! (print-event "AttestationMade" (concat (concat "Attester: " (to-ascii attester)) (concat ", Subject: " (to-ascii subject)))))
          (ok true))
        (err err-not-verified))))

;; Function to revoke an attestation
(define-public (revoke-attestation (subject principal))
  (let ((attester tx-sender))
    (match (map-get? attestations { attester: attester, subject: subject })
      attestation (begin
                    (map-set attestations
                      { attester: attester, subject: subject }
                      (merge attestation { valid: false }))
                    (try! (print-event "AttestationRevoked" (concat (concat "Attester: " (to-ascii attester)) (concat ", Subject: " (to-ascii subject)))))
                    (ok true))
      (err err-invalid-attestation))))

;; Function to update reputation (only contract owner or governance can do this)
(define-public (update-reputation (address principal) (change int))
  (if (or (is-eq tx-sender contract-owner) (var-get governance-enabled))
      (match (map-get? identities { address: address })
        identity (let ((new-reputation (+ (get reputation identity) change)))
                   (map-set identities
                     { address: address }
                     (merge identity { reputation: (if (< new-reputation 0) u0 (to-uint new-reputation)) }))
                   (try! (print-event "ReputationUpdated" (concat (concat "Address: " (to-ascii address)) (concat ", New Reputation: " (to-ascii new-reputation)))))
                   (ok true))
        (err err-not-found))
      (err err-not-owner)))

;; Function to file a dispute
(define-public (file-dispute (subject principal) (reason (string-utf8 100)))
  (let ((disputant tx-sender))
    (if (is-verified disputant)
        (begin
          (map-set disputes
            { disputant: disputant, subject: subject }
            { reason: reason, resolved: false })
          (try! (print-event "DisputeFiled" (concat (concat "Disputant: " (to-ascii disputant)) (concat ", Subject: " (to-ascii subject)))))
          (ok true))
        (err err-not-verified))))

;; Function to resolve a dispute (only contract owner or governance can do this)
(define-public (resolve-dispute (disputant principal) (subject principal))
  (if (or (is-eq tx-sender contract-owner) (var-get governance-enabled))
      (match (map-get? disputes { disputant: disputant, subject: subject })
        dispute (begin
                  (map-set disputes
                    { disputant: disputant, subject: subject }
                    (merge dispute { resolved: true }))
                  (try! (print-event "DisputeResolved" (concat (concat "Disputant: " (to-ascii disputant)) (concat ", Subject: " (to-ascii subject)))))
                  (ok true))
        (err err-not-found))
      (err err-not-owner)))

;; Function to enable/disable governance
(define-public (set-governance (enabled bool))
  (if (is-eq tx-sender contract-owner)
      (begin
        (var-set governance-enabled enabled)
        (try! (print-event "GovernanceStatusChanged" (concat "Enabled: " (if enabled "true" "false"))))
        (ok true))
      (err err-not-owner)))

;; Governance proposal function (placeholder for future implementation)
(define-public (submit-governance-proposal (proposal-id uint) (action (string-utf8 100)))
  (if (var-get governance-enabled)
      (begin
        ;; Implement governance logic here
        (try! (print-event "GovernanceProposalSubmitted" (concat (concat "Proposal ID: " (to-ascii proposal-id)) (concat ", Action: " action))))
        (ok true))
      (err u108))) ;; Governance not enabled

