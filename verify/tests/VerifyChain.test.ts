import { describe, expect, it, beforeAll } from "vitest";

const accounts = simnet.getAccounts();
const contractOwner = accounts.get("deployer")!;
const user1 = accounts.get("wallet_1")!;
const user2 = accounts.get("wallet_2")!;
const user3 = accounts.get("wallet_3")!;

describe("VerifyChain Tests", () => {
  beforeAll(() => {
    // Deploy the contract if it's not already deployed
    simnet.deployContract("verifychain", "verifychain", contractOwner);
  });

  describe("Identity Registration", () => {
    it("should allow a user to register an identity", () => {
      const { result } = simnet.callPublicFn("verifychain", "register-identity", ["Alice", "alice@example.com"], user1);
      expect(result).toBeOk(true);
    });

    it("should not allow duplicate registration", () => {
      simnet.callPublicFn("verifychain", "register-identity", ["Bob", "bob@example.com"], user2);
      const { result } = simnet.callPublicFn("verifychain", "register-identity", ["Bob", "bob@example.com"], user2);
      expect(result).toBeErr(101); // err-already-registered
    });

    it("should increase the identity count after registration", () => {
      const { result } = simnet.callReadOnlyFn("verifychain", "get-identity-count", [], contractOwner);
      expect(result).toBeUint(2); // Assuming 2 successful registrations so far
    });
  });

  describe("Identity Verification", () => {
    it("should allow the contract owner to verify an identity", () => {
      const { result } = simnet.callPublicFn("verifychain", "verify-identity", [user1], contractOwner);
      expect(result).toBeOk(true);
    });

    it("should not allow non-owners to verify an identity", () => {
      const { result } = simnet.callPublicFn("verifychain", "verify-identity", [user2], user1);
      expect(result).toBeErr(100); // err-not-owner
    });

    it("should correctly report verification status", () => {
      const { result } = simnet.callReadOnlyFn("verifychain", "is-verified", [user1], contractOwner);
      expect(result).toBeBool(true);
    });

    it("should not allow verifying an already verified identity", () => {
      const { result } = simnet.callPublicFn("verifychain", "verify-identity", [user1], contractOwner);
      expect(result).toBeErr(103); // err-already-verified
    });
  });

  describe("Identity Revocation", () => {
    it("should allow the contract owner to revoke a verified identity", () => {
      const { result } = simnet.callPublicFn("verifychain", "revoke-identity", [user1], contractOwner);
      expect(result).toBeOk(true);
    });

    it("should correctly update verification status after revocation", () => {
      const { result } = simnet.callReadOnlyFn("verifychain", "is-verified", [user1], contractOwner);
      expect(result).toBeBool(false);
    });

    it("should not allow non-owners to revoke an identity", () => {
      const { result } = simnet.callPublicFn("verifychain", "revoke-identity", [user2], user1);
      expect(result).toBeErr(100); // err-not-owner
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

  describe("Identity Attributes", () => {
    it("should allow a user to set a custom attribute", () => {
      const { result } = simnet.callPublicFn("verifychain", "set-identity-attribute", ["country", "USA"], user1);
      expect(result).toBeOk(true);
    });

    it("should correctly retrieve a set attribute", () => {
      const { result } = simnet.callReadOnlyFn("verifychain", "get-identity-attribute", [user1, "country"], contractOwner);
      expect(result.value).toHaveProperty("value", "USA");
    });
  });

  describe("Attestations", () => {
    beforeAll(() => {
      // Verify user1 and user2 for attestation tests
      simnet.callPublicFn("verifychain", "verify-identity", [user1], contractOwner);
      simnet.callPublicFn("verifychain", "verify-identity", [user2], contractOwner);
    });

    it("should allow a verified user to make an attestation", () => {
      const { result } = simnet.callPublicFn("verifychain", "make-attestation", [user2], user1);
      expect(result).toBeOk(true);
    });

    it("should correctly report a valid attestation", () => {
      const { result } = simnet.callReadOnlyFn("verifychain", "is-attestation-valid", [user1, user2], contractOwner);
      expect(result).toBeBool(true);
    });

    it("should allow a user to revoke their attestation", () => {
      const { result } = simnet.callPublicFn("verifychain", "revoke-attestation", [user2], user1);
      expect(result).toBeOk(true);
    });

    it("should correctly report a revoked attestation as invalid", () => {
      const { result } = simnet.callReadOnlyFn("verifychain", "is-attestation-valid", [user1, user2], contractOwner);
      expect(result).toBeBool(false);
    });
  });

  describe("Reputation Management", () => {
    it("should allow the contract owner to update reputation", () => {
      const { result } = simnet.callPublicFn("verifychain", "update-reputation", [user1, 5], contractOwner);
      expect(result).toBeOk(true);
    });

    it("should correctly report updated reputation", () => {
      const { result } = simnet.callReadOnlyFn("verifychain", "get-reputation", [user1], contractOwner);
      expect(result).toBeUint(5);
    });

    it("should not allow reputation to go below zero", () => {
      simnet.callPublicFn("verifychain", "update-reputation", [user1, -10], contractOwner);
      const { result } = simnet.callReadOnlyFn("verifychain", "get-reputation", [user1], contractOwner);
      expect(result).toBeUint(0);
    });

    it("should not allow non-owners to update reputation", () => {
      const { result } = simnet.callPublicFn("verifychain", "update-reputation", [user2, 1], user1);
      expect(result).toBeErr(100); // err-not-owner
    });
  });
});