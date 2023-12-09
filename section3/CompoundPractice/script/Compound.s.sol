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
    constructor() ERC20("Underlying coin", "ULC")  {
        _mint(msg.sender, 10000e18);
    }
}

contract CompoundScript is Script {
    function run() external {

        //command
        //forge script script/Compound.s.sol:CompoundScript --rpc-url xxxx --private-key xxxx --broadcast

        vm.startBroadcast();

        address myAddress = 0x7502D29B7ebEBb410d42FB8e4ff62CEd6CFC24d4;

        UnderlyingCoin ulc = new UnderlyingCoin();
        Unitroller unitroller = new Unitroller();
        Comptroller comptroller = new Comptroller();
        Comptroller comptrollerProxy = Comptroller(address(unitroller));
        WhitePaperInterestRateModel whitePaperInterestRateModel = new WhitePaperInterestRateModel(0, 0);
        CErc20Delegate cErc20Delegate = new CErc20Delegate();

        SimplePriceOracle simplePriceOracle = new SimplePriceOracle();

        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);

        comptrollerProxy._setPriceOracle(simplePriceOracle);

        CErc20Delegator cErc20Delegator = new CErc20Delegator(
            address(ulc), 
            comptrollerProxy, 
            whitePaperInterestRateModel, 
            1e18,
            "Compound Underlying coin",
            "cULC",
            18,
            payable(myAddress),
            address(cErc20Delegate),
            "0x"
        );

        

        vm.stopBroadcast();
    }
}
