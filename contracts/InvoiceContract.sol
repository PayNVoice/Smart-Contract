// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract PayNVoice {

    struct Invoice{
       address clientAddress;
       address creatorAddress;
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


}