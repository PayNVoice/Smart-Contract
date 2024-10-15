// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.24;

// import "./MasterContract.sol";
// import "./SupplierContract.sol";
// import "./InvoiceContract.sol";

// contract FactoryContract {
//     MasterContract public masterContract;

//     struct ProjectDetails {
//         address[] customers;
//         uint256[] totalAmountToBeAllocatedForEachCustomer;
//         string[] milestones;
//         uint256[] expectedDeliveryDate;
//         string termsForConductingBusiness;
//         uint256 penaltyRate;
//         address[] supplierContracts; // Added to store supplier contract addresses
//         address[] invoiceContracts; // Added to store invoice contract addresses
//     }

//     mapping(uint256 => ProjectDetails) public projects;
//     uint256 public projectCounter;

//     event SupplierContractCreated(address supplierContract);
//     event InvoiceContractCreated(address invoiceContract);
//     event ProjectDeployed(address indexed initiator, uint256 projectId, ProjectDetails project);
//     event MilestoneCompleted(uint256 projectId, uint256 milestoneIndex);
//     event DeliveryDetailsUpdated(address customer, string newDeliveryDetails);

//     constructor(address _masterContract) {
//         masterContract = MasterContract(_masterContract);
//         projectCounter = 0;
//     }

//     // Create a new project and deploy contracts for multiple customers
//     function createProject(
//         address[] memory customers,
//         uint256[] memory totalAmountToBeAllocatedForEachCustomer,
//         string[] memory milestones,
//         uint256[] memory expectedDeliveryDate,
//         string memory termsForConductingBusiness,
//         uint256 penaltyRate
//     ) external {
//         require(customers.length > 0, "No customers provided");
//         require(customers.length == totalAmountToBeAllocatedForEachCustomer.length, "Mismatch in customers and allocated amounts");

//         ProjectDetails storage project = projects[projectCounter];
//         project.customers = customers;
//         project.totalAmountToBeAllocatedForEachCustomer = totalAmountToBeAllocatedForEachCustomer;
//         project.milestones = milestones;
//         project.expectedDeliveryDate = expectedDeliveryDate;
//         project.termsForConductingBusiness = termsForConductingBusiness;
//         project.penaltyRate = penaltyRate;

//         for (uint256 i = 0; i < customers.length; i++) {
//             // Deploy a supplier contract for each customer
//             SupplierContract newSupplierContract = new SupplierContract(customers[i], address(masterContract));
//             project.supplierContracts.push(address(newSupplierContract));
//             emit SupplierContractCreated(address(newSupplierContract));
//         }

//         emit ProjectDeployed(msg.sender, projectCounter, project);
//         projectCounter++;
//     }

//     // Generate an invoice for a specific customer and milestone
//     function generateInvoiceForCustomer(
//         uint256 projectId,
//         address customer,
//         uint256 amount,
//         string memory details
//     ) external {
//         ProjectDetails storage project = projects[projectId];
//         require(isCustomerInProject(project, customer), "Customer not part of this project");

//         // Create an invoice contract
//         InvoiceContract newInvoiceContract = new InvoiceContract(customer, amount, details);
//         project.invoiceContracts.push(address(newInvoiceContract));
//         emit InvoiceContractCreated(address(newInvoiceContract));

//         // Call the master contract to generate the invoice
//         masterContract.generateInvoice(customer, amount, details);
//     }

//     // Update delivery details for a specific customer
//     function updateDeliveryDetailsForCustomer(
//         uint256 projectId,
//         address customer,
//         string memory newDeliveryDetails,
//         bytes memory signature
//     ) external {
//         ProjectDetails storage project = projects[projectId];
//         require(isCustomerInProject(project, customer), "Customer not part of this project");

//         // Call the master contract to update delivery details
//         masterContract.updateDeliveryDetails(customer, newDeliveryDetails, signature);

//         // Emit an event to notify the system
//         emit DeliveryDetailsUpdated(customer, newDeliveryDetails);
//     }

//     // Complete a milestone
//     function completeMilestone(
//         uint256 projectId,
//         uint256 milestoneIndex
//     ) external {
//         require(milestoneIndex < projects[projectId].milestones.length, "Invalid milestone index");

//         // Emit event to track milestone completion
//         emit MilestoneCompleted(projectId, milestoneIndex);
//     }

//     // Internal function to check if an address is a customer in the project
//     function isCustomerInProject(ProjectDetails storage project, address customer) internal view returns (bool) {
//         for (uint256 i = 0; i < project.customers.length; i++) {
//             if (project.customers[i] == customer) {
//                 return true;
//             }
//         }
//         return false;
//     }
// }
