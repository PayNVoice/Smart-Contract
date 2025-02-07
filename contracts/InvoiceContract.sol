// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.24;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "./library/PriceConverter.sol";

// contract PayNVoice {
//     using PriceConverter for uint256; 

//     address public invoiceCreator;
//     address public erc20TokenAddress;

//     struct Invoice{
//        address clientAddress;
//        uint256 amount;
//        uint256 deadline;
//        string termsAndConditions;
//        string paymentterm;
//        bool areConditionsMet;
//        bool isPaid;
//        bool hasAccepted;
//        Milestone[] milestones;
//        uint256 lateFeeRate;
//     }
//     enum Status{
//         pending,
//         isCompleted,
//         confirmed
//     }

//     struct Milestone {
//         string description;
//         uint256 amount;
//         Status status;
//         bool isPaid;
//         uint256 deadline;
//     }

//     constructor(address _erc20TokenAddress){
//         if(msg.sender == address(0)){
//             revert ADDRESS_ZERO_NOT_PERMITTED();
//         }
//         if(_erc20TokenAddress == address(0)){
//             revert ADDRESS_ZERO_NOT_PERMITTED();
//         }
//         invoiceCreator = msg.sender;
//         erc20TokenAddress = _erc20TokenAddress;
//     }

//     error ADDRESS_ZERO_NOT_PERMITTED();
//     error INVOICE_NOT_GENERATED_YET();
//     error YOU_DID_NOT_DEPLOY_THIS_CONTRACT();
//     error INVOICE_DOES_NOT_EXIST();
//     error NOT_AUTHORIZE_TO_CALL_THIS_FUNCTION();
//     error CANT_INITIATE_RELEASE();
//     error PAYMENT_HAS_BEEN_MADE();
//     error INVOICE_NOT_FOR_YOU();
//     error INSUFFICIENT_AMOUNT_INPUTTED();

//     event InvoiceCreatedSuccessfully(address indexed whocreates, address indexed createFor, uint256 amount, uint256 id);
//     event InvoiceReturnedSuccessfully(address indexed forwho, uint256 invoiceId);
//     event MilestoneAdded(uint256 indexed invoiceId, string description, uint256 amount);
//     event MilestoneCompleted(uint256 indexed invoiceId, uint256 milestoneIndex);
//     event InvoiceAcceptedSuccessfully(address indexed forWho, uint256 invoiceId);
//     event ReceiptGenerated(uint256 milestone, address indexed forWho, uint256 amount);
//     mapping(address => mapping(uint256 => Invoice)) public invoices;
//     mapping(address => uint256) public invoiceCount;
//     uint256 invoiceCounter = 1;



//     function createInvoice(address clientAddress, uint256 ethAmount, uint256 deadline, string memory termsAndConditions, string memory paymentTerm) public returns(uint256 invoiceId_) {
//         if(msg.sender == address(0)){
//             revert ADDRESS_ZERO_NOT_PERMITTED();
//         }
//         if(msg.sender != invoiceCreator){
//             revert YOU_DID_NOT_DEPLOY_THIS_CONTRACT();
//         }

//         uint256 usdAmount = ethAmount.getConversionRate();

//         invoiceId_ = invoiceCounter;
        
//         Invoice storage _invoice = invoices[invoiceCreator][invoiceId_];
//         _invoice.clientAddress = clientAddress;
//         _invoice.amount = usdAmount;
//         _invoice.deadline = deadline;
//         _invoice.termsAndConditions = termsAndConditions;
//         _invoice.paymentterm = paymentTerm;
        
//         invoices[msg.sender][invoiceId_] = _invoice;
//         invoiceCount[msg.sender]++;
//         invoiceCounter++;

//         emit InvoiceCreatedSuccessfully(msg.sender, clientAddress, ethAmount, invoiceId_);
//     }

//     function addMilestone(
//         uint256 _invoiceId,
//         string memory _description,
//         uint256 _amount,
//         uint256 _deadline
//     ) public {
//         Invoice storage invoice = invoices[invoiceCreator][_invoiceId];
//         invoice.milestones.push(Milestone({
//             description: _description,
//             amount: _amount,
//             status: Status.pending,
//             isPaid: false,
//             deadline: _deadline
//         }));
//         emit MilestoneAdded(_invoiceId, _description, _amount);
//     }


//     function acceptInvoice(uint256 _invoiceId) external{
//         if(msg.sender == address(0)){
//             revert ADDRESS_ZERO_NOT_PERMITTED();
//         }
//         Invoice storage invoice = invoices[invoiceCreator][_invoiceId];
//         if(invoice.clientAddress != msg.sender){
//             revert INVOICE_DOES_NOT_EXIST();
//         }
//         invoice.hasAccepted = true;

//         emit InvoiceAcceptedSuccessfully(msg.sender, _invoiceId);
//     }


//     function depositToEscrow(uint256 invoiceId, uint256 ethAmount) external {
//         if(msg.sender == address(0)){
//             revert ADDRESS_ZERO_NOT_PERMITTED();
//         }
//         Invoice storage invoice = invoices[invoiceCreator][invoiceId];

//         if(msg.sender != invoice.clientAddress){
//             revert INVOICE_NOT_FOR_YOU();
//         }

//         uint256 amountSpecifiedByInvoiceCreator = invoice.amount;

//         if(ethAmount <= amountSpecifiedByInvoiceCreator){
//             revert INSUFFICIENT_AMOUNT_INPUTTED();
//         }
        
//         uint256 usdAmount = ethAmount.getConversionRate();

//         uint256 userTokenBal = IERC20(erc20TokenAddress).balanceOf(msg.sender);
//         uint256 userTokenBalInUSD = userTokenBal.getConversionRate();
//         require(userTokenBalInUSD > usdAmount, "Insufficient balance");
//         invoices[invoiceCreator][invoiceId].isPaid = true;
        
//         IERC20(erc20TokenAddress).transferFrom(msg.sender, address(this), ethAmount);
//     }

//     // function depositToEscrow(uint256 invoiceId, uint256 ethAmount) external payable {

//     //      if(msg.sender == address(0)){
//     //         revert ADDRESS_ZERO_NOT_PERMITTED();
//     //     }
//     //     Invoice storage invoice = invoices[invoiceCreator][invoiceId];

//     //     if(msg.sender != invoice.clientAddress){
//     //         revert INVOICE_NOT_FOR_YOU();
//     //     }

//     //     uint256 amountSpecifiedByInvoiceCreator = invoice.amount;

//     //     if(ethAmount <= amountSpecifiedByInvoiceCreator){
//     //         revert INSUFFICIENT_AMOUNT_INPUTTED();
//     //     }
        
//     //     uint256 usdAmount = ethAmount.getConversionRate();

        
        
//     //     uint256 userTokenBal = IERC20(erc20TokenAddress).balanceOf(msg.sender);
//     //     uint256 userTokenBalInUSD = userTokenBal.getConversionRate();

//     //   //apply penalty on the client if the pay past the invoice deadline
//     //     if(block.timestamp > invoice.deadline){

//     //        uint256 lateFee = calculateLateFee(invoiceId);
//     //        uint256 amountToDeposit = invoice.amount + lateFee;

//     //        require(userTokenBalInUSD >= amountToDeposit, "Insufficient balance for amount and late fee");
//     //        invoice.isPaid = true;

//     //        IERC20(erc20TokenAddress).transferFrom(msg.sender, address(this), amountToDeposit);
//     //     }else{
//     //         require(userTokenBalInUSD >= invoice.amount, "Insufficient balance");
//     //         invoice.isPaid = true;
        
//     //         IERC20(erc20TokenAddress).transferFrom(msg.sender, address(this), invoice.amount);
//     //     }
//     // }




//     function markMilestoneCompleted(uint256 _invoiceId, uint256 _milestoneIndex) public {   
//         Invoice storage invoice = invoices[invoiceCreator][_invoiceId];
//         require(_milestoneIndex < invoice.milestones.length, "Invalid milestone index");

//         Milestone storage milestone = invoice.milestones[_milestoneIndex];
//         milestone.status = Status.isCompleted;

//         emit MilestoneCompleted(_invoiceId, _milestoneIndex);
//     }


    


//     // Add Late Fee Penalty Calculation
//     function calculateLateFee(uint256 invoiceId) public view returns (uint256) {
//         Invoice storage invoice = invoices[invoiceCreator][invoiceId];
//         if (block.timestamp > invoice.deadline) {
//             uint256 daysLate = (block.timestamp - invoice.deadline) / (24*60*60);
//             uint256 lateFee = (invoice.amount * invoice.lateFeeRate * daysLate) / 100;
//             return lateFee;
//         } else {
//             return 0;
//         }
//     }

//      // Add Late Fee Penalty Calculation on Supplier
//     function calculateLateFeeForSupplier(uint256 invoiceId, uint256 milestoneIndex) public view returns (uint256) {

//         Invoice storage invoice = invoices[invoiceCreator][invoiceId];
//         require(milestoneIndex < invoice.milestones.length, "Invalid milestone index");

//         Milestone storage milestone = invoice.milestones[milestoneIndex]; 

//         if (block.timestamp > milestone.deadline) {
//             uint256 daysLate = (block.timestamp - invoice.deadline) / (24*60*60);
//             uint256 lateFee = (invoice.amount * invoice.lateFeeRate * daysLate) / 100;
//             return lateFee;
//         } else {
//             return 0;
//         }
//     }


//     // the person who deposited into our escrow is doing this
//     function confirmPaymentRelease(uint256 invoiceId) public {
//         if(msg.sender == address(0)){
//             revert ADDRESS_ZERO_NOT_PERMITTED();
//         }

//         Invoice storage invoice = invoices[invoiceCreator][invoiceId];

//         if(msg.sender != invoice.clientAddress){
//             revert NOT_AUTHORIZE_TO_CALL_THIS_FUNCTION();
//         }
//         if(invoice.amount == 0){
//             revert CANT_INITIATE_RELEASE();
//         }

//         uint256 milestoneLength = invoice.milestones.length;
//         uint256 userTokenBal = IERC20(erc20TokenAddress).balanceOf(msg.sender);


//         for(uint256 counter = 0; counter < milestoneLength; counter++){
//             if(invoice.milestones[counter].isPaid == false){

//                 //here is when both parties have fulfilled what was in agreement
//                 if(block.timestamp <= invoice.milestones[counter].deadline && block.timestamp <= invoice.deadline && invoice.milestones[counter].status == Status.confirmed){
//                     invoice.milestones[counter].isPaid == true;
//                     IERC20(erc20TokenAddress).transferFrom(address(this), invoice.clientAddress, invoice.milestones[counter].amount);
//                     break;
//                 } 

//                 //Here is when client pays past the deadline of Invoice issuance

//                 if(block.timestamp <= invoice.milestones[counter].deadline && block.timestamp > invoice.deadline && invoice.milestones[counter].status == Status.confirmed){

//                 uint256 lateFee = calculateLateFee(invoiceId);
//                 uint256 amountToBeRealeased = invoice.amount + lateFee;

//                 require(userTokenBal >= amountToBeRealeased, "Insufficient balance for amount and late fee");
//                 invoice.isPaid = true;

//                 IERC20(erc20TokenAddress).transferFrom(address(this), invoice.clientAddress, amountToBeRealeased);
//                 }

//                 //Here is when the Supplier delivers past the milestone deadline

//                 if(block.timestamp > invoice.milestones[counter].deadline && invoice.milestones[counter].status == Status.confirmed){
//                     uint256 lateFee =  calculateLateFeeForSupplier(invoiceId, counter);
//                     uint256 amountToBeRealeased = invoice.milestones[counter].amount - lateFee;

//                     invoice.milestones[counter].isPaid == true;
//                     IERC20(erc20TokenAddress).transferFrom(address(this), invoice.clientAddress, amountToBeRealeased);
//                     break;
//                 } 
//             }
//         }

    
//     }


//     function getMilestones(uint256 invoiceId) external view returns (Milestone[] memory) {
//         return invoices[invoiceCreator][invoiceId].milestones;
//     }

//     function getInvoiceCount(address user) private view returns (uint256) {
//         return invoiceCount[user];
//     }

//     function generateAllInvoice() external view returns (Invoice[] memory) {
//         if(msg.sender == address(0)){
//             revert ADDRESS_ZERO_NOT_PERMITTED();
//         } 
//         Invoice[] memory inv;
//         if(msg.sender == invoiceCreator){
//             uint256 invoiceCounting = getInvoiceCount(msg.sender);
//             if(invoiceCounter < 1){
//                 revert INVOICE_NOT_GENERATED_YET();
//             }
//             inv = returnHelperInvoices(invoiceCounting);
//         } else {
            
//             uint256 invoiceCount2 = getInvoiceCount(invoiceCreator);
//             if(invoiceCount2 < 1){
//                 revert INVOICE_NOT_GENERATED_YET();
//             }
//             inv = returnHelperInvoices(invoiceCount2);
//         }
//         return inv;
//     }

//     function returnHelperInvoices(uint256 invoiceCou) private view returns(Invoice[] memory){
//         Invoice[] memory invoiceList = new Invoice[](invoiceCou);
//             for(uint256 count = 1; count<=invoiceCou; count++){
//                 invoiceList[count - 1] = invoices[msg.sender][count];
//             }
//         return invoiceList;
//     }

//     /*Client get a particular invoice*/
//     function getInvoice(uint256 invoiceId) external returns (Invoice memory invoice1_) {
//         if(msg.sender == address(0)){
//             revert ADDRESS_ZERO_NOT_PERMITTED();
//         }
//         invoice1_ = invoices[invoiceCreator][invoiceId];

//         emit InvoiceReturnedSuccessfully(msg.sender, invoiceId);
//     }

//     // get all invoices for a particular client
//     function getInvoicesForClient(address client) external view returns (Invoice[] memory){
//         uint256 count = 0;
//         for (uint256 i = 1; i <= invoiceCounter; i++) {
//             if (invoices[invoiceCreator][i].clientAddress == client) {
//                 count++;
//             }
//         }
//         Invoice[] memory clientInvoices = new Invoice[](count);
//         uint256 index = 0;
//         for (uint256 i = 1; i <= invoiceCounter; i++) {
//             if (invoices[invoiceCreator][i].clientAddress == client) {
//                 clientInvoices[index] = invoices[invoiceCreator][i];
//                 index++;
//             }
//         }
//         return clientInvoices;
//     }

//     function generateReceipt(uint256 milestone, address clientAddress, uint256 usdAmount) public{
//         emit ReceiptGenerated(
//             milestone,
//             clientAddress,
//             usdAmount
//         );
            
//     }


// }

    
    
