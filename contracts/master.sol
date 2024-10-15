// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


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

    struct Supplier{
        address supplierAddresses;
        Milestone[] milestones;
        bool isPaid;
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
        // address supplier;
        address customer;
        uint256 totalAmount;
        uint256 deadline;
        string termsOfBusiness;
        address[] supplierAddresses;
        mapping(address => Supplier) suppliers;
        bool isCompleted;
    }

    

    mapping (address => BusinessAccount) public registeredBusiness;
    mapping(uint256 =>  B2BAgreement) public agreements;

    event BusinessRegistered(address indexed businessAddress, string indexed businessName);
    event AgreementCreated(uint256 indexed agreementId, address indexed customer, uint256 indexed  totalAmount);
    event DepositReceived(uint256 indexed amount, address from);
    event PaymentReleased(uint256 indexed agreementId, address _supplier, uint256 indexed milestoneIndex, uint256 indexed amount);
    event InvoiceGenerated(uint256 indexed agreementId, address _supplier, uint256 indexed milestoneIndex, string indexed invoiceDetails);
    event MilestoneCompleted(uint256 indexed agreementId, uint256 indexed milestoneIndex);
    event SupplierAdded(uint256 indexed agreementId, address indexed supplier);

    modifier onlyRegistered(){
        require(registeredBusiness[msg.sender].isRegistered, "Business not registered");
        _;
    }

    modifier onlyCustomer(uint256 _agreementId) {
        require(agreements[_agreementId].customer == msg.sender, "Only the customer can perform this action");
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
        address _customer, 
        uint256 _totalAmount,  
        uint256 _deadline, 
        string memory _terms
        ) external returns(uint256 aggreementId)  {
        require(_customer != address(0), "Invalid addresses");

        B2BAgreement storage newAggreement = agreements[aggreementCounter];
        newAggreement.customer = _customer;
        newAggreement.totalAmount = _totalAmount;
        newAggreement.deadline = _deadline;
        newAggreement.termsOfBusiness = _terms;

        emit AgreementCreated(aggreementCounter, _customer, _totalAmount);

        return aggreementCounter++;
        
    }


    function addSupplier(
        uint256 _agreementId, 
        address _supplier, 
        string[] memory _milestoneDescriptions, 
        uint256[] memory _milestoneAmounts
    ) external onlyCustomer(_agreementId)
    {
        require(_supplier != address(0), "Invalid supplier address");
        require(_milestoneDescriptions.length == _milestoneAmounts.length, "Descriptions and amounts length mismatch");

        B2BAgreement storage agreement = agreements[_agreementId];
        require(agreement.suppliers[_supplier].supplierAddresses == address(0), "Supplier already added");

        //create supplier
        Supplier storage supplier = agreement.suppliers[_supplier];
        supplier.supplierAddresses = _supplier;

        for(uint256 i =0; i < _milestoneDescriptions.length; i++){
            supplier.milestones.push(Milestone({
                description: _milestoneDescriptions[i],
                amount: _milestoneAmounts[i],
                status: mileStoneStatus.Pending
            }));
        }

        agreement.supplierAddresses.push(_supplier);
        emit SupplierAdded(_agreementId, _supplier);

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
        Supplier storage supplier = agreement.suppliers[msg.sender];

        require(supplier.supplierAddresses == msg.sender, "Only supplier can mark as complete");
        require(supplier.milestones[_milestoneIndex].status == mileStoneStatus.Pending, "Milestone already completed");

        supplier.milestones[_milestoneIndex].status = mileStoneStatus.Completed;
        emit MilestoneCompleted(_agreementId, _milestoneIndex);

        // Generate the invoice automatically
        generateInvoice(_agreementId, _milestoneIndex, msg.sender);

    }

    // customer confirms the completion of milestone
    function confirmMilestoneCompletion(uint256 _agreementId, address _supplier, uint256 _milestoneIndex) external {

        B2BAgreement storage agreement = agreements[_agreementId];
        Supplier storage supplier = agreement.suppliers[msg.sender];
        
        require(supplier.milestones[_milestoneIndex].status == mileStoneStatus.Completed, "Milestone not completed by supplier");

        supplier.milestones[_milestoneIndex].status = mileStoneStatus.customerConfirmed;

        // Release payment if both parties confirm the milestone
        if (supplier.milestones[_milestoneIndex].status == mileStoneStatus.Completed && 
            supplier.milestones[_milestoneIndex].status == mileStoneStatus.customerConfirmed) {
            releasePayment(_agreementId, _supplier, _milestoneIndex);
        }
    }

    // Release payment for a completed milestone using ERC20 tokens
    function releasePayment(uint256 _agreementId, address _supplier, uint256 _milestoneIndex) internal {

        B2BAgreement storage agreement = agreements[_agreementId];
        Supplier storage supplier = agreement.suppliers[msg.sender];

        require(supplier.milestones[_milestoneIndex].status == mileStoneStatus.Completed, "Milestone not completed");
        require(supplier.milestones[_milestoneIndex].status == mileStoneStatus.customerConfirmed, "Milestone not confirmed by customer");
        require(supplier.milestones[_milestoneIndex].status == mileStoneStatus.supplierConfirmed, "Milestone not confirmed by supplier");

        uint256 paymentAmount = supplier.milestones[_milestoneIndex].amount;
        
        // Transfer the amount from this contract to the supplier
        require(paymentToken.transfer(supplier.supplierAddresses, paymentAmount), "Token transfer failed");
        
        supplier.milestones[_milestoneIndex].status = mileStoneStatus.Paid; // Update the milestone to paid status

        emit PaymentReleased(_agreementId, _supplier, _milestoneIndex, paymentAmount);
    }

    //invoice for a milestone
    function generateInvoice(uint256 _aggreementId, uint256 _milestoneIndex, address _supplier) internal {
        
        B2BAgreement storage agreement = agreements[_aggreementId];
        Supplier storage supplier = agreement.suppliers[_supplier];

        string memory invoiceDetails = string(abi.encodePacked(
            "Invoice for milestone ", 
            supplier.milestones[_milestoneIndex].description,
            ". Amount: ", 
            uint2str(supplier.milestones[_milestoneIndex].amount)
        ));

        emit InvoiceGenerated(_aggreementId, _supplier, _milestoneIndex, invoiceDetails);
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