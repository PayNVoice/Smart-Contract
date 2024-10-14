// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PayNVoice {
    address public invoiceCreator;

    struct Milestone {
        string description;
        uint256 amount;
        bool isCompleted;
        bool isPaid;
    }

    struct Invoice {
        address clientAddress;
        uint256 amount;
        uint256 deadline;
        string termsAndConditions;
        string paymentTerm;
        bool areConditionsMet;
        bool isPaid;
        Milestone[] milestones;
    }

    error ADDRESS_ZERO_NOT_PERMITTED();
    error INVOICE_NOT_GENERATED_YET();
    error YOU_DID_NOT_DEPLOY_THIS_CONTRACT();

    event InvoiceCreatedSuccessfully(address indexed creator, address indexed client, uint256 amount, uint256 id);
    event MilestoneAdded(uint256 indexed invoiceId, string description, uint256 amount);
    event MilestoneCompleted(uint256 indexed invoiceId, uint256 milestoneIndex);
    event InvoiceReturnedSuccessfully(address indexed client, uint256 invoiceId);

    address public erc20TokenAddress = 0x6033F7f88332B8db6ad452B7C6D5bB643990aE3f;
    mapping(address => mapping(uint256 => Invoice)) public invoices;
    mapping(address => uint256) public invoiceCount;
    uint256 public invoiceCounter = 1;

    constructor() {
        if (msg.sender == address(0)) {
            revert ADDRESS_ZERO_NOT_PERMITTED();
        }
        invoiceCreator = msg.sender;
    }

    function createInvoice(
        address clientAddress,
        uint256 amount,
        uint256 deadline,
        string memory termsAndConditions,
        string memory paymentTerm
    ) public returns (uint256 invoiceId_) {
        if (msg.sender == address(0)) {
            revert ADDRESS_ZERO_NOT_PERMITTED();
        }
        if (msg.sender != invoiceCreator) {
            revert YOU_DID_NOT_DEPLOY_THIS_CONTRACT();
        }

        invoiceId_ = invoiceCounter;
        Invoice storage _invoice = invoices[invoiceCreator][invoiceId_];
        _invoice.clientAddress = clientAddress;
        _invoice.amount = amount;
        _invoice.deadline = deadline;
        _invoice.termsAndConditions = termsAndConditions;
        _invoice.paymentTerm = paymentTerm;

        invoices[msg.sender][invoiceId_] = _invoice;
        invoiceCount[msg.sender]++;
        invoiceCounter += 1;

        emit InvoiceCreatedSuccessfully(msg.sender, clientAddress, amount, invoiceId_);
    }

    function addMilestone(
        uint256 _invoiceId,
        string memory _description,
        uint256 _amount
    ) public {
        Invoice storage invoice = invoices[invoiceCreator][_invoiceId];
        invoice.milestones.push(Milestone({
            description: _description,
            amount: _amount,
            isCompleted: false,
            isPaid: false
        }));
        emit MilestoneAdded(_invoiceId, _description, _amount);
    }

    function markMilestoneCompleted(uint256 _invoiceId, uint256 _milestoneIndex) public {
        Invoice storage invoice = invoices[invoiceCreator][_invoiceId];
        require(_milestoneIndex < invoice.milestones.length, "Invalid milestone index");

        Milestone storage milestone = invoice.milestones[_milestoneIndex];
        milestone.isCompleted = true;

        emit MilestoneCompleted(_invoiceId, _milestoneIndex);
    }

    function getInvoice(uint256 invoiceId) external returns (Invoice memory invoice_) {
        if (msg.sender == address(0)) {
            revert ADDRESS_ZERO_NOT_PERMITTED();
        }
        invoice_ = invoices[invoiceCreator][invoiceId];
        emit InvoiceReturnedSuccessfully(msg.sender, invoiceId);
    }

    function getMilestones(uint256 invoiceId) external view returns (Milestone[] memory) {
        return invoices[invoiceCreator][invoiceId].milestones;
    }

    // Add additional functions for payment release and other operations as needed
}
