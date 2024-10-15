// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


library PriceConverter {
     function getLatestPrice() view  internal returns(uint256){
        AggregatorV3Interface price = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int256 answer, ,,)= price.latestRoundData(); 
        return uint256(answer * 1e10);

    }

    function getConversionRate(uint ethAmount) view internal  returns(uint){
        uint ethPrice = getLatestPrice();
        uint ethAmountTousd = (ethPrice * ethAmount) / 1e18;
        return ethAmountTousd;
    }
}
	
