import { describe, expect, it, beforeAll } from "vitest";

const accounts = simnet.getAccounts();
const contractOwner = accounts.get("deployer")!;
const user1 = accounts.get("wallet_1")!;
const user2 = accounts.get("wallet_2")!;
const user3 = accounts.get("wallet_3")!;

describe("VerifyChain Enhanced Tests", () => {
  beforeAll(() => {
    // Deploy the contract if it's not already deployed
    simnet.deployContract("verifychain", "verifychain", contractOwner);
  });

  describe("Identity Registration and Verification", () => {
    it("should allow a user to register an identity", () => {
      const { result } = simnet.callPublicFn("verifychain", "register-identity", ["Alice", "alice@example.com"], user1);
      expect(result).toBeOk(true);
    });

    it("should allow the owner to verify an identity with a tier", () => {
      const { result } = simnet.callPublicFn("verifychain", "verify-identity", [user1, 1], contractOwner);
      expect(result).toBeOk(true);
    });

    it("should not allow non-owners to verify an identity", () => {
      const { result } = simnet.callPublicFn("verifychain", "verify-identity", [user2, 1], user1);
      expect(result).toBeErr(100); // err-not-owner
    });

    it("should correctly report verification status", () => {
      const { result } = simnet.callReadOnlyFn("verifychain", "is-verified", [user1], contractOwner);
      expect(result).toBeBool(true);
    });
  });

  describe("Verification Renewal", () => {
    it("should allow a user to renew their verification", () => {
      const { result } = simnet.callPublicFn("verifychain", "renew-verification", [], user1);
      expect(result).toBeOk(true);
    });
  });

  describe("Email Update", () => {
    it("should allow a user to update their email", () => {
      const { result } = simnet.callPublicFn("verifychain", "update-email", ["newalice@example.com"], user1);
      expect(result).toBeOk(true);
    });

    it("should correctly update the email in the identity", () => {
      const { result } = simnet.callReadOnlyFn("verifychain", "get-identity", [user1], contractOwner);
      expect(result.value).toHaveProperty("email", "newalice@example.com");
    });
  });

  describe("Attestations", () => {
    beforeAll(() => {
      // Verify user2 for attestation tests
      simnet.callPublicFn("verifychain", "verify-identity", [user2, 1], contractOwner);
    });

    it("should allow a verified user to make an attestation", () => {
      const { result } = simnet.callPublicFn("verifychain", "make-attestation", [user2], user1);
      expect(result).toBeOk(true);
    });

    it("should allow a user to revoke their attestation", () => {
      const { result } = simnet.callPublicFn("verifychain", "revoke-attestation", [user2], user1);
      expect(result).toBeOk(true);
    });
  });

  describe("Reputation Management", () => {
    it("should allow the contract owner to update reputation", () => {
      const { result } = simnet.callPublicFn("verifychain", "update-reputation", [user1, 5], contractOwner);
      expect(result).toBeOk(true);
    });

    it("should correctly report updated reputation", () => {
      const { result } = simnet.callReadOnlyFn("verifychain", "get-identity", [user1], contractOwner);
      expect(result.value).toHaveProperty("reputation", 5);
    });

    it("should not allow reputation to go below zero", () => {
      simnet.callPublicFn("verifychain", "update-reputation", [user1, -10], contractOwner);
      const { result } = simnet.callReadOnlyFn("verifychain", "get-identity", [user1], contractOwner);
      expect(result.value).toHaveProperty("reputation", 0);
    });
  });

  describe("Dispute Resolution", () => {
    it("should allow a verified user to file a dispute", () => {
      const { result } = simnet.callPublicFn("verifychain", "file-dispute", [user2, "Reason for dispute"], user1);
      expect(result).toBeOk(true);
    });

    it("should allow the contract owner to resolve a dispute", () => {
      const { result } = simnet.callPublicFn("verifychain", "resolve-dispute", [user1, user2], contractOwner);
      expect(result).toBeOk(true);
    });
  });

  describe("Governance", () => {
    it("should allow the contract owner to enable governance", () => {
      const { result } = simnet.callPublicFn("verifychain", "set-governance", [true], contractOwner);
      expect(result).toBeOk(true);
    });

    it("should allow submitting a governance proposal when enabled", () => {
      const { result } = simnet.callPublicFn("verifychain", "submit-governance-proposal", [1, "Test proposal"], user1);
      expect(result).toBeOk(true);
    });

    it("should not allow submitting a governance proposal when disabled", () => {
      simnet.callPublicFn("verifychain", "set-governance", [false], contractOwner);
      const { result } = simnet.callPublicFn("verifychain", "submit-governance-proposal", [2, "Test proposal"], user1);
      expect(result).toBeErr(108); // Governance not enabled
    });
  });
});