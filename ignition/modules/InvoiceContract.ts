import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const tokenAddress = "0x6033F7f88332B8db6ad452B7C6D5bB643990aE3f";


const InvoiceContractModule = buildModule("PayNVoiceModule", (m) => {

    const saveContract = m.contract("PayNVoice", [tokenAddress]);

    return { saveContract };
});

export default InvoiceContractModule;