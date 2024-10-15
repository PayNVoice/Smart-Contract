// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const PayNVoiceModule = buildModule("PayNVoiceModule", (m) => {

  const payNvoice = m.contract("PayNVoice");

  return { payNvoice };
});

export default PayNVoiceModule;
