const {
  expectRevert, // Assertions for transactions that should fail
} = require("@openzeppelin/test-helpers");
const DeedRepository = artifacts.require("DeedRepository");
const userAddress = "0x0B79C244E5EB2ab662853D4d05F4b31D04699a4B".toLowerCase();
const tokenURI =
  "ipfs://bafybeict2kq6gt4ikgulypt7h7nwj4hmfi2kevrqvnx2osibfulyy5x3hu/no-time-to-explain.jpeg";

contract("DeedRepository", function (accounts) {
  // check if deployment goes smooth
  describe("deployment", () => {
    // check if the smart contract is deployed
    // by checking the address of the smart contract
    it("deploys successfully", async () => {
      let deedRepository = await DeedRepository.deployed();
      const address = await deedRepository.address;

      assert.notEqual(address, "");
      assert.notEqual(address, undefined);
      assert.notEqual(address, null);
      assert.notEqual(address, 0x0);
    });
  });

  // Inputs
  describe("When the user mint a deed", () => {
    it("Should trigger Transfer event when NFT is minted to the user", async () => {
      let deedRepository = await DeedRepository.deployed();
      const tx = await deedRepository.registerDeed("2", tokenURI);
      const { logs } = tx;
      const log = logs[0];
      assert.equal(log.event, "Transfer");
      assert.equal(log.args[1], accounts[0]);
      assert.equal(log.args[2], "2");
    });
  });

  describe("When the user register a deed", () => {
    it("Should have the DeedRegistered event triggered ", async () => {
      let deedRepository = await DeedRepository.deployed();
      const tx = await deedRepository.registerDeed("1", tokenURI);
      const { logs } = tx;
      const log = logs[1];
      assert.equal(log.event, "DeedRegistered");
      assert.equal(log.args[0], accounts[0]);
      assert.equal(log.args[1], "1");
    });
  });
});
