// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './token.sol';

contract MasterContract {

    uint256 public escrowAmount;
    uint256 penaltyRate;
    uint256 aggreementCounter;
    Token public  paymentToken;
    
    struct BusinessAccount{
        string businessName;
        string category;
        bool isRegistered;
    }

    enum mileStoneStatus{
        Pending,
        Completed,
        Paid,
        customerConfirmed,
        supplierConfirmed
    }

    struct Milestone{
        string description;
        uint256 amount;
        mileStoneStatus status;

    }

    struct B2BAgreement{
        address supplier;
        address customer;
        uint256 totalAmount;
        uint256 deadline;
        string termsOfBusiness;
        Milestone[] milestones;
        bool isCompleted;
    }

    mapping (address => BusinessAccount) public registeredBusiness;
    mapping(uint256 =>  B2BAgreement) public agreements;

    event BusinessRegistered(address indexed businessAddress, string indexed businessName);
    event AgreementCreated(uint256 indexed agreementId, address indexed supplier, address indexed customer, uint256  totalAmount);
    event DepositReceived(uint256 indexed amount, address from);
    event PaymentReleased(uint256 indexed agreementId, uint256 indexed milestoneIndex, uint256 indexed amount);
    event InvoiceGenerated(uint256 indexed agreementId, uint256 indexed milestoneIndex, string indexed invoiceDetails);
    event MilestoneCompleted(uint256 indexed agreementId, uint256 indexed milestoneIndex);

    modifier onlyRegistered(){
        require(registeredBusiness[msg.sender].isRegistered, "Business not registered");
        _;
    }

    constructor(address tokenAddress){
        aggreementCounter = 1;
        paymentToken = Token(tokenAddress);
    }

    function registerBusiness(string memory _name, string  memory _category) external {
        registeredBusiness[msg.sender] = BusinessAccount({
            businessName: _name,
            category: _category,
            isRegistered: true
        });

        emit BusinessRegistered(msg.sender, _name);
    }

    function createAgreement(
        address _supplier, 
        address _customer, 
        uint256 _totalAmount, 
        string[] memory _milestoneDescriptions,  
        uint256 _deadline, 
        uint256[] memory _milestoneAmounts, 
        string memory _terms
        ) external onlyRegistered returns(uint256 aggreementId)  {
        require(_supplier != address(0) && _customer != address(0), "Invalid addresses");

        B2BAgreement storage newAggreement = agreements[aggreementCounter];
        newAggreement.supplier = _supplier;
        newAggreement.customer = _customer;
        newAggreement.totalAmount = _totalAmount;
        newAggreement.deadline = _deadline;
        newAggreement.termsOfBusiness = _terms;

          for (uint256 i = 0; i < _milestoneDescriptions.length; i++) {
            newAggreement.milestones.push(Milestone({
                description: _milestoneDescriptions[i],
                amount: _milestoneAmounts[i],
                status: mileStoneStatus.Pending // initial status is Pending
            }));
        }

        emit AgreementCreated(aggreementCounter, _supplier, _customer, _totalAmount);

        return aggreementCounter++;
        
    }

    function depositToEscrow(uint256 _aggreementId, uint256 amount) external {
        require(amount > 0, "Must send some funds");
        require(agreements[_aggreementId].customer == msg.sender, "Only customer can send");

        paymentToken.transferFrom(msg.sender, address(this), amount);
        escrowAmount += amount;
        emit DepositReceived(amount, msg.sender);
    }

    //supplier marks milestone completed
    function markMilesstoneCompleted(uint256 _agreementId, uint256 _milestoneIndex ) external {
        B2BAgreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.supplier, "Only supplier can mark as complete");
        require(agreement.milestones[_milestoneIndex].status == mileStoneStatus.Pending, "Milestone already completed");

        agreement.milestones[_milestoneIndex].status = mileStoneStatus.Completed;
        emit MilestoneCompleted(_agreementId, _milestoneIndex);

    }

    // customer confirms the completion of milestone
    function confirmMilestoneCompletion(uint256 _agreementId, uint256 _milestoneIndex) external {
        B2BAgreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.customer, "Only customer can confirm");

        agreement.milestones[_milestoneIndex].status = mileStoneStatus.customerConfirmed;

        // Release payment if both parties confirm the milestone
        if (agreement.milestones[_milestoneIndex].status == mileStoneStatus.Completed && 
            agreement.milestones[_milestoneIndex].status == mileStoneStatus.customerConfirmed) {
            releasePayment(_agreementId, _milestoneIndex);
        }
    }

    // Release payment for a completed milestone using ERC20 tokens
    function releasePayment(uint256 _agreementId, uint256 _milestoneIndex) internal {
        B2BAgreement storage agreement = agreements[_agreementId];
        require(agreement.milestones[_milestoneIndex].status == mileStoneStatus.Completed, "Milestone not completed");
        require(agreement.milestones[_milestoneIndex].status == mileStoneStatus.customerConfirmed, "Milestone not confirmed by customer");
        require(agreement.milestones[_milestoneIndex].status == mileStoneStatus.supplierConfirmed, "Milestone not confirmed by supplier");

        uint256 paymentAmount = agreement.milestones[_milestoneIndex].amount;
        
        // Transfer the amount from this contract to the supplier
        require(paymentToken.transfer(agreement.supplier, paymentAmount), "Token transfer failed");
        
        agreement.milestones[_milestoneIndex].status = mileStoneStatus.Paid; // Update the milestone to paid status

        emit PaymentReleased(_agreementId, _milestoneIndex, paymentAmount);
    }

    //invoice for a milestone
    function generateInvoice(uint256 __aggreementId, uint256 _milestoneIndex) external {
        B2BAgreement storage agreement = agreements[__aggreementId];
        require(msg.sender == agreement.supplier || msg.sender == agreement.customer, "Unauthorized access");

        string memory invoiceDetails = string(abi.encodePacked(
            "Invoice for milestone ", 
            agreement.milestones[_milestoneIndex].description,
            ". Amount: ", 
            uint2str(agreement.milestones[_milestoneIndex].amount)
        ));

        emit InvoiceGenerated(__aggreementId, _milestoneIndex, invoiceDetails);
    }

       // Helper function to convert uint to string
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        return string(bstr);
    }

    
}