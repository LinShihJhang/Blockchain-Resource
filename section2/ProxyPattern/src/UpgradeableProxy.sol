// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Proxy } from "./Proxy.sol";

contract UpgradeableProxy is Proxy {
  // TODO:
  // 1. inherit or copy the code from BasicProxy
  // 2. add upgradeTo function to upgrade the implementation contract
  // 3. add upgradeToAndCall, which upgrade the implemnetation contract and call the init function again
  address implementationContractAddress;
  constructor(address implementationContractAddress_){
    implementationContractAddress = implementationContractAddress_;
  }
  fallback() external payable {
        _delegate(implementationContractAddress);
    }

    function upgradeTo(address newImplementationContractAddress) external{
      implementationContractAddress = newImplementationContractAddress;
    }

    function upgradeToAndCall(address newImplementationContractAddress, bytes calldata data) external payable{
      implementationContractAddress = newImplementationContractAddress;
       (bool success, ) = address(implementationContractAddress).delegatecall(data);
       require(success,"call success"); 

    }
}