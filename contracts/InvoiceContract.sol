// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PayNVoice {


    address public invoiceCreator;
    address public erc20TokenAddress;

    struct Invoice{
       address clientAddress;
       uint256 amount;
       uint256 deadline;
       string termsAndConditions;
       string paymentterm;
       bool areConditionsMet;
       bool isPaid;
       bool hasAccepted;
       Milestone[] milestones;
    }
    enum Status{
        pending,
        isCompleted,
        confirmed
    }

    struct Milestone {
        string description;
        uint256 amount;
        Status status;
        bool isPaid;
    }

    constructor(address _erc20TokenAddress){
        if(msg.sender == address(0)){
            revert ADDRESS_ZERO_NOT_PERMITED();
        }
        if(_erc20TokenAddress == address(0)){
            revert ADDRESS_ZERO_NOT_PERMITED();
        }
        invoiceCreator = msg.sender;
        erc20TokenAddress = _erc20TokenAddress;
    }

    error ADDRESS_ZERO_NOT_PERMITED();
    error INVOICE_NOT_GENERATED_YET();
    error YOU_DID_NOT_DEPLOY_THIS_CONTRACT();
    error INVOICE_DOES_NOT_EXIST();
    error NOT_AUTHORIZE_TO_CALL_THIS_FUNCTION();
    error CANT_INITIATE_RELEASE();
    error PAYMENT_HAS_NOT_BEEN_MADE();
    error INVOICE_NOT_FOR_YOU();

    event InvoiceCreatedSuccessfully(address indexed whocreates, address indexed createFor, uint256 amount, uint256 id);
    event InvoiceReturnedSuccessfully(address indexed forwho, uint256 invoiceId);
    event MilestoneAdded(uint256 indexed invoiceId, string description, uint256 amount);
    event MilestoneCompleted(uint256 indexed invoiceId, uint256 milestoneIndex);
    event InvoiceAcceptedSuccessfully(address indexed forWho, uint256 invoiceId);

    mapping(address => mapping(uint256 => Invoice)) public invoices;
    mapping(address => uint256) public invoiceCount;
    uint256 invoiceCounter = 1;

    function createInvoice(address clientAddress, uint256 amount, uint256 deadline, string memory termsAndConditions, string memory paymentTerm) public returns(uint256 invoiceId_) {
        if(msg.sender == address(0)){
            revert ADDRESS_ZERO_NOT_PERMITED();
        }
        if(msg.sender != invoiceCreator){
            revert YOU_DID_NOT_DEPLOY_THIS_CONTRACT();
        }
        invoiceId_ = invoiceCounter;
        Invoice storage _invoice = invoices[invoiceCreator][invoiceId_];
        _invoice.clientAddress = clientAddress;
        _invoice.amount = amount;
        _invoice.deadline = deadline;
        _invoice.termsAndConditions = termsAndConditions;
        _invoice.paymentterm = paymentTerm;
        
        invoices[msg.sender][invoiceId_] = _invoice;
        invoiceCount[msg.sender]++;
        invoiceCounter++;

        emit InvoiceCreatedSuccessfully(msg.sender, clientAddress, amount, invoiceId_);
    }

    function acceptInvoice(uint256 _invoiceId) external{
        if(msg.sender == address(0)){
            revert ADDRESS_ZERO_NOT_PERMITED();
        }
        Invoice storage invoice = invoices[invoiceCreator][_invoiceId];
        if(invoice.clientAddress != msg.sender){
            revert INVOICE_DOES_NOT_EXIST();
        }
        invoice.hasAccepted = true;

        emit InvoiceAcceptedSuccessfully(msg.sender, _invoiceId);
    }


    function depositToEscrow(uint256 invoiceId) external payable {
        Invoice storage invoice = invoices[invoiceCreator][invoiceId];
        if(invoice.clientAddress != msg.sender){
            revert INVOICE_NOT_FOR_YOU();
        }
        
        uint256 userTokenBal = IERC20(erc20TokenAddress).balanceOf(msg.sender);
        require(userTokenBal >= invoices[invoiceCreator][invoiceId].amount, "Insufficient balance");
        invoices[invoiceCreator][invoiceId].isPaid = true;
        
        IERC20(erc20TokenAddress).transferFrom(msg.sender, address(this), invoices[invoiceCreator][invoiceId].amount);
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
            status: Status.pending,
            isPaid: false
        }));
        emit MilestoneAdded(_invoiceId, _description, _amount);
    }

    function markMilestoneCompleted(uint256 _invoiceId, uint256 _milestoneIndex) public {
        
        Invoice storage invoice = invoices[invoiceCreator][_invoiceId];
        require(_milestoneIndex < invoice.milestones.length, "Invalid milestone index");

        Milestone storage milestone = invoice.milestones[_milestoneIndex];
        milestone.status = Status.isCompleted;

        emit MilestoneCompleted(_invoiceId, _milestoneIndex);
    }

    function getMilestones(uint256 invoiceId) external view returns (Milestone[] memory) {
        return invoices[invoiceCreator][invoiceId].milestones;
    }

    function getInvoiceCount(address user) private view returns (uint256) {
        return invoiceCount[user];
    }

    function generateAllInvoice() external view returns (Invoice[] memory) {
        if(msg.sender == address(0)){
            revert ADDRESS_ZERO_NOT_PERMITED();
        } 
        Invoice[] memory inv;
        if(msg.sender == invoiceCreator){
            uint256 invoiceCounting = getInvoiceCount(msg.sender);
            if(invoiceCounter < 1){
                revert INVOICE_NOT_GENERATED_YET();
            }
            inv = returnHelperInvoices(invoiceCounting);
        } else {
            
            uint256 invoiceCount2 = getInvoiceCount(invoiceCreator);
            if(invoiceCount2 < 1){
                revert INVOICE_NOT_GENERATED_YET();
            }
            inv = returnHelperInvoices(invoiceCount2);
        }
        return inv;
    }

    function returnHelperInvoices(uint256 invoiceCou) private view returns(Invoice[] memory){
        Invoice[] memory invoiceList = new Invoice[](invoiceCou);
            for(uint256 count = 1; count<=invoiceCou; count++){
                invoiceList[count - 1] = invoices[msg.sender][count];
            }
            return invoiceList;
    }

    /*Client get a particular invoice*/
    function getInvoice(uint256 invoiceId) external returns (Invoice memory invoice1_) {
        if(msg.sender == address(0)){
            revert ADDRESS_ZERO_NOT_PERMITED();
        }
        invoice1_ = invoices[invoiceCreator][invoiceId];

        emit InvoiceReturnedSuccessfully(msg.sender, invoiceId);

    }

    // get all invoices for a particular client
    function getInvoicesForClient(address client) external view returns (Invoice[] memory){
        uint256 count = 0;
        for (uint256 i = 1; i <= invoiceCounter; i++) {
            if (invoices[invoiceCreator][i].clientAddress == client) {
                count++;
            }
        }

        Invoice[] memory clientInvoices = new Invoice[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= invoiceCounter; i++) {
            if (invoices[invoiceCreator][i].clientAddress == client) {
                clientInvoices[index] = invoices[invoiceCreator][i];
                index++;
            }
        }

        return clientInvoices;
}

// the person who deposited into our escrow is doing this
function releasePayment(uint256 invoiceId) external {
    if(msg.sender == address(0)){
        revert ADDRESS_ZERO_NOT_PERMITED();
    }

    Invoice storage invoice = invoices[invoiceCreator][invoiceId];

    if(msg.sender != invoice.clientAddress){
        revert NOT_AUTHORIZE_TO_CALL_THIS_FUNCTION();
    }
    if(invoice.amount == 0){
        revert CANT_INITIATE_RELEASE();
    }
    if(invoice.isPaid == false){
        revert PAYMENT_HAS_NOT_BEEN_MADE();
    }
     
    IERC20(erc20TokenAddress).transfer(invoices[invoiceCreator][invoiceId].clientAddress, invoices[invoiceCreator][invoiceId].amount);
    
    delete invoices[invoiceCreator][invoiceId];
}


}