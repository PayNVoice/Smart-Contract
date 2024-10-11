// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract InvoiceContract is Ownable {
    struct Invoice {
        uint256 agreementId;
        uint256 milestoneIndex;
        string details;
        uint256 amount;
        bool isPaid;
        address payable supplier;
        address payable customer;
        uint256 createdAt;
    }

    mapping(uint256 => Invoice) public invoices; // Invoice ID => Invoice
    uint256 public invoiceCounter;

    event InvoiceCreated(uint256 invoiceId, uint256 agreementId, uint256 milestoneIndex, string details, uint256 amount, address supplier, address customer);
    event InvoicePaid(uint256 invoiceId);

    constructor() {
        invoiceCounter = 1;
    }

    // Create a new invoice
    function createInvoice(
        uint256 _agreementId,
        uint256 _milestoneIndex,
        string memory _details,
        uint256 _amount,
        address payable _supplier,
        address payable _customer
    ) external onlyOwner returns (uint256 invoiceId) {
        Invoice storage newInvoice = invoices[invoiceCounter];
        newInvoice.agreementId = _agreementId;
        newInvoice.milestoneIndex = _milestoneIndex;
        newInvoice.details = _details;
        newInvoice.amount = _amount;
        newInvoice.isPaid = false;
        newInvoice.supplier = _supplier;
        newInvoice.customer = _customer;
        newInvoice.createdAt = block.timestamp;

        emit InvoiceCreated(invoiceCounter, _agreementId, _milestoneIndex, _details, _amount, _supplier, _customer);
        return invoiceCounter++;
    }

    // Pay an invoice
    function payInvoice(uint256 _invoiceId) external payable {
        Invoice storage invoice = invoices[_invoiceId];
        require(!invoice.isPaid, "Invoice already paid");
        require(msg.sender == invoice.customer, "Only the customer can pay the invoice");
        require(msg.value == invoice.amount, "Incorrect amount sent");

        invoice.supplier.transfer(msg.value);
        invoice.isPaid = true;

        emit InvoicePaid(_invoiceId);
    }

    // Check if an invoice is paid
    function isInvoicePaid(uint256 _invoiceId) external view returns (bool) {
        return invoices[_invoiceId].isPaid;
    }
}
