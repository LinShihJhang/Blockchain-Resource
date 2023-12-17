// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "compound-protocol/contracts/Comptroller.sol";
import "compound-protocol/contracts/ComptrollerInterface.sol";
import "compound-protocol/contracts/Unitroller.sol";
import "compound-protocol/contracts/CErc20Delegator.sol";
import "compound-protocol/contracts/CErc20Delegate.sol";
import "compound-protocol/contracts/CToken.sol";
import "compound-protocol/contracts/WhitePaperInterestRateModel.sol";
import "compound-protocol/contracts/SimplePriceOracle.sol";

contract UnderlyingCoinA is ERC20 {
    constructor() ERC20("Underlying coin A", "ULCA") {
        _mint(msg.sender, 10000e18);
    }
}

contract UnderlyingCoinB is ERC20 {
    constructor() ERC20("Underlying coin B", "ULCB") {
        _mint(msg.sender, 10000e18);
    }
}

contract Hw13Test is Test {
    // EIP20Interface public USDC = EIP20Interface(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    // CErc20 public cUSDC = CErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    // address public user;

    Unitroller unitroller;
    Comptroller comptroller;
    Comptroller comptrollerProxy;
    WhitePaperInterestRateModel whitePaperInterestRateModel;
    ERC20 underlyingCoinA;
    ERC20 underlyingCoinB;
    CErc20Delegate cErc20Delegate;
    CErc20Delegator cTokenA;
    CErc20Delegator cTokenB;
    SimplePriceOracle simplePriceOracle;

    address admin = makeAddr("Admin");
    address user1 = makeAddr("User1");
    address user2 = makeAddr("User2");
    address user3 = makeAddr("User3");

    function setUp() public {
        vm.startPrank(admin);

        unitroller = new Unitroller();
        comptroller = new Comptroller();
        comptrollerProxy = Comptroller(address(unitroller));
        whitePaperInterestRateModel = new WhitePaperInterestRateModel(0, 0);
        underlyingCoinA = new UnderlyingCoinA();
        underlyingCoinB = new UnderlyingCoinB();
        cErc20Delegate = new CErc20Delegate();
        simplePriceOracle = new SimplePriceOracle();

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

        comptrollerProxy._supportMarket(CToken(address(cTokenA)));
        comptrollerProxy._supportMarket(CToken(address(cTokenB)));

        // token A 的價格為 $1
        simplePriceOracle.setUnderlyingPrice(CToken(address(cTokenA)), 1e18);
        // token B 的價格為 $100
        simplePriceOracle.setUnderlyingPrice(CToken(address(cTokenB)), 100e18);

        comptrollerProxy._setCollateralFactor(CToken(address(cTokenB)), 0.5e18);
        comptrollerProxy._setCloseFactor(0.5e18);

        deal(address(underlyingCoinA), user1, 100e18);
        deal(address(underlyingCoinB), user1, 100e18);
        deal(address(underlyingCoinA), user2, 100e18);
        deal(address(underlyingCoinB), user2, 100e18);
        deal(address(underlyingCoinA), user3, 1000e18);
        deal(address(underlyingCoinB), user3, 1000e18);

        vm.stopPrank();
        // vm.label(borrowerAddress, "Borrower");
    }

    function testMintRedeem() public {
        vm.startPrank(user1);
        underlyingCoinA.approve(address(cTokenA), 100e18);
        underlyingCoinB.approve(address(cTokenB), 100e18);
        cTokenA.mint(100e18);
        cTokenB.mint(100e18);
        assertEq(cTokenA.balanceOf(user1), 100e18);
        assertEq(cTokenB.balanceOf(user1), 100e18);

        cTokenA.redeem(100e18);
        cTokenB.redeem(100e18);
        assertEq(underlyingCoinA.balanceOf(user1), 100e18);
        assertEq(underlyingCoinB.balanceOf(user1), 100e18);

        vm.stopPrank();
    }

    function user1Borrow() internal {
        vm.startPrank(user3);
        underlyingCoinA.approve(address(cTokenA), 1000e18);
        underlyingCoinB.approve(address(cTokenB), 1000e18);
        cTokenA.mint(1000e18);
        cTokenB.mint(1000e18);
        assertEq(cTokenA.balanceOf(user3), 1000e18);
        assertEq(cTokenB.balanceOf(user3), 1000e18);
        vm.stopPrank();

        vm.startPrank(user1);
        underlyingCoinB.approve(address(cTokenB), 1e18);
        cTokenB.mint(1e18);
        assertEq(cTokenB.balanceOf(user1), 1e18);

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cTokenB);
        comptrollerProxy.enterMarkets(cTokens);
        cTokenA.borrow(50e18);
        assertEq(underlyingCoinA.balanceOf(user1), 150e18);
        vm.stopPrank();
    }

    function user2Liquidate() internal {
        vm.startPrank(user2);
        (, , uint shortfall) = comptrollerProxy.getAccountLiquidity(user1);
        require(shortfall > 0, "user1 can not liquidate");

        uint borrowBalance = cTokenA.borrowBalanceStored(user1);
        underlyingCoinA.approve(address(cTokenA), 100e18);
        uint success = cTokenA.liquidateBorrow(
            user1,
            borrowBalance / 2,
            cTokenB
        );
        require(success == 0, "liquidateBorrow faild");
        vm.stopPrank();
    }

    function testBorrowRepay() public {
        user1Borrow();

        vm.startPrank(user1);
        underlyingCoinA.approve(address(cTokenA), 50e18);
        cTokenA.repayBorrow(50e18);
        assertEq(underlyingCoinA.balanceOf(user1), 100e18);
        vm.stopPrank();
    }

    function testLiquidate1() public {
        user1Borrow();

        vm.startPrank(admin);
        comptrollerProxy._setCollateralFactor(CToken(address(cTokenB)), 0.1e18);
        vm.stopPrank();

        user2Liquidate();
    }

    function testLiquidate2() public {
        user1Borrow();

        vm.startPrank(admin);
        // token B 的價格為 $100
        simplePriceOracle.setUnderlyingPrice(CToken(address(cTokenB)), 10e18);
        vm.stopPrank();

        user2Liquidate();
    }
}
