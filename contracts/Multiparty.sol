//SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Multiparty {

  enum Milestone1 {
    COMPLETED
  }

  enum Milestone2{
    STARTED,
    COMPLETED
  }

  enum Milestone3 {
    STARTED,
    PARTLY_READY,
    COMPLETED
  }
// Balance of partyMembers in out contract
mapping(uint256 partyMemberId => address partyMemberAddress)  public partyMember; 


  struct MultipartyRecord {
    address[] partyMembers;
    uint256[] totalAmountAllocatedForEachPartyMember;
    uint256[] milestoneCountForEachPartyMember;
    uint256[] expectedDeliveryDate;
    string termsForConductingBusiness;
    uint256 penaltyRateForDefaulters;
  }
  mapping(address => mapping(uint256 => MultipartyRecord)) public multipartyList;
  mapping(address => uint256) public totalMultiPartySystemCreated;

  address multipartyCreator;
  address multipartyCreatorBalance;
  address erc20TokenAddress;

  error ADDRESS_ZERO_NOT_PERMITED();
  error NOT_AUTHORIZE_TO_CALL_THIS_FUNCTION();
  error PARTY_MEMBERS_VALUE_CANNOT_BE_EMPTY();
  error VALUE_CANNOT_BE_EMPTY();
  error LENGTH_MUST_BE_SAME_WITH_PARTYMEMBERS_LENGTH();
  error TERMS_FOR_BUSINESS_CANNOT_BE_EMPTY();
  error PENALTY_RATE_MUST_BE_SET();

  event MultiPartyCreatedSuccessfully(address indexed whoCreates);
  // event Deposited

  constructor(){
    if(msg.sender == address(0)){
      revert ADDRESS_ZERO_NOT_PERMITED();
    }
    multipartyCreator = msg.sender;
  }

  function createMultiPartySystem(
    address[] memory _partMem, 
    uint256[] memory _totalAmountForEach,
    uint256[] memory _mileStoneCountForEach,
    uint256[] memory _expectedDateForEach,
    string memory _termsForConductingBusiness,
    uint256 _penalty
    ) public {
      if(msg.sender == address(0)){
        revert ADDRESS_ZERO_NOT_PERMITED();
      }
      if(msg.sender != multipartyCreator){
        revert NOT_AUTHORIZE_TO_CALL_THIS_FUNCTION();
      }
      uint256 lengthOfArrayCheck = _partMem.length;

      if(_partMem.length == 0){
        revert PARTY_MEMBERS_VALUE_CANNOT_BE_EMPTY();
      }

      if(lengthOfArrayCheck != _totalAmountForEach.length ||
      lengthOfArrayCheck != _mileStoneCountForEach.length ||
      lengthOfArrayCheck != _expectedDateForEach.length){
        
        revert LENGTH_MUST_BE_SAME_WITH_PARTYMEMBERS_LENGTH();
      }

      if(bytes(_termsForConductingBusiness).length == 0){
        revert TERMS_FOR_BUSINESS_CANNOT_BE_EMPTY();
      }

      if(_penalty == 0){
        revert PENALTY_RATE_MUST_BE_SET();
      }

      MultipartyRecord memory newRecord = MultipartyRecord({
        partyMembers: _partMem,
        totalAmountAllocatedForEachPartyMember: _totalAmountForEach,
        milestoneCountForEachPartyMember: _mileStoneCountForEach,
        expectedDeliveryDate: _expectedDateForEach,
        termsForConductingBusiness: _termsForConductingBusiness,
        penaltyRateForDefaulters: _penalty
      });

      uint256 counter = totalMultiPartySystemCreated[msg.sender];
      multipartyList[msg.sender][counter] = newRecord;

      totalMultiPartySystemCreated[msg.sender]++;

      // I WILL COME BACK TO THE EVENT LATER TO ADD MORE ARGUMENTS
      emit MultiPartyCreatedSuccessfully(msg.sender);
      
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
    // Ensure that the milestone is completed before releasing payment
    // We assume that there is a mapping to track milestone completion for each party member
    
    if (milestoneIndex == 1 && Milestone1.COMPLETED == Milestone1.COMPLETED) {
        IERC20(erc20TokenAddress).transfer(partyMember[partyMemberId], milestone1Payment);
    } else if (milestoneIndex == 2 && Milestone2.COMPLETED == Milestone2.COMPLETED) {
        IERC20(erc20TokenAddress).transfer(partyMember[partyMemberId], milestone2Payment);
    } else if (milestoneIndex == 3 && Milestone3.COMPLETED == Milestone3.COMPLETED) {
       IERC20(erc20TokenAddress).transfer(partyMember[partyMemberId], milestone3Payment);
    } else {
        revert("Milestone not completed or invalid");
    }
}





}