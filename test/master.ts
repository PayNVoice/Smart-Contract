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

   describe("Agreement Creation", function () {
        it("Should create an agreement successfully", async function () {
            const { masterContract, supplier, customer } = await loadFixture(deployMasterContract);

            const milestoneDescriptions = ["Design", "Development", "Testing"];
            const milestoneAmounts = [ethers.parseUnits("100", 18), ethers.parseUnits("200", 18), ethers.parseUnits("150", 18)];
            const deadline = Math.floor(Date.now() / 1000) + 86400; // 24 hours from now
            const totalAmount = milestoneAmounts.reduce((acc, val) => acc + Number(ethers.formatUnits(val, 18)), 0);

            // Register the customer as a business
            await masterContract.connect(customer).registerBusiness("My Business", "Tech");

            await masterContract.connect(customer).createAgreement(
            supplier.address,
            customer.address,
            totalAmount, 
            milestoneDescriptions,
            deadline,
            milestoneAmounts,
            "Standard Terms"
            );

            const agreement = await masterContract.agreements(1); // Agreement ID 1
            expect(agreement.supplier).to.equal(supplier.address);
            expect(agreement.customer).to.equal(customer.address);
            expect(agreement.totalAmount).to.equal(totalAmount);
            expect(agreement.deadline).to.equal(deadline);
        });
   });

   


});