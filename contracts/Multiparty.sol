
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Multiparty {


  address owner;
  address tokenAddress;
  uint  agreementID; 
  uint[] public agreementIDs;
  

  enum Milestones {
    STARTED,
    PARTLY_READY,
    COMPLETED
  }


  struct MultipartyRecord {
    uint  _id;
    address[] partyMembers;
    uint[] amountAllocated;
    string[] deliveryDate;
    uint penalty;
    mapping(address => uint256) totalDeposits;

  }
  
  mapping(uint => mapping(address => MultipartyRecord)) public multipartyList;
  mapping (uint => bool) isCreated;
  

 
  address public multipartyCreator;
  address public multipartyCreatorBalance;
  address public erc20TokenAddress;

  error ADDRESS_ZERO_NOT_PERMITED();
  error NOT_AUTHORIZE_TO_CALL_THIS_FUNCTION();
  error PARTY_MEMBERS_VALUE_CANNOT_BE_EMPTY();
  error VALUE_CANNOT_BE_EMPTY();
  error LENGTH_MUST_BE_SAME_WITH_PARTYMEMBERS_LENGTH();
  error PENALTY_RATE_MUST_BE_SET();
  error NOT_A_MEMBER();
  error NOT_AN_ALLOCATED_AMOUNT();
  error INSUFFICIENT_AMOUNT();

  event MultiPartyCreatedSuccessfully(address indexed whoCreates , uint256 indexed agreementID);
  event  DepositSuccessful(address indexed depositor , uint256 amount, uint256 agreementID );
  event MultiPartyCreatedSuccessfully(address indexed whoCreates);



  constructor(address _tokenAddress){
    if(msg.sender == address(0)){
      revert ADDRESS_ZERO_NOT_PERMITED();
    }
    owner = msg.sender;
     tokenAddress = _tokenAddress;
  }

  function createMultiPartySystem(
   
    address[] memory _partMem, 
    uint[] memory _amountAllocated,
    string[] memory _deliveryDate,
    uint _penalty
    ) public {
      if(msg.sender == address(0)){
        revert ADDRESS_ZERO_NOT_PERMITED();
      }
      if(msg.sender != owner){
        revert NOT_AUTHORIZE_TO_CALL_THIS_FUNCTION();
      }
      uint256 lengthOfArrayCheck = _partMem.length;

      if(_partMem.length == 0){
        revert PARTY_MEMBERS_VALUE_CANNOT_BE_EMPTY();
      }

      if(lengthOfArrayCheck != _amountAllocated.length ||
      lengthOfArrayCheck != _deliveryDate.length){
        
        revert LENGTH_MUST_BE_SAME_WITH_PARTYMEMBERS_LENGTH();
      }

     

      if(_penalty == 0){
        revert PENALTY_RATE_MUST_BE_SET();
      }

      uint _id = agreementID + 1;

      MultipartyRecord storage record = multipartyList[_id][msg.sender];

      record._id = _id;
      record.partyMembers =_partMem;
      record.amountAllocated = _amountAllocated;
      record.deliveryDate = _deliveryDate;
      record.penalty = _penalty;

      isCreated[_id] = true;

      agreementID += 1;
      agreementIDs.push(_id);

      emit MultiPartyCreatedSuccessfully(msg.sender, _id);
      
  }




  function depositToPlatform(uint256 _amount, uint256 _id) public {

  require(msg.sender != address(0), "zero address");
  require( isCreated[_id] , "invalid Agreement");

  MultipartyRecord storage record = multipartyList[_id][msg.sender];

    bool isMember = false;
    uint256 allocatedAmount;
}
  // function for the creator to send token to the contract
  // function depositToken(uint256 _amount) external{
  //   if(msg.sender == address(0)){
  //     revert ADDRESS_ZERO_NOT_PERMITED();
  //   }
  //   if(erc20TokenAddress == address(0)){
  //     revert ADDRESS_ZERO_NOT_PERMITED();
  //   }
  //   IERC20(erc20TokenAddress).transferFrom(multipartyCreator, address(this), _amount);
  // }

/*Release Payment*/
function releasePayment(uint256 partyMemberId, uint256 milestoneIndex, uint256 milestone1Payment, uint256 milestone2Payment, uint256 milestone3Payment) external {
    // We will ensure that the milestone is completed before releasing payment
    // We assume that there is a mapping to track milestone completion for each party member
    
   
    for (uint256 i = 0; i < record.partyMembers.length; i++) {
        if (record.partyMembers[i] == msg.sender) {
            isMember = true;
            allocatedAmount = record.amountAllocated[i]; 
            break;
        }
    }

    if (!isMember) {
        revert NOT_A_MEMBER();
    }

    if (_amount != allocatedAmount) {
        revert NOT_AN_ALLOCATED_AMOUNT();
    }

    IERC20 token = IERC20(tokenAddress); 
    require(token.allowance(msg.sender, address(this)) >= _amount, "Allowance not sufficient");
    uint256 _userTokenBalance = token.balanceOf(msg.sender);

     if (_userTokenBalance < _amount) {

        revert INSUFFICIENT_AMOUNT();
    }
   

    token.transferFrom(msg.sender, address(this), _amount);

    record.totalDeposits[msg.sender] += _amount;

    emit  DepositSuccessful(msg.sender, _amount, _id);
}


function getAllAgreementIDs() public view returns (uint[] memory) {
    return agreementIDs;
}

function getAgreementDetails(uint _id) 
    public view returns (address[] memory, uint[] memory,string[] memory, uint) 
{
    MultipartyRecord storage record = multipartyList[_id][msg.sender];

    return (record.partyMembers, record.amountAllocated, record.deliveryDate, record.penalty);
}


// function releasePayment( Milestones _mileStone,uint _amount, uint _id) external {
//    MultipartyRecord storage record = multipartyList[_id][msg.sender];

//         if(_mileStone == Milestones.STARTED){
//             record.penalty;
            
//         }else if (_mileStone == Milestones.PARTLY_READY){
//           record.penalty ;
             
//         } else {
//          record.penalty;
          
//         }

// }




}

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
    // Add additional functions for payment release and other operations as needed
}

