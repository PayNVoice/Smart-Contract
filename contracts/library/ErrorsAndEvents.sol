// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
library CustomErrors{
    error ADDRESS_ZERO_NOT_PERMITED();
    error INVOICE_NOT_GENERATED_YET();
    error YOU_DID_NOT_DEPLOY_THIS_CONTRACT();
    error INVOICE_DOES_NOT_EXIST();
    error NOT_AUTHORIZE_TO_CALL_THIS_FUNCTION();
    error CANT_INITIATE_RELEASE();
    error PAYMENT_HAS_BEEN_MADE();
    error INVOICE_NOT_FOR_YOU();
}

library Events{
        event InvoiceCreatedSuccessfully(address indexed whocreates, address indexed createFor, uint256 amount, uint256 indexed id);
    event InvoiceReturnedSuccessfully(address indexed forwho, uint256 indexed invoiceId);
    event MilestoneAdded(uint256 indexed invoiceId, string indexed description, uint256 indexed amount);
    event MilestoneCompleted(uint256 indexed invoiceId, uint256 indexed milestoneIndex);
    event InvoiceAcceptedSuccessfully(address indexed forWho, uint256 indexed invoiceId);
}