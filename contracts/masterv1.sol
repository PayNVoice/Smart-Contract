// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.24;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract B2BMasterContract  {
//     struct BusinessAccount {
//         string businessName;
//         string category;
//         string categoryBusinessTransactsWithMostly;
//         bool isRegistered;
//     }

//     enum MilestoneStatus {
//         Pending,
//         Completed,
//         Paid,
//         CustomerConfirmed,
//         SupplierConfirmed
//     }

//     struct Milestone {
//         string description;
//         uint256 amount;
//         MilestoneStatus status; 
//     }

//     struct B2BAgreement {
//         address supplier;
//         address customer;
//         uint256 totalAmount;
//         Milestone[] milestones;
//         uint256 deadline;
//         string termsForConductingBusiness;
//         bool isCompleted;
//     }

//     mapping(address => BusinessAccount) public registeredBusinesses;
//     mapping(uint256 => B2BAgreement) public agreements; // Agreement ID => Agreement
//     uint256 public agreementCounter;

//     uint256 public penaltyRate; // Set a penalty rate for delayed payments or deliveries
//     uint256 public escrowAmount;

//     // Add state variable for the ERC20 token
//     IERC20 public paymentToken; // ERC20 token address

//     event BusinessRegistered(address indexed businessAddress, string businessName, string category);
//     event AgreementCreated(uint256 agreementId, address supplier, address customer, uint256 totalAmount);
//     event DepositReceived(uint256 amount, address from);
//     event MilestoneCompleted(uint256 agreementId, uint256 milestoneIndex);
//     event PaymentReleased(uint256 agreementId, uint256 milestoneIndex, uint256 amount);
//     event InvoiceGenerated(uint256 agreementId, uint256 milestoneIndex, string invoiceDetails);
//     event DeliveryDetailsUpdated(uint256 agreementId, uint256 milestoneIndex, string newDeliveryDetails, bool confirmed);

//     modifier onlyRegistered() {
//         require(registeredBusinesses[msg.sender].isRegistered, "Business not registered");
//         _;
//     }

//     constructor(IERC20 _paymentToken) {
//         paymentToken = _paymentToken; 
//         agreementCounter = 1;
//     }

//     // Function to register a business
//     function registerBusiness(
//         string memory _businessName,
//         string memory _category,
//         string memory _categoryBusinessTransactsWithMostly
//     ) external {
//         require(!registeredBusinesses[msg.sender].isRegistered, "Business already registered");
        
//         registeredBusinesses[msg.sender] = BusinessAccount({
//             businessName: _businessName,
//             category: _category,
//             categoryBusinessTransactsWithMostly: _categoryBusinessTransactsWithMostly,
//             isRegistered: true
//         });

//         emit BusinessRegistered(msg.sender, _businessName, _category);
//     }

//     // Create a new B2B agreement between a supplier and a customer
//     function createAgreement(
//         address _supplier,
//         address _customer,
//         uint256 _totalAmount,
//         string[] memory _milestoneDescriptions,
//         uint256[] memory _milestoneAmounts,
//         uint256 _deadline,
//         string memory _terms
//     ) external onlyRegistered returns (uint256 agreementId) {
//         require(_supplier != address(0) && _customer != address(0), "Invalid supplier or customer");
//         require(_milestoneDescriptions.length == _milestoneAmounts.length, "Milestone data mismatch");

//         B2BAgreement storage newAgreement = agreements[agreementCounter];
//         newAgreement.supplier = _supplier;
//         newAgreement.customer = _customer;
//         newAgreement.totalAmount = _totalAmount;
//         newAgreement.deadline = _deadline;
//         newAgreement.termsForConductingBusiness = _terms;

//         // Add milestones to the agreement
//         for (uint256 i = 0; i < _milestoneDescriptions.length; i++) {
//             newAgreement.milestones.push(Milestone({
//                 description: _milestoneDescriptions[i],
//                 amount: _milestoneAmounts[i],
//                 status: MilestoneStatus.Pending // Set the initial status to Pending
//             }));
//         }

//         emit AgreementCreated(agreementCounter, _supplier, _customer, _totalAmount);

//         return agreementCounter++;
//     }

//     // Deposit funds into the escrow
//     function depositToEscrow(uint256 _agreementId, uint256 amount) external {
//         require(amount > 0, "Must send some funds");
//         require(agreements[_agreementId].customer == msg.sender, "Only customer can deposit");
        
//         // Transfer the payment token from the customer to this contract
//         require(paymentToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        
//         escrowAmount += amount;
//         emit DepositReceived(amount, msg.sender);
//     }

//     // Mark a milestone as completed by supplier
//     function markMilestoneCompleted(uint256 _agreementId, uint256 _milestoneIndex) external {
//         B2BAgreement storage agreement = agreements[_agreementId];
//         require(msg.sender == agreement.supplier, "Only supplier can mark as completed");
//         require(agreement.milestones[_milestoneIndex].status == MilestoneStatus.Pending, "Milestone already completed");

//         agreement.milestones[_milestoneIndex].status = MilestoneStatus.Completed;
//         emit MilestoneCompleted(_agreementId, _milestoneIndex);
//     }

//     // Confirm a milestone as completed by customer
//     function confirmMilestoneCompletion(uint256 _agreementId, uint256 _milestoneIndex) external {
//         B2BAgreement storage agreement = agreements[_agreementId];
//         require(msg.sender == agreement.customer, "Only customer can confirm");

//         agreement.milestones[_milestoneIndex].status = MilestoneStatus.CustomerConfirmed;

//         // Release payment if both parties confirm the milestone
//         if (agreement.milestones[_milestoneIndex].status == MilestoneStatus.Completed && 
//             agreement.milestones[_milestoneIndex].status == MilestoneStatus.CustomerConfirmed) {
//             releasePayment(_agreementId, _milestoneIndex);
//         }
//     }

//     // Supplier confirms milestone completion after customer confirmation
//     function supplierConfirmMilestone(uint256 _agreementId, uint256 _milestoneIndex) external {
//         B2BAgreement storage agreement = agreements[_agreementId];
//         require(msg.sender == agreement.supplier, "Only supplier can confirm");

//         agreement.milestones[_milestoneIndex].status = MilestoneStatus.SupplierConfirmed;

//         // Release payment if both parties confirm the milestone
//         if (agreement.milestones[_milestoneIndex].status == MilestoneStatus.Completed && 
//             agreement.milestones[_milestoneIndex].status == MilestoneStatus.CustomerConfirmed) {
//             releasePayment(_agreementId, _milestoneIndex);
//         }
//     }

//     // Release payment for a completed milestone using ERC20 tokens
//     function releasePayment(uint256 _agreementId, uint256 _milestoneIndex) internal {
//         B2BAgreement storage agreement = agreements[_agreementId];
//         require(agreement.milestones[_milestoneIndex].status == MilestoneStatus.Completed, "Milestone not completed");
//         require(agreement.milestones[_milestoneIndex].status == MilestoneStatus.CustomerConfirmed, "Milestone not confirmed by customer");
//         require(agreement.milestones[_milestoneIndex].status == MilestoneStatus.SupplierConfirmed, "Milestone not confirmed by supplier");

//         uint256 paymentAmount = agreement.milestones[_milestoneIndex].amount;
        
//         // Transfer the amount from this contract to the supplier
//         require(paymentToken.transfer(agreement.supplier, paymentAmount), "Token transfer failed");
        
//         agreement.milestones[_milestoneIndex].status = MilestoneStatus.Paid; // Update the milestone to paid status

//         emit PaymentReleased(_agreementId, _milestoneIndex, paymentAmount);
//     }

//     // Generate invoice for a milestone
//     function generateInvoice(uint256 _agreementId, uint256 _milestoneIndex) external {
//         B2BAgreement storage agreement = agreements[_agreementId];
//         require(msg.sender == agreement.supplier || msg.sender == agreement.customer, "Unauthorized access");

//         string memory invoiceDetails = string(abi.encodePacked(
//             "Invoice for milestone ", 
//             agreement.milestones[_milestoneIndex].description,
//             ". Amount: ", 
//             uint2str(agreement.milestones[_milestoneIndex].amount)
//         ));

//         emit InvoiceGenerated(_agreementId, _milestoneIndex, invoiceDetails);
//     }

//     // Helper function to convert uint to string
//     function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
//         if (_i == 0) {
//             return "0";
//         }
//         uint j = _i;
//         uint len;
//         while (j != 0) {
//             len++;
//             j /= 10;
//         }
//         bytes memory bstr = new bytes(len);
//         uint k = len;
//         j = _i;
//         while (j != 0) {
//             bstr[--k] = bytes1(uint8(48 + j % 10));
//             j /= 10;
//         }
//         return string(bstr);

//     // Update delivery details for a milestone
//     function updateDeliveryDetails(uint256 _agreementId, uint256 _milestoneIndex, string memory newDetails) external {
//         B2BAgreement storage agreement = agreements[_agreementId];
//         require(msg.sender == agreement.supplier, "Only supplier can update delivery details");

//         // Update delivery details in milestone
//         emit DeliveryDetailsUpdated(_agreementId, _milestoneIndex, newDetails, false);
//     }
// }



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
    error PAYMENT_HAS_BEEN_MADE();
    error INVOICE_NOT_FOR_YOU();

    event InvoiceCreatedSuccessfully(address indexed whocreates, address indexed createFor, uint256 amount, uint256 id);
    event InvoiceReturnedSuccessfully(address indexed forwho, uint256 indexed invoiceId);
    event MilestoneAdded(uint256 indexed invoiceId, string indexed description, uint256 indexed amount);
    event MilestoneCompleted(uint256 indexed invoiceId, uint256 indexed milestoneIndex);
    event InvoiceAcceptedSuccessfully(address indexed forWho, uint256 indexed invoiceId);

    mapping(address => mapping(uint256 => Invoice)) public invoices;
    mapping(address => uint256) public invoiceCount;
    uint256 invoiceCounter = 1;

    function addMilestone(
        uint256 _invoiceId,
        string memory _description,
        uint256 _amount
        uint256 _deadline
    ) public {
        Invoice storage invoice = invoices[invoiceCreator][_invoiceId];
        invoice.milestones.push(Milestone({
            description: _description,
            amount: _amount,
            status: Status.pending,
            isPaid: false
            deadline: _deadline
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

    // Add Late Fee Penalty Calculation
    function calculateLateFee(uint256 invoiceId) public view returns (uint256) {
        Invoice storage invoice = invoices[invoiceCreator][invoiceId];
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

        Invoice storage invoice = invoices[invoiceCreator][invoiceId];
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

        Invoice storage invoice = invoices[invoiceCreator][invoiceId];
        if(invoice.clientAddress != msg.sender){
            revert INVOICE_NOT_FOR_YOU();
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
function confirmPaymentRelease(uint256 invoiceId) public {
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

    uint256 milestoneLength = invoice.milestones.length;

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
                lateFee =  calculateLateFeeForSupplier(invoiceId, invoice.milestones[counter])
                uint256 amountToBeRealeased = invoice.milestones[counter].amount - lateFee;

                invoice.milestones[counter].isPaid == true;
                IERC20(erc20TokenAddress).transfer(address(this), invoice.clientAddress, amountToBeRealeased);
                break;
            } 
        }
    }

    // if(invoice.isPaid == true){
    //     revert PAYMENT_HAS_BEEN_MADE();
    // }

    // delete invoices[invoiceCreator][invoiceId];
}

// function requestForPaymentRelease(uint256 invoiceId, uint256 milestone) external{
//     if(msg.sender == address(0)){
//         revert ADDRESS_ZERO_NOT_PERMITTED();
//     }

//     if(msg.sender )
//     invoices[invoiceCreator][invoiceId];
//     if()
// }


}