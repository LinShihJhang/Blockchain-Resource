// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "compound-protocol/contracts/Comptroller.sol";
import "compound-protocol/contracts/ComptrollerInterface.sol";
import "compound-protocol/contracts/Unitroller.sol";
import "compound-protocol/contracts/CErc20Delegator.sol";
import "compound-protocol/contracts/CErc20Delegate.sol";
import "compound-protocol/contracts/WhitePaperInterestRateModel.sol";
import "compound-protocol/contracts/SimplePriceOracle.sol";

contract UnderlyingCoin is ERC20 {
    constructor() ERC20("Underlying coin", "ULC")  {}
}

contract CompoundScript is Script {
    function run() external {

        //command
        //forge script script/Compound.s.sol:CompoundScript --rpc-url xxxx --private-key xxxx --broadcast

        vm.startBroadcast();

        address myAddress = 0x7502D29B7ebEBb410d42FB8e4ff62CEd6CFC24d4;

        UnderlyingCoin ulc = new UnderlyingCoin();
        Comptroller comptroller = new Comptroller();
        Unitroller unitroller = new Unitroller();
        WhitePaperInterestRateModel whitePaperInterestRateModel = new WhitePaperInterestRateModel(0, 0);
        CErc20Delegate cErc20Delegate = new CErc20Delegate();

        SimplePriceOracle simplePriceOracle = new SimplePriceOracle();

        CErc20Delegator cErc20Delegator = new CErc20Delegator(
            address(ulc), 
            ComptrollerInterface(address(comptroller)), 
            whitePaperInterestRateModel, 
            1,
            "Compound Underlying coin",
            "cULC",
            18,
            payable(myAddress),
            address(cErc20Delegate),
            "0x"
        );

        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);

        Comptroller(address(unitroller))._setPriceOracle(simplePriceOracle);

        vm.stopBroadcast();
    }
}
