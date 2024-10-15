
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import ".InvoiceContract.sol";

contract PayNVoiceFactory {

    PayNVoice[] invoiceClones;

    function createInvoice() external returns (PayNVoice newInvoice_, uint256 length_) {

        newInvoice_ = new PayNVoice();

        invoiceClones.push(newInvoice_);

        length_ = invoiceClones.length;
    }

    function getInvoiceClones() external view returns(PayNVoice[] memory) {
        return invoiceClones;
    }

     function getANInvoiceClone(uint _index) external view returns (PayNVoice) {
        return invoiceClones[_index];
    }
}




