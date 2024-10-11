// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract MasterContract {

    struct BusinessAccount{
        string businessName;
        string category;
        bool isRegistered;
    }

    mapping (address => BusinessAccount) public registeredBusiness;

    event BusinnesRegistered(address indexed businessAddress, string businessName)

    function registerBusiness(string _name, string _category) external {
        registerBusiness[msg.sender] = BusinessAccount({
            businessName: _name,
            category: _category,
            isRegistered: true
        });

        emit BusinnesRegistered(msg.sender, businessName);
    }

    
}