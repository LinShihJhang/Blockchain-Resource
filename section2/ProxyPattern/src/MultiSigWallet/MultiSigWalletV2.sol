// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import { MultiSigWallet } from "./MultiSigWallet.sol";

contract MultiSigWalletV2 is MultiSigWallet {

    constructor (address[3] memory _owners) MultiSigWallet(_owners) {}
    
    function updateOwner(address _newOwner1, address _newOwner2, address _newOwner3) external onlyAdmin override {
      owner1 = _newOwner1;
      owner2 = _newOwner2;
      owner3 = _newOwner3;
    }

    function camcelTransaction() public {
        transactions.pop();
    }

    

}