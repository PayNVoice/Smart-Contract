// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MasterContract {

    uint256 public escrowAmount;
    uint256 penaltyRate;
    uint256 aggreementCounter;
    address paymentToken;
    
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

    event BusinnesRegistered(address indexed businessAddress, string indexed businessName);
    event AgreementCreated(uint256 agreementId, address supplier, address customer, uint256 totalAmount);
    event DepositReceived(uint256 amount, address from);

    constructor(address tokenAddress){
        aggreementCounter = 1;
        paymentToken =  tokenAddress;
    }

    function registerBusiness(string _name, string _category) external {
        registerBusiness[msg.sender] = BusinessAccount({
            businessName: _name,
            category: _category,
            isRegistered: true
        });

        emit BusinnesRegistered(msg.sender, businessName);
    }

    function createAgreement(address _supplier, address _customer, uint256 _totalAmount, string[] memory _milestoneDescription,  uint256 _deadline, uint256[] memory _milestoneAmounts, string memory _terms) external returns(uint256 aggreementId) {
        require(_supplier != address(0) && _customer != address(0), "Invalid addresses");

        B2BAgreement memory newAggreement = agreements[agreementCounter]
        newAggreement.supplier = _supplier;
        newAggreement.customer = _customer;
        newAggreement.totalAmount = _totalAmount;
        newAggreement.deadline = _deadline;
        newAggreement.terms = _terms;

        for(uint256 i = 0; i < _milestoneDescription.length; i++){
            newAggreement.milestones.push({
                description: _milestoneDescription[i],
                amount: _milestoneAmounts[i],
                status: MilestoneStatus.Pending
            })
        }

        emit AgreementCreated(agreementCounter, _supplier, _customer, _totalAmount);

        return agreementCounter++;
        
    }

    function depositToEscrow(uint256 _aggreementId, uint256 _milestoneIndex) external {
        require(amount > 0, "Must send some funds");
        require(agreements[_aggreementId].customer == msg.sender, "Only customer can send");

        paymentToken.transferFrom(msg.sender, address(this), amount);
        escrowAmount += amount;
        emit DepositReceived(amount, msg.sender);
    }

    //invoice for a milestone
    function generateInvoice(uint256 __aggreementId, uint256 _milestoneIndex) external {
          B2BAgreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.supplier || msg.sender == agreement.customer, "Unauthorized access");

        string memory invoiceDetails = string(abi.encodePacked(
            "Invoice for milestone ", 
            agreement.milestones[_milestoneIndex].description,
            ". Amount: ", 
            uint2str(agreement.milestones[_milestoneIndex].amount)
        ));

        emit InvoiceGenerated(_agreementId, _milestoneIndex, invoiceDetails);
    }

    
}