;; VerifyChain Clarinet Test Suite

(use-trait sip-010-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

(define-constant contract-owner 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(define-constant user-1 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
(define-constant user-2 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)

;; Test: Register Identity
(define-public (test-register-identity)
  (begin
    (print "Test: Register Identity")
    (asserts! (is-ok (contract-call? .verifychain register-identity "Alice" "alice@example.com")) "Failed to register new identity")
    (asserts! (is-eq (unwrap-panic (contract-call? .verifychain get-identity-count)) u1) "Incorrect identity count after registration")
    (asserts! (is-err (contract-call? .verifychain register-identity "Alice" "alice@example.com")) "Should not allow duplicate registration")
    (ok true)))

;; Test: Verify Identity with Tier
(define-public (test-verify-identity)
  (begin
    (print "Test: Verify Identity with Tier")
    (asserts! (is-ok (as-contract (contract-call? .verifychain verify-identity user-1 u1))) "Failed to verify identity")
    (asserts! (is-eq (unwrap-panic (contract-call? .verifychain is-verified user-1)) true) "Identity should be verified")
    (asserts! (is-err (contract-call? .verifychain verify-identity user-1 u2)) "Should not allow verifying already verified identity")
    (asserts! (is-err (contract-call? .verifychain verify-identity user-2 u1)) "Non-owner should not be able to verify identity")
    (ok true)))

;; Test: Renew Verification
(define-public (test-renew-verification)
  (begin
    (print "Test: Renew Verification")
    (asserts! (is-ok (contract-call? .verifychain renew-verification)) "Failed to renew verification")
    (ok true)))

;; Test: Update Email
(define-public (test-update-email)
  (begin
    (print "Test: Update Email")
    (asserts! (is-ok (contract-call? .verifychain update-email "newalice@example.com")) "Failed to update email")
    (asserts! (is-eq (get email (unwrap-panic (contract-call? .verifychain get-identity user-1))) "newalice@example.com") "Email not updated correctly")
    (ok true)))

;; Test: Make and Revoke Attestation
(define-public (test-attestations)
  (begin
    (print "Test: Make and Revoke Attestation")
    (asserts! (is-ok (contract-call? .verifychain make-attestation user-2)) "Failed to make attestation")
    (asserts! (is-ok (contract-call? .verifychain revoke-attestation user-2)) "Failed to revoke attestation")
    (ok true)))

;; Test: Update Reputation
(define-public (test-update-reputation)
  (begin
    (print "Test: Update Reputation")
    (asserts! (is-ok (as-contract (contract-call? .verifychain update-reputation user-1 5))) "Failed to update reputation")
    (asserts! (is-eq (get reputation (unwrap-panic (contract-call? .verifychain get-identity user-1))) u5) "Reputation not updated correctly")
    (ok true)))

;; Test: File and Resolve Dispute
(define-public (test-disputes)
  (begin
    (print "Test: File and Resolve Dispute")
    (asserts! (is-ok (contract-call? .verifychain file-dispute user-2 "Reason for dispute")) "Failed to file dispute")
    (asserts! (is-ok (as-contract (contract-call? .verifychain resolve-dispute user-1 user-2))) "Failed to resolve dispute")
    (ok true)))

;; Test: Governance
(define-public (test-governance)
  (begin
    (print "Test: Governance")
    (asserts! (is-ok (as-contract (contract-call? .verifychain set-governance true))) "Failed to enable governance")
    (asserts! (is-ok (contract-call? .verifychain submit-governance-proposal u1 "Test proposal")) "Failed to submit governance proposal")
    (ok true)))

;; Run all tests
(define-public (run-tests)
  (begin
    (try! (test-register-identity))
    (try! (test-verify-identity))
    (try! (test-renew-verification))
    (try! (test-update-email))
    (try! (test-attestations))
    (try! (test-update-reputation))
    (try! (test-disputes))
    (try! (test-governance))
    (print "All Clarinet tests completed successfully!")
    (ok true)))