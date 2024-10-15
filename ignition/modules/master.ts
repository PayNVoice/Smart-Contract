import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const tokenAddress = "0xBB668f3553d2F75AF0Ad14F74838128e27b3B100";


const PayNVoiceModule = buildModule("PayNVoiceModule", (m) => {

    const saveContract = m.contract("PayNVoice", [tokenAddress]);

    return { saveContract };
});

export default PayNVoiceModule;

// TokenModule#Token - 0xBB668f3553d2F75AF0Ad14F74838128e27b3B100
// MasterContractModule#MasterContract - 0x55aC224619eCEfAF755ed7d047Da6a6A6BcAe560