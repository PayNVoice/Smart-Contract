// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract PayNVoice {


    address public invoiceCreator;

    struct Invoice{
       address clientAddress;
       uint256 amount;
       uint256 deadline;
       string termsAndConditions;
       string paymentterm;
       bool areConditionsMet;
       bool isPaid;

    }

    address public erc20TokenAddress;
    mapping(uint256=>Invoice) public invoice;
    uint256 public invoiceCounter;
    Invoice[] invoiceList;


    function createInvoice(address clientAddress, uint256 amount, uint256 deadline, string memory termsAndConditions, string memory paymentterm) public {
     uint256 invoiceId = invoiceCounter+1;
     Invoice storage _invoice = invoice[invoiceId];
     _invoice.clientAddress = clientAddress;
     _invoice.creatorAddress = msg.sender;
     _invoice.amount = amount;
     _invoice.deadline = deadline;
     _invoice.termsAndConditions = termsAndConditions;
     _invoice.paymentterm = paymentterm;

    invoiceList.push(_invoice);
    invoiceCounter+=1;
    }


/*Client generate all invoice*/

function generateAllInvoice() external view returns (Invoice[] memory) {
    return invoiceList;
}

/*Client get a particular invoice*/
function getInvoice(uint256 invoiceId) external view returns (Invoice memory) {
    return invoice[invoiceId];

}

// get all invoices for a particular client
function getInvoicesForClient(address client) external view returns (Invoice[] memory) {
    uint256 count = 0;
    for (uint256 i = 1; i <= invoiceCounter; i++) {
        if (invoice[i].clientAddress == client) {
            count++;
        }
    }

    Invoice[] memory clientInvoices = new Invoice[](count);
    uint256 index = 0;
    for (uint256 i = 1; i <= invoiceCounter; i++) {
        if (invoice[i].clientAddress == client) {
            clientInvoices[index] = invoice[i];
=======
    constructor(){
        if(msg.sender == address(0)){
            revert ADDRESS_ZERO_NOT_PERMITED();
        }
        invoiceCreator = msg.sender;
    }

    error ADDRESS_ZERO_NOT_PERMITED();
    error INVOICE_NOT_GENERATED_YET();
    error YOU_DID_NOT_DEPLOY_THIS_CONTRACT();

    event InvoiceCreatedSuccessfully(address indexed whocreates, address indexed createFor, uint256 amount, uint256 id);
    event InvoiceReturnedSuccessfully(address indexed forwho, uint256 invoiceId);

    address public erc20TokenAddress = 0x6033F7f88332B8db6ad452B7C6D5bB643990aE3f;
    mapping(address => mapping(uint256 => Invoice)) public invoices;
    mapping(address => uint256) public invoiceCount;
    uint256 public invoiceCounter = 1;

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
        invoiceCounter+=1;

        emit InvoiceCreatedSuccessfully(msg.sender, clientAddress, amount, invoiceId_);
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

/*function for payment*/
function payment(uint256 invoiceId) external payable {
require(invoice[invoiceId].clientAddress == msg.sender, "This invoice Not for you");

uint256 userTokenBal = IERC20(erc20TokenAddress).balanceOf(msg.sender);
require(userTokenBal >= invoice[invoiceId].amount, "Insufficient balance");

invoice[invoiceId].isPaid = true;
IERC20(erc20TokenAddress).transferFrom(msg.sender, address(this), invoice[invoiceId].amount);
}

/*function to release Payment*/
function releasePayment(uint256 invoiceId) external {
    require(invoice[invoiceId].creatorAddress== msg.sender, "You cant initiate realease");
    require(invoice[invoiceId].isPaid == true, "Invoice is not paid");
     
    IERC20(erc20TokenAddress).transfer(invoice[invoiceId].clientAddress, invoice[invoiceId].amount);
    
    delete invoice[invoiceId];
}
function payment(uint256 invoiceId) external payable {
    require(invoices[invoiceCreator][invoiceId].clientAddress == msg.sender, "This invoice Not for you");
    
    uint256 userTokenBal = IERC20(erc20TokenAddress).balanceOf(msg.sender);
    require(userTokenBal >= invoices[invoiceCreator][invoiceId].amount, "Insufficient balance");
    invoices[invoiceCreator][invoiceId].isPaid = true;
    
    IERC20(erc20TokenAddress).transferFrom(msg.sender, address(this), invoices[invoiceCreator][invoiceId].amount);
}

function releasePayment(uint256 invoiceId) external {
    require(invoices[msg.sender][invoiceId].amount == 0, "You cant initiate realease");
    require(invoices[invoiceCreator][invoiceId].isPaid == true, "Invoice is not paid");
     
    IERC20(erc20TokenAddress).transfer(invoices[invoiceCreator][invoiceId].clientAddress, invoices[invoiceCreator][invoiceId].amount);
    
    delete invoices[invoiceCreator][invoiceId];
}


}