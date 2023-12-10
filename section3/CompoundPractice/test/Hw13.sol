// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "compound-protocol/contracts/Comptroller.sol";
import "compound-protocol/contracts/ComptrollerInterface.sol";
import "compound-protocol/contracts/Unitroller.sol";
import "compound-protocol/contracts/CErc20Delegator.sol";
import "compound-protocol/contracts/CErc20Delegate.sol";
import "compound-protocol/contracts/CToken.sol";
import "compound-protocol/contracts/WhitePaperInterestRateModel.sol";
import "compound-protocol/contracts/SimplePriceOracle.sol";

contract Hw13Test {
    // EIP20Interface public USDC = EIP20Interface(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    // CErc20 public cUSDC = CErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    // address public user;

    Unitroller unitroller;
    Comptroller comptroller;
    Comptroller comptrollerProxy;
    WhitePaperInterestRateModel whitePaperInterestRateModel;
    ERC20 underlyingCoinA;
    ERC20 underlyingCoinB;
    CErc20Delegate cTokenA;
    CErc20Delegate cTokenB;
    SimplePriceOracle simplePriceOracle;

    address admin = makeAddr("Admin");
    address user1 = makeAddr("User1");

    function setUp() public override {
        vm.startPrank(admin);

        unitroller = new Unitroller();
        comptroller = new Comptroller();
        comptrollerProxy = Comptroller(address(unitroller));
        whitePaperInterestRateModel = new WhitePaperInterestRateModel(0, 0);
        ERC20 underlyingCoinA = new ERC20("Underlying coin A", "ULCA");
        ERC20 underlyingCoinB = new ERC20("Underlying coin B", "ULCB");
        SimplePriceOracle simplePriceOracle = new SimplePriceOracle();

        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);
        comptrollerProxy._setPriceOracle(simplePriceOracle);
        

        cTokenA = new CErc20Delegator(
            address(underlyingCoinA), 
            comptrollerProxy, 
            whitePaperInterestRateModel, 
            1e18,
            "Compound Underlying coin A",
            "cULCA",
            18,
            payable(admin),
            address(cErc20Delegate),
            "0x"
        );
        cTokenB = new CErc20Delegator(
            address(underlyingCoinB), 
            comptrollerProxy, 
            whitePaperInterestRateModel, 
            1e18,
            "Compound Underlying coin B",
            "cULCB",
            18,
            payable(admin),
            address(cErc20Delegate),
            "0x"
        );

        comptrollerProxy._supportMarket(cToken(address(cTokenA)));
        comptrollerProxy._supportMarket(cToken(address(cTokenB)));

        deal(underlyingCoinA, user1, 1e20);

        vm.stopPranks();
        // vm.label(borrowerAddress, "Borrower");
    }

    function testMintRedeem() public {
        vm.startPrank(user1);
        cTokenA.mint(1e20);
        cTokenB.mint(1e20);
        vm.stopPranks();
        
    }


}
