// //SPDX-License-Identifier: MIT

// pragma solidity ^0.8.24;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract Multiparty {


//   address owner;
//   address tokenAddress;
//   uint  agreementID; 
//   uint[] public agreementIDs;
  

//   enum Milestones {
//     STARTED,
//     PARTLY_READY,
//     COMPLETED
//   }


//   struct MultipartyRecord {
//     uint  _id;
//     address[] partyMembers;
//     uint[] amountAllocated;
//     string[] deliveryDate;
//     uint penalty;
//     mapping(address => uint256) totalDeposits;

//   }
  
//   mapping(uint => mapping(address => MultipartyRecord)) public multipartyList;
//   mapping (uint => bool) isCreated;
  

 
//   address public multipartyCreator;
//   address public multipartyCreatorBalance;
//   address public erc20TokenAddress;

//   error ADDRESS_ZERO_NOT_PERMITED();
//   error NOT_AUTHORIZE_TO_CALL_THIS_FUNCTION();
//   error PARTY_MEMBERS_VALUE_CANNOT_BE_EMPTY();
//   error VALUE_CANNOT_BE_EMPTY();
//   error LENGTH_MUST_BE_SAME_WITH_PARTYMEMBERS_LENGTH();
//   error PENALTY_RATE_MUST_BE_SET();
//   error NOT_A_MEMBER();
//   error NOT_AN_ALLOCATED_AMOUNT();
//   error INSUFFICIENT_AMOUNT();

//   event MultiPartyCreatedSuccessfully(address indexed whoCreates , uint256 indexed agreementID);
//   event  DepositSuccessful(address indexed depositor , uint256 amount, uint256 agreementID );
//   event MultiPartyCreatedSuccessfully(address indexed whoCreates);



//   constructor(address _tokenAddress){
//     if(msg.sender == address(0)){
//       revert ADDRESS_ZERO_NOT_PERMITED();
//     }
//     owner = msg.sender;
//      tokenAddress = _tokenAddress;
//   }

//   function createMultiPartySystem(
   
//     address[] memory _partMem, 
//     uint[] memory _amountAllocated,
//     string[] memory _deliveryDate,
//     uint _penalty
//     ) public {
//       if(msg.sender == address(0)){
//         revert ADDRESS_ZERO_NOT_PERMITED();
//       }
//       if(msg.sender != owner){
//         revert NOT_AUTHORIZE_TO_CALL_THIS_FUNCTION();
//       }
//       uint256 lengthOfArrayCheck = _partMem.length;

//       if(_partMem.length == 0){
//         revert PARTY_MEMBERS_VALUE_CANNOT_BE_EMPTY();
//       }

//       if(lengthOfArrayCheck != _amountAllocated.length ||
//       lengthOfArrayCheck != _deliveryDate.length){
        
//         revert LENGTH_MUST_BE_SAME_WITH_PARTYMEMBERS_LENGTH();
//       }

     

//       if(_penalty == 0){
//         revert PENALTY_RATE_MUST_BE_SET();
//       }

//       uint _id = agreementID + 1;

//       MultipartyRecord storage record = multipartyList[_id][msg.sender];

//       record._id = _id;
//       record.partyMembers =_partMem;
//       record.amountAllocated = _amountAllocated;
//       record.deliveryDate = _deliveryDate;
//       record.penalty = _penalty;

//       isCreated[_id] = true;

//       agreementID += 1;
//       agreementIDs.push(_id);

//       emit MultiPartyCreatedSuccessfully(msg.sender, _id);
      
//   }




//   function depositToPlatform(uint256 _amount, uint256 _id) public {

//   require(msg.sender != address(0), "zero address");
//   require( isCreated[_id] , "invalid Agreement");

//   MultipartyRecord storage record = multipartyList[_id][msg.sender];

//     bool isMember = false;
//     uint256 allocatedAmount;
// }
//   // function for the creator to send token to the contract
//   // function depositToken(uint256 _amount) external{
//   //   if(msg.sender == address(0)){
//   //     revert ADDRESS_ZERO_NOT_PERMITED();
//   //   }
//   //   if(erc20TokenAddress == address(0)){
//   //     revert ADDRESS_ZERO_NOT_PERMITED();
//   //   }
//   //   IERC20(erc20TokenAddress).transferFrom(multipartyCreator, address(this), _amount);
//   // }

// /*Release Payment*/
// function releasePayment(uint256 partyMemberId, uint256 milestoneIndex, uint256 milestone1Payment, uint256 milestone2Payment, uint256 milestone3Payment) external {
//     // We will ensure that the milestone is completed before releasing payment
//     // We assume that there is a mapping to track milestone completion for each party member
    
   
//     for (uint256 i = 0; i < record.partyMembers.length; i++) {
//         if (record.partyMembers[i] == msg.sender) {
//             isMember = true;
//             allocatedAmount = record.amountAllocated[i]; 
//             break;
//         }
//     }

//     if (!isMember) {
//         revert NOT_A_MEMBER();
//     }

//     if (_amount != allocatedAmount) {
//         revert NOT_AN_ALLOCATED_AMOUNT();
//     }

//     IERC20 token = IERC20(tokenAddress); 
//     require(token.allowance(msg.sender, address(this)) >= _amount, "Allowance not sufficient");
//     uint256 _userTokenBalance = token.balanceOf(msg.sender);

//      if (_userTokenBalance < _amount) {

//         revert INSUFFICIENT_AMOUNT();
//     }
   

//     token.transferFrom(msg.sender, address(this), _amount);

//     record.totalDeposits[msg.sender] += _amount;

//     emit  DepositSuccessful(msg.sender, _amount, _id);
// }


// function getAllAgreementIDs() public view returns (uint[] memory) {
//     return agreementIDs;
// }

// function getAgreementDetails(uint _id) 
//     public view returns (address[] memory, uint[] memory,string[] memory, uint) 
// {
//     MultipartyRecord storage record = multipartyList[_id][msg.sender];

//     return (record.partyMembers, record.amountAllocated, record.deliveryDate, record.penalty);
// }


// // function releasePayment( Milestones _mileStone,uint _amount, uint _id) external {
// //    MultipartyRecord storage record = multipartyList[_id][msg.sender];

// //         if(_mileStone == Milestones.STARTED){
// //             record.penalty;
            
// //         }else if (_mileStone == Milestones.PARTLY_READY){
// //           record.penalty ;
             
// //         } else {
// //          record.penalty;
          
// //         }

// // }





// }