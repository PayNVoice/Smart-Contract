import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { Contract, Signer} from "ethers";
import { Multiparty, Multiparty__factory } from "../typechain-types";

describe("Multiparty", function(){

  async function deployGlobal(){
    const MultipartyContract = await hre.ethers.getContractFactory("Multiparty");
    const [owner, addr1, addr2] = await hre.ethers.getSigners();
    const multiparty = await MultipartyContract.deploy();
    await multiparty.waitForDeployment();
    console.log("Multiparty deployed::: ",multiparty);

    return { owner, addr1, addr2, multiparty }
  }

  describe("Interaction with MultiParty by Who initiates transaction", function(){
    
    it("Should set the correct creator on deployment", async function () {
      const { owner, addr1, addr2, multiparty } = await loadFixture(deployGlobal);
      expect(await multiparty.multipartyCreator()).to.equal(owner.address);
    });

    it("Should test for the creation", async function(){
      const { owner, addr1, addr2, multiparty } = await loadFixture(deployGlobal);

      const partyMem = [addr1.address, addr2.address];
      const amount1 = hre.ethers.parseEther("0.05");
      const amount2 = hre.ethers.parseEther("0.5");

      const totalAmountAllocated = [amount1, amount2]
      multiparty.createMultiPartySystem(
        //@ts-ignore
        partyMem,
        totalAmountAllocated,
      )
    })

  })
})

