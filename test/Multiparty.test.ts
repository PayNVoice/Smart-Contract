import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";
import { Contract, Signer} from "ethers";

describe("Multiparty", function(){
  let owner: Signer;
  let addr1: Signer; 
  let addr2: Signer;

  let multiparty: Contract;

  beforeEach(async function(){
    const MultipartyContract = await hre.ethers.getContractFactory("Multiparty");
    [owner, addr1, addr2] = await hre.ethers.getSigners();
    multiparty = await MultipartyContract.deploy();
    console.log("Multipart deployed::: ",multiparty);
  })

  it("Should set the correct creator on deployment", async function () {
    expect(await multiparty.multipartyCreator()).to.equal(owner.address);
  });

})