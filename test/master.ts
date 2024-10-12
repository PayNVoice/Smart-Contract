import {
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre, { ethers } from "hardhat";

describe("MasterContract", function () {
    async function deployToken(){
        const [owner, otherAccount] = await hre.ethers.getSigners();
        const Token = await hre.ethers.getContractFactory("Token");
        const token = await Token.deploy();
        return { token };
    }

    async function deployMasterContract(){
        const [owner, supplier, customer] = await hre.ethers.getSigners();
        const {token} = await loadFixture(deployToken)

        const MasterContract = await hre.ethers.getContractFactory("MasterContract");
        const masterContract = await MasterContract.deploy(token);

        return { masterContract, token, owner, supplier, customer };
    }

    describe("Business Registration", function () {
        it("Should register a business successfully", async function () {
        const { masterContract, owner } = await loadFixture(deployMasterContract);

        await masterContract.registerBusiness("MyBusiness", "Software");

        const registeredBusiness = await masterContract.registeredBusiness(owner.address);
        expect(registeredBusiness.isRegistered).to.be.true;
        expect(registeredBusiness.businessName).to.equal("MyBusiness");
        expect(registeredBusiness.category).to.equal("Software");
        });
  });
});