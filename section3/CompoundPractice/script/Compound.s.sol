// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract SimpleSwapScript is Script {
    function run() external {
        //vm.startBroadcast('private key');

        address token0 = 0xb16F35c0Ae2912430DAc15764477E179D9B9EbEa;
        address token1 = 0x51fCe89b9f6D4c530698f181167043e1bB4abf89;

        //SimpleSwap simpleSwap = new SimpleSwap(token0, token1);

        //vm.stopBroadcast();
    }
}
