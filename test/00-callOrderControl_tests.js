const { assert, expect } = require("chai");
const { ethers, getNamedAccounts } = require("hardhat");

function getSelector(functionSignature) {
  const hash = ethers.utils.solidityKeccak256(["string"], [functionSignature]);
  return hash.substring(0, 10);
}

describe("CallOrderControl.sol tests", function () {
  let deployer,
    client1,
    client2,
    callOrderControlContract,
    allowedCallsEventFilter,
    useCaseContract,
    useCaseContractClient1,
    funcSelec1,
    funcSelec2;

  beforeEach(async function () {
    const {
      deployer: dep,
      client1: c1,
      client2: c2,
    } = await getNamedAccounts();
    deployer = dep;
    client1 = c1;
    client2 = c2;
    callOrderControlContract = await ethers.getContract("CallOrderControl");
    allowedCallsEventFilter = await callOrderControlContract.filters
      .CallOrderControl__AllowedFuncCallsGranted;
    funcSelec1 = "changeData(uint256)";
    funcSelec2 = "incrementData(uint256)";
    funcSelec1 = getSelector(funcSelec1);
    funcSelec2 = getSelector(funcSelec2);
  });

  describe("Tests when calls must be called in a sequence.", function () {
    describe("Internal functionalities tests.", function () {
      it("Allowed call is stored and accessed correctly and isSequence is updated correctly.", async () => {
        // Values for functions are stored correctly and event is emitted.
        let txResponse = await callOrderControlContract.callAllowFuncCallsFor(
          client1,
          [funcSelec1],
          true
        );
        let txReceipt = await txResponse.wait();
        let txBlock = txReceipt.blockNumber;
        let query = await callOrderControlContract.queryFilter(
          allowedCallsEventFilter,
          txBlock
        );

        let validCallsEmitted = query[0].args[1][0];
        assert.equal(validCallsEmitted, funcSelec1);

        let allowedCalls = await callOrderControlContract.getAllowedFuncCalls(
          client1
        );
        assert.equal(allowedCalls[0], funcSelec1);

        let sequence = await callOrderControlContract.getIsSequence(client1);
        assert.equal(sequence, true);

        // Same values for same function but different client are stored correctly.
        await callOrderControlContract.callAllowFuncCallsFor(
          client2,
          [funcSelec1],
          true
        );

        allowedCalls = await callOrderControlContract.getAllowedFuncCalls(
          client2
        );
        assert.equal(allowedCalls[0], funcSelec1);
      });

      it("When allowing multiple calls with Calls' sequence, array stored and accessed correctly.", async () => {
        await callOrderControlContract.callAllowFuncCallsFor(
          client1,
          [funcSelec1, funcSelec2],
          true
        );

        let allowedCalls = await callOrderControlContract.getAllowedFuncCalls(
          client1
        );
        assert.equal(allowedCalls[0], funcSelec1);
        assert.equal(allowedCalls[1], funcSelec2);
      });
    });

    describe("CallOrderControl functionalities implemented in other contract tests.", function () {
      beforeEach(async function () {
        useCaseContract = await ethers.getContract("UseCaseContract", deployer);
        useCaseContractClient1 = await ethers.getContract(
          "UseCaseContract",
          client1
        );
      });

      it("Using CallOrderControl in other contract.", async () => {
        // Permission not given yet, must revert.
        await expect(
          useCaseContractClient1.changeData(1)
        ).revertedWithCustomError(
          useCaseContractClient1,
          "CallOrderControl__NotAllowedCall"
        );

        await useCaseContract.callAllowFuncCallsFor(
          client1,
          [funcSelec1, funcSelec2, funcSelec1],
          true
        );

        // Permission given but calling in different order, must revert.
        await expect(
          useCaseContractClient1.incrementData(1)
        ).revertedWithCustomError(
          useCaseContractClient1,
          "CallOrderControl__NotAllowedCall"
        );

        // Calling in correct order, should execute correctly.
        await useCaseContractClient1.changeData(1);
        let number = await useCaseContractClient1.getNumber();
        assert.equal(1, number);

        await useCaseContractClient1.incrementData(1);
        number = await useCaseContractClient1.getNumber();
        assert.equal(2, number);

        await useCaseContractClient1.changeData(1);
        number = await useCaseContractClient1.getNumber();
        assert.equal(1, number);

        // After calling correctly, if calling again must revert.
        await expect(
          useCaseContractClient1.changeData(1)
        ).revertedWithCustomError(
          useCaseContractClient1,
          "CallOrderControl__NotAllowedCall"
        );

        await expect(
          useCaseContractClient1.incrementData(1)
        ).revertedWithCustomError(
          useCaseContractClient1,
          "CallOrderControl__NotAllowedCall"
        );

        await expect(
          useCaseContractClient1.changeData(1)
        ).revertedWithCustomError(
          useCaseContractClient1,
          "CallOrderControl__NotAllowedCall"
        );
      });
    });
  });

  describe("Tests when Calls can be called in any order.", function () {
    describe("Internal functionalities tests.", function () {
      it("Allowed call is stored and accessed correctly and isSequence is updated correctly.", async () => {
        // Values for functions are stored correctly and event is emitted.
        let txResponse = await callOrderControlContract.callAllowFuncCallsFor(
          client1,
          [funcSelec1],
          false
        );
        let txReceipt = await txResponse.wait();
        let txBlock = txReceipt.blockNumber;
        let query = await callOrderControlContract.queryFilter(
          allowedCallsEventFilter,
          txBlock
        );

        let validCallsEmitted = query[0].args[1][0];
        assert.equal(validCallsEmitted, funcSelec1);

        let allowedCalls = await callOrderControlContract.getAllowedFuncCalls(
          client1
        );
        assert.equal(allowedCalls[0], funcSelec1);

        let sequence = await callOrderControlContract.getIsSequence(client1);
        assert.equal(sequence, false);

        // Same values for same function but different client are stored correctly.
        await callOrderControlContract.callAllowFuncCallsFor(
          client2,
          [funcSelec1],
          false
        );

        allowedCalls = await callOrderControlContract.getAllowedFuncCalls(
          client2
        );
        assert.equal(allowedCalls[0], funcSelec1);
      });
    });

    describe("CallOrderControl functionalities implemented in other contract tests.", function () {
      beforeEach(async function () {
        useCaseContract = await ethers.getContract("UseCaseContract", deployer);
        useCaseContractClient1 = await ethers.getContract(
          "UseCaseContract",
          client1
        );
      });

      it("Using CallOrderControl in other contract.", async () => {
        // Permission not given yet, must revert.
        await expect(
          useCaseContractClient1.changeData(1)
        ).revertedWithCustomError(
          useCaseContractClient1,
          "CallOrderControl__NotAllowedCall"
        );

        await useCaseContract.callAllowFuncCallsFor(
          client1,
          [funcSelec1, funcSelec2, funcSelec1],
          false
        );

        // Permission given, should not revert.
        await useCaseContractClient1.changeData(1);
        let number = await useCaseContractClient1.getNumber();
        assert.equal(1, number);

        await useCaseContractClient1.incrementData(1);
        number = await useCaseContractClient1.getNumber();
        assert.equal(2, number);

        await useCaseContractClient1.changeData(1);
        number = await useCaseContractClient1.getNumber();
        assert.equal(1, number);

        // Calls already used, must revert.
        await expect(
          useCaseContractClient1.changeData(1)
        ).revertedWithCustomError(
          useCaseContractClient1,
          "CallOrderControl__NotAllowedCall"
        );

        await expect(
          useCaseContractClient1.incrementData(1)
        ).revertedWithCustomError(
          useCaseContractClient1,
          "CallOrderControl__NotAllowedCall"
        );

        await expect(
          useCaseContractClient1.changeData(1)
        ).revertedWithCustomError(
          useCaseContractClient1,
          "CallOrderControl__NotAllowedCall"
        );
      });

      it("Correct funcToCallsLeft mapping reset.", async () => {
        await useCaseContract.callAllowFuncCallsFor(
          client1,
          [funcSelec1, funcSelec2, funcSelec1],
          false
        );

        // Permission given, should not revert.
        await useCaseContractClient1.changeData(1);
        let number = await useCaseContractClient1.getNumber();
        assert.equal(1, number);

        await useCaseContractClient1.incrementData(1);
        number = await useCaseContractClient1.getNumber();
        assert.equal(2, number);

        // Client didn't use all calls but we are giving new ones,
        // should overwrite.
        await useCaseContract.callAllowFuncCallsFor(
          client1,
          [funcSelec1, funcSelec2, funcSelec1],
          false
        );

        await useCaseContractClient1.changeData(1);
        number = await useCaseContractClient1.getNumber();
        assert.equal(1, number);

        await useCaseContractClient1.changeData(1);
        number = await useCaseContractClient1.getNumber();
        assert.equal(1, number);

        // As overwritten, even before we had 1 call left,
        // only 2 calls should be allowed.
        await expect(
          useCaseContractClient1.changeData(1)
        ).revertedWithCustomError(
          useCaseContractClient1,
          "CallOrderControl__NotAllowedCall"
        );

        await useCaseContractClient1.incrementData(1);
        number = await useCaseContractClient1.getNumber();
        assert.equal(2, number);

        await expect(
          useCaseContractClient1.incrementData(1)
        ).revertedWithCustomError(
          useCaseContractClient1,
          "CallOrderControl__NotAllowedCall"
        );
      });
    });
  });
});
