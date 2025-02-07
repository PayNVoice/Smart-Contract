// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CustomErrors, Events} from "./library/ErrorsAndEvents.sol";

// contract Multiparty {

contract PayNVoice {
    address public invoiceCreator;
    address public erc20TokenAddress;

    struct Invoice{
       address clientAddress;
       uint256 amount;
       uint256 deadline;
       string title;
       string termsAndConditions;
       string paymentterm;
       bool areConditionsMet;
       bool isPaid;
       bool hasAccepted;
       Milestone[] milestones;
       uint256 lateFeeRate;
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
        uint256 deadline;
    }

    constructor(address _erc20TokenAddress){
        if(msg.sender == address(0)){
            revert CustomErrors.ADDRESS_ZERO_NOT_PERMITED();
        }
        if(_erc20TokenAddress == address(0)){
            revert CustomErrors.ADDRESS_ZERO_NOT_PERMITED();
        }
    
        erc20TokenAddress = _erc20TokenAddress;
    }





    mapping(address => mapping(uint256 => Invoice)) public invoices;
    mapping(address => uint256) public invoiceCount;
    uint256 invoiceCounter;

    function addMilestone(
        uint256 _invoiceId,
        string memory _description,
        uint256 _amount,
        uint256 _deadline
    ) public {
        Invoice storage invoice = invoices[msg.sender][_invoiceId];
        invoice.milestones.push(Milestone({
            description: _description,
            amount: _amount,
            status: Status.pending,
            isPaid: false,
            deadline: _deadline
        }));
        emit Events.MilestoneAdded(_invoiceId, _description, _amount);
    }

    function markMilestoneCompleted(uint256 _invoiceId, uint256 _milestoneIndex) public {   
        Invoice storage invoice = invoices[msg.sender][_invoiceId];
        require(_milestoneIndex < invoice.milestones.length, "Invalid milestone index");

        Milestone storage milestone = invoice.milestones[_milestoneIndex];
        milestone.status = Status.isCompleted;

        emit Events.MilestoneCompleted(_invoiceId, _milestoneIndex);
    }


    function createInvoice(address clientAddress, uint256 amount, uint256 deadline, string memory termsAndConditions, string memory paymentTerm, string memory title) public returns(uint256 invoiceId_) {
        if(msg.sender == address(0)){
            revert CustomErrors.ADDRESS_ZERO_NOT_PERMITED();
        }

        if(clientAddress == msg.sender){

            revert CustomErrors.INVALID_ADDRESS();
        }

        require(clientAddress != msg.sender, "NO" );
        
        invoiceId_ = invoiceCounter + 1;
        
        Invoice storage _invoice = invoices[msg.sender][invoiceId_];
        _invoice.clientAddress = clientAddress;
        _invoice.amount = amount;
        _invoice.deadline = deadline;
        _invoice.termsAndConditions = termsAndConditions;
        _invoice.paymentterm = paymentTerm;
        _invoice.title =title;
        invoiceCreator = msg.sender;
        
        invoices[invoiceCreator][invoiceId_] = _invoice;
        invoiceCount[invoiceCreator]++;
        invoiceCounter++;

        emit Events.InvoiceCreatedSuccessfully(invoiceCreator, clientAddress, amount, invoiceId_);
    }

    function acceptInvoice(uint256 _invoiceId) external{
        if(msg.sender == address(0)){
            revert CustomErrors.ADDRESS_ZERO_NOT_PERMITED();
        }
        Invoice storage invoice = invoices[invoiceCreator][_invoiceId];
        if(invoice.clientAddress != msg.sender){
            revert CustomErrors.INVOICE_DOES_NOT_EXIST();
        }
        invoice.hasAccepted = true;

        emit Events.InvoiceAcceptedSuccessfully(msg.sender, _invoiceId);
    }

    // Add Late Fee Penalty Calculation
    function calculateLateFee(uint256 invoiceId) public view returns (uint256) {
        Invoice storage invoice = invoices[msg.sender][invoiceId];
        if (block.timestamp > invoice.deadline) {
            uint256 daysLate = (block.timestamp - invoice.deadline) / (24*60*60);
            uint256 lateFee = (invoice.amount * invoice.lateFeeRate * daysLate) / 100;
            return lateFee;
        } else {
            return 0;
        }
    }

     // Add Late Fee Penalty Calculation on Supplier
    function calculateLateFeeForSupplier(uint256 invoiceId, uint256 milestoneIndex) public view returns (uint256) {

        Invoice storage invoice = invoices[msg.sender][invoiceId];
        require(milestoneIndex < invoice.milestones.length, "Invalid milestone index");

        Milestone storage milestone = invoice.milestones[milestoneIndex]; 

        if (block.timestamp > milestone.deadline) {
            uint256 daysLate = (block.timestamp - invoice.deadline) / (24*60*60);
            uint256 lateFee = (invoice.amount * invoice.lateFeeRate * daysLate) / 100;
            return lateFee;
        } else {
            return 0;
        }
    }


    function depositToEscrow(uint256 invoiceId) external payable {

        Invoice storage invoice = invoices[msg.sender][invoiceId];
        if(invoice.clientAddress != msg.sender){
            revert CustomErrors.INVOICE_NOT_FOR_YOU();
        }
        
        uint256 userTokenBal = IERC20(erc20TokenAddress).balanceOf(msg.sender);

      //apply penalty on the client if the pay past the invoice deadline
        if(block.timestamp > invoice.deadline){

           uint256 lateFee = calculateLateFee(invoiceId);
           uint256 amountToDeposit = invoice.amount + lateFee;

           require(userTokenBal >= amountToDeposit, "Insufficient balance for amount and late fee");
           invoice.isPaid = true;

           IERC20(erc20TokenAddress).transferFrom(msg.sender, address(this), amountToDeposit);
        }else{
            require(userTokenBal >= invoice.amount, "Insufficient balance");
            invoice.isPaid = true;
        
            IERC20(erc20TokenAddress).transferFrom(msg.sender, address(this), invoice.amount);
        }
    }

    function getMilestones(uint256 invoiceId) external view returns (Milestone[] memory) {
        return invoices[msg.sender][invoiceId].milestones;
    }

    function getInvoiceCount(address user) private view returns (uint256) {
        return invoiceCount[user];
    }



    function generateAllInvoice() external view returns (Invoice[] memory) {    /*************************************************************/
        if(msg.sender == address(0)){
        revert CustomErrors.ADDRESS_ZERO_NOT_PERMITED();
        } 

        Invoice[] memory inv;

        if(msg.sender == invoiceCreator){

            uint256 invoiceCounting = getInvoiceCount(msg.sender);

            if(invoiceCounter < 1){
                revert CustomErrors.INVOICE_NOT_GENERATED_YET();
            }
            inv = returnHelperInvoices(invoiceCounting);
        } else {
            
            uint256 invoiceCount2 = getInvoiceCount(msg.sender);

            if(invoiceCount2 < 1){
                revert CustomErrors.INVOICE_NOT_GENERATED_YET();
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
    function getInvoice(uint256 invoiceId) external view returns (Invoice memory) {
        if(msg.sender == address(0)){
            revert CustomErrors.ADDRESS_ZERO_NOT_PERMITED();
        }
        return invoices[invoiceCreator][invoiceId];

        // emit Events.InvoiceReturnedSuccessfully(msg.sender, invoiceId);

    }

    // get all invoices for a particular client
    function getInvoicesForClient() external view returns (Invoice[] memory){
        uint256 count = 0;
        for (uint256 i = 1; i <= invoiceCounter; i++) {
            require(invoices[invoiceCreator][i].clientAddress==msg.sender, "Enter A valid Address");
                count++;
            
        }
        Invoice[] memory clientInvoices = new Invoice[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= invoiceCounter; i++) {
            if (invoices[invoiceCreator][i].clientAddress==msg.sender) {
                clientInvoices[index] = invoices[msg.sender][i];
                index++;
            }

        }

        return clientInvoices;
    }



// the person who deposited into our escrow is doing this
    function confirmPaymentRelease(uint256 invoiceId) public {
        if(msg.sender == address(0)){
            revert CustomErrors.ADDRESS_ZERO_NOT_PERMITED();
        }

        Invoice storage invoice = invoices[invoiceCreator][invoiceId];

        if(msg.sender != invoice.clientAddress){
            revert CustomErrors.NOT_AUTHORIZE_TO_CALL_THIS_FUNCTION();
        }
        if(invoice.amount == 0){
            revert CustomErrors.CANT_INITIATE_RELEASE();
        }

        uint256 milestoneLength = invoice.milestones.length;
        uint256 userTokenBal = IERC20(erc20TokenAddress).balanceOf(msg.sender);


        for(uint256 counter = 0; counter < milestoneLength; counter++){
            if(invoice.milestones[counter].isPaid == false){

                //here is when both parties have fulfilled what was in agreement
                if(block.timestamp <= invoice.milestones[counter].deadline && block.timestamp <= invoice.deadline && invoice.milestones[counter].status == Status.confirmed){
                    invoice.milestones[counter].isPaid == true;
                    IERC20(erc20TokenAddress).transferFrom(address(this), invoice.clientAddress, invoice.milestones[counter].amount);
                    break;
                } 

                //Here is when client pays past the deadline of Invoice issuance

                if(block.timestamp <= invoice.milestones[counter].deadline && block.timestamp > invoice.deadline && invoice.milestones[counter].status == Status.confirmed){

                uint256 lateFee = calculateLateFee(invoiceId);
                uint256 amountToBeRealeased = invoice.amount + lateFee;

                require(userTokenBal >= amountToBeRealeased, "Insufficient balance for amount and late fee");
                invoice.isPaid = true;

                IERC20(erc20TokenAddress).transferFrom(address(this), invoice.clientAddress, amountToBeRealeased);
                }

                //Here is when the Supplier delivers past the milestone deadline

                if(block.timestamp > invoice.milestones[counter].deadline && invoice.milestones[counter].status == Status.confirmed){
                    uint256 lateFee =  calculateLateFeeForSupplier(invoiceId, counter);
                    uint256 amountToBeRealeased = invoice.milestones[counter].amount - lateFee;

                    invoice.milestones[counter].isPaid == true;
                    IERC20(erc20TokenAddress).transferFrom(address(this), invoice.clientAddress, amountToBeRealeased);
                    break;
                } 
            }
        }

    
    }
}
