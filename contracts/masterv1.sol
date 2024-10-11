// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract B2BMasterContract is Ownable {
    struct BusinessAccount {
        string businessName;
        string category;
        string categoryBusinessTransactsWithMostly;
        bool isRegistered;
    }

    enum MilestoneStatus {
        Pending,
        Completed,
        Paid,
        CustomerConfirmed,
        SupplierConfirmed
    }

    struct Milestone {
        string description;
        uint256 amount;
        MilestoneStatus status; 
    }

    struct B2BAgreement {
        address supplier;
        address customer;
        uint256 totalAmount;
        Milestone[] milestones;
        uint256 deadline;
        string termsForConductingBusiness;
        bool isCompleted;
    }

    mapping(address => BusinessAccount) public registeredBusinesses;
    mapping(uint256 => B2BAgreement) public agreements; // Agreement ID => Agreement
    uint256 public agreementCounter;

    uint256 public penaltyRate; // Set a penalty rate for delayed payments or deliveries
    uint256 public escrowAmount;

    // Add state variable for the ERC20 token
    IERC20 public paymentToken; // ERC20 token address

    event BusinessRegistered(address indexed businessAddress, string businessName, string category);
    event AgreementCreated(uint256 agreementId, address supplier, address customer, uint256 totalAmount);
    event DepositReceived(uint256 amount, address from);
    event MilestoneCompleted(uint256 agreementId, uint256 milestoneIndex);
    event PaymentReleased(uint256 agreementId, uint256 milestoneIndex, uint256 amount);
    event InvoiceGenerated(uint256 agreementId, uint256 milestoneIndex, string invoiceDetails);
    event DeliveryDetailsUpdated(uint256 agreementId, uint256 milestoneIndex, string newDeliveryDetails, bool confirmed);

    modifier onlyRegistered() {
        require(registeredBusinesses[msg.sender].isRegistered, "Business not registered");
        _;
    }

    constructor(IERC20 _paymentToken) {
        paymentToken = _paymentToken; 
        agreementCounter = 1;
    }

    // Function to register a business
    function registerBusiness(
        string memory _businessName,
        string memory _category,
        string memory _categoryBusinessTransactsWithMostly
    ) external {
        require(!registeredBusinesses[msg.sender].isRegistered, "Business already registered");
        
        registeredBusinesses[msg.sender] = BusinessAccount({
            businessName: _businessName,
            category: _category,
            categoryBusinessTransactsWithMostly: _categoryBusinessTransactsWithMostly,
            isRegistered: true
        });

        emit BusinessRegistered(msg.sender, _businessName, _category);
    }

    // Create a new B2B agreement between a supplier and a customer
    function createAgreement(
        address _supplier,
        address _customer,
        uint256 _totalAmount,
        string[] memory _milestoneDescriptions,
        uint256[] memory _milestoneAmounts,
        uint256 _deadline,
        string memory _terms
    ) external onlyRegistered returns (uint256 agreementId) {
        require(_supplier != address(0) && _customer != address(0), "Invalid supplier or customer");
        require(_milestoneDescriptions.length == _milestoneAmounts.length, "Milestone data mismatch");

        B2BAgreement storage newAgreement = agreements[agreementCounter];
        newAgreement.supplier = _supplier;
        newAgreement.customer = _customer;
        newAgreement.totalAmount = _totalAmount;
        newAgreement.deadline = _deadline;
        newAgreement.termsForConductingBusiness = _terms;

        // Add milestones to the agreement
        for (uint256 i = 0; i < _milestoneDescriptions.length; i++) {
            newAgreement.milestones.push(Milestone({
                description: _milestoneDescriptions[i],
                amount: _milestoneAmounts[i],
                status: MilestoneStatus.Pending // Set the initial status to Pending
            }));
        }

        emit AgreementCreated(agreementCounter, _supplier, _customer, _totalAmount);

        return agreementCounter++;
    }

    // Deposit funds into the escrow
    function depositToEscrow(uint256 _agreementId, uint256 amount) external {
        require(amount > 0, "Must send some funds");
        require(agreements[_agreementId].customer == msg.sender, "Only customer can deposit");
        
        // Transfer the payment token from the customer to this contract
        require(paymentToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        
        escrowAmount += amount;
        emit DepositReceived(amount, msg.sender);
    }

    // Mark a milestone as completed by supplier
    function markMilestoneCompleted(uint256 _agreementId, uint256 _milestoneIndex) external {
        B2BAgreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.supplier, "Only supplier can mark as completed");
        require(agreement.milestones[_milestoneIndex].status == MilestoneStatus.Pending, "Milestone already completed");

        agreement.milestones[_milestoneIndex].status = MilestoneStatus.Completed;
        emit MilestoneCompleted(_agreementId, _milestoneIndex);
    }

    // Confirm a milestone as completed by customer
    function confirmMilestoneCompletion(uint256 _agreementId, uint256 _milestoneIndex) external {
        B2BAgreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.customer, "Only customer can confirm");

        agreement.milestones[_milestoneIndex].status = MilestoneStatus.CustomerConfirmed;

        // Release payment if both parties confirm the milestone
        if (agreement.milestones[_milestoneIndex].status == MilestoneStatus.Completed && 
            agreement.milestones[_milestoneIndex].status == MilestoneStatus.CustomerConfirmed) {
            releasePayment(_agreementId, _milestoneIndex);
        }
    }

    // Supplier confirms milestone completion after customer confirmation
    function supplierConfirmMilestone(uint256 _agreementId, uint256 _milestoneIndex) external {
        B2BAgreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.supplier, "Only supplier can confirm");

        agreement.milestones[_milestoneIndex].status = MilestoneStatus.SupplierConfirmed;

        // Release payment if both parties confirm the milestone
        if (agreement.milestones[_milestoneIndex].status == MilestoneStatus.Completed && 
            agreement.milestones[_milestoneIndex].status == MilestoneStatus.CustomerConfirmed) {
            releasePayment(_agreementId, _milestoneIndex);
        }
    }

    // Release payment for a completed milestone using ERC20 tokens
    function releasePayment(uint256 _agreementId, uint256 _milestoneIndex) internal {
        B2BAgreement storage agreement = agreements[_agreementId];
        require(agreement.milestones[_milestoneIndex].status == MilestoneStatus.Completed, "Milestone not completed");
        require(agreement.milestones[_milestoneIndex].status == MilestoneStatus.CustomerConfirmed, "Milestone not confirmed by customer");
        require(agreement.milestones[_milestoneIndex].status == MilestoneStatus.SupplierConfirmed, "Milestone not confirmed by supplier");

        uint256 paymentAmount = agreement.milestones[_milestoneIndex].amount;
        
        // Transfer the amount from this contract to the supplier
        require(paymentToken.transfer(agreement.supplier, paymentAmount), "Token transfer failed");
        
        agreement.milestones[_milestoneIndex].status = MilestoneStatus.Paid; // Update the milestone to paid status

        emit PaymentReleased(_agreementId, _milestoneIndex, paymentAmount);
    }

    // Generate invoice for a milestone
    function generateInvoice(uint256 _agreementId, uint256 _milestoneIndex) external {
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

    // Update delivery details for a milestone
    function updateDeliveryDetails(uint256 _agreementId, uint256 _milestoneIndex, string memory newDetails) external {
        B2BAgreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.supplier, "Only supplier can update delivery details");

        // Update delivery details in milestone
        emit DeliveryDetailsUpdated(_agreementId, _milestoneIndex, newDetails, false);
    }
}
