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

;; Test: Verify Identity
(define-public (test-verify-identity)
  (begin
    (print "Test: Verify Identity")
    (asserts! (is-ok (as-contract (contract-call? .verifychain verify-identity user-1))) "Failed to verify identity")
    (asserts! (is-eq (unwrap-panic (contract-call? .verifychain is-verified user-1)) true) "Identity should be verified")
    (asserts! (is-err (contract-call? .verifychain verify-identity user-1)) "Should not allow verifying already verified identity")
    (asserts! (is-err (contract-call? .verifychain verify-identity user-2)) "Non-owner should not be able to verify identity")
    (ok true)))

;; Test: Update Email
(define-public (test-update-email)
  (begin
    (print "Test: Update Email")
    (asserts! (is-ok (contract-call? .verifychain update-email "newalice@example.com")) "Failed to update email")
    (asserts! (is-eq (get email (unwrap-panic (contract-call? .verifychain get-identity user-1))) "newalice@example.com") "Email not updated correctly")
    (ok true)))

;; Run all tests
(define-public (run-tests)
  (begin
    (try! (test-register-identity))
    (try! (test-verify-identity))
    (try! (test-update-email))
    (print "All Clarinet tests completed successfully!")
    (ok true)))