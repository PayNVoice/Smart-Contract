// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";

// contract B2BMasterContract is Ownable {
//     struct BusinessAccount {
//         string businessName;
//         string category;
//         string categoryBusinessTransactsWithMostly;
//         bool isRegistered;
//     }

//     struct Milestone {
//         string description;
//         uint256 amount;
//         bool isCompleted;
//         bool isPaid;
//         bool customerConfirmed;
//         bool supplierConfirmed;
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

//     constructor() {
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
//                 isCompleted: false,
//                 isPaid: false,
//                 customerConfirmed: false,
//                 supplierConfirmed: false
//             }));
//         }

//         emit AgreementCreated(agreementCounter, _supplier, _customer, _totalAmount);

//         return agreementCounter++;
//     }

//     // Deposit funds into the escrow
//     function depositToEscrow(uint256 _agreementId) external payable {
//         require(msg.value > 0, "Must send some funds");
//         require(agreements[_agreementId].customer == msg.sender, "Only customer can deposit");

//         escrowAmount += msg.value;
//         emit DepositReceived(msg.value, msg.sender);
//     }

//     // Mark a milestone as completed by supplier
//     function markMilestoneCompleted(uint256 _agreementId, uint256 _milestoneIndex) external {
//         B2BAgreement storage agreement = agreements[_agreementId];
//         require(msg.sender == agreement.supplier, "Only supplier can mark as completed");
//         require(!agreement.milestones[_milestoneIndex].isCompleted, "Milestone already completed");

//         agreement.milestones[_milestoneIndex].isCompleted = true;
//         emit MilestoneCompleted(_agreementId, _milestoneIndex);
//     }

//     // Confirm a milestone as completed by customer
//     function confirmMilestoneCompletion(uint256 _agreementId, uint256 _milestoneIndex) external {
//         B2BAgreement storage agreement = agreements[_agreementId];
//         require(msg.sender == agreement.customer, "Only customer can confirm");

//         agreement.milestones[_milestoneIndex].customerConfirmed = true;
        
//         // Release payment if both parties confirm the milestone
//         if (agreement.milestones[_milestoneIndex].supplierConfirmed && agreement.milestones[_milestoneIndex].customerConfirmed) {
//             releasePayment(_agreementId, _milestoneIndex);
//         }
//     }

//     // Supplier confirms milestone completion after customer confirmation
//     function supplierConfirmMilestone(uint256 _agreementId, uint256 _milestoneIndex) external {
//         B2BAgreement storage agreement = agreements[_agreementId];
//         require(msg.sender == agreement.supplier, "Only supplier can confirm");

//         agreement.milestones[_milestoneIndex].supplierConfirmed = true;
        
//         // Release payment if both parties confirm the milestone
//         if (agreement.milestones[_milestoneIndex].supplierConfirmed && agreement.milestones[_milestoneIndex].customerConfirmed) {
//             releasePayment(_agreementId, _milestoneIndex);
//         }
//     }

//     // Release payment for a completed milestone
//     function releasePayment(uint256 _agreementId, uint256 _milestoneIndex) internal {
//         B2BAgreement storage agreement = agreements[_agreementId];
//         require(agreement.milestones[_milestoneIndex].isCompleted, "Milestone not completed");
//         require(agreement.milestones[_milestoneIndex].customerConfirmed && agreement.milestones[_milestoneIndex].supplierConfirmed, "Milestone not confirmed by both parties");

//         uint256 paymentAmount = agreement.milestones[_milestoneIndex].amount;
//         payable(agreement.supplier).transfer(paymentAmount);
//         agreement.milestones[_milestoneIndex].isPaid = true;

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
//         uint k = len - 1;
//         while (_i != 0) {
//             bstr[k--] = bytes1(uint8(48 + _i % 10));
//             _i /= 10;
//         }
//         return string(bstr);
//     }
// }
