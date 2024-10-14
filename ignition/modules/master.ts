import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const tokenAddress = "0xBB668f3553d2F75AF0Ad14F74838128e27b3B100";


const MasterContractModule = buildModule("MasterContractModule", (m) => {

    const saveContract = m.contract("MasterContract", [tokenAddress]);

    return { saveContract };
});

export default MasterContractModule;

// TokenModule#Token - 0xBB668f3553d2F75AF0Ad14F74838128e27b3B100
// MasterContractModule#MasterContract - 0x55aC224619eCEfAF755ed7d047Da6a6A6BcAe560