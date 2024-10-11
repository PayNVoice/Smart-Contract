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
  address lskTokenAddress;

  error ADDRESS_ZERO_NOT_PERMITED();
  error NOT_AUTHORIZE_TO_CALL_THIS_FUNCTION();
  error PARTY_MEMBERS_VALUE_CANNOT_BE_EMPTY();
  error VALUE_CANNOT_BE_EMPTY();
  error LENGTH_MUST_BE_SAME_WITH_PARTYMEMBERS_LENGTH();
  error TERMS_FOR_BUSINESS_CANNOT_BE_EMPTY();
  error PENALTY_RATE_MUST_BE_SET();
  error NOT_A_MEMBER();
  error NOT_AN_ALLOCATED_AMOUNT();
  error INSUFFICIENT_AMOUNT();

  event MultiPartyCreatedSuccessfully(address indexed whoCreates);
  event  DepositSuccessful(address indexed depositor , uint256 amount, uint256 counterID);


  constructor(address _lskTokenAddress){
    if(msg.sender == address(0)){
      revert ADDRESS_ZERO_NOT_PERMITED();
    }
    multipartyCreator = msg.sender;
     lskTokenAddress = _lskTokenAddress;
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



  function depositToPlatform(uint256 _amount, uint256 _counterID) public {

  
    MultipartyRecord storage record = multipartyList[msg.sender][_counterID];

    bool isMember = false;
    uint256 allocatedAmount;
    
   
    for (uint256 i = 0; i < record.partyMembers.length; i++) {
        if (record.partyMembers[i] == msg.sender) {
            isMember = true;
            allocatedAmount = record.totalAmountAllocatedForEachPartyMember[i]; 
            break;
        }
    }

    if (!isMember) {
        revert NOT_A_MEMBER();
    }

    if (_amount != allocatedAmount) {
        revert NOT_AN_ALLOCATED_AMOUNT();
    }

    IERC20 lskToken = IERC20(lskTokenAddress); 

    uint256 _userTokenBalance = lskToken.balanceOf(msg.sender);

     if (_userTokenBalance < _amount) {

        revert INSUFFICIENT_AMOUNT();
    }
   

    lskToken.transferFrom(msg.sender, address(this), _amount);

    emit  DepositSuccessful(msg.sender, _amount, _counterID);
}


  





}