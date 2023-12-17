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

contract Hw14Test is Test {
    Unitroller unitroller;
    Comptroller comptroller;
    Comptroller comptrollerProxy;
    WhitePaperInterestRateModel whitePaperInterestRateModel;
    ERC20 USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ERC20 UNI = ERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
    CErc20Delegate cErc20Delegate;
    CErc20Delegator cUSDC;
    CErc20Delegator cUNI;
    SimplePriceOracle simplePriceOracle;

    address admin = makeAddr("Admin");
    address user1 = makeAddr("User1");
    address user2 = makeAddr("User2");
    address user3 = makeAddr("User3");
    uint initUSDC = 10000 * 1e6;
    uint initUNI = 10000 * 1e18;

    function setUp() public {
        //Fork Ethereum mainnet at block 17465000(Reference)
        uint256 forkId = vm.createFork(vm.envString("MAINNET_RPC_URL"));
        vm.selectFork(forkId);
        vm.rollFork(17_465_000);
        assertEq(block.number, 17_465_000);

        vm.startPrank(admin);

        unitroller = new Unitroller();
        comptroller = new Comptroller();
        comptrollerProxy = Comptroller(address(unitroller));
        whitePaperInterestRateModel = new WhitePaperInterestRateModel(0, 0);
        cErc20Delegate = new CErc20Delegate();
        simplePriceOracle = new SimplePriceOracle();

        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);
        comptrollerProxy._setPriceOracle(simplePriceOracle);

        //cERC20 的 decimals 皆為 18，初始 exchangeRate 為 1:1
        //使用 USDC 以及 UNI 代幣來作為 token A 以及 Token B
        cUSDC = new CErc20Delegator(
            address(USDC),
            comptrollerProxy,
            whitePaperInterestRateModel,
            1e6,
            "Compound USDC",
            "cUSDC",
            18,
            payable(admin),
            address(cErc20Delegate),
            "0x"
        );

        cUNI = new CErc20Delegator(
            address(UNI),
            comptrollerProxy,
            whitePaperInterestRateModel,
            1e18,
            "Compound UNI",
            "cUNI",
            18,
            payable(admin),
            address(cErc20Delegate),
            "0x"
        );

        comptrollerProxy._supportMarket(CToken(address(cUSDC)));
        comptrollerProxy._supportMarket(CToken(address(cUNI)));

        // 在 Oracle 中設定 USDC 的價格為 $1，UNI 的價格為 $5
        simplePriceOracle.setUnderlyingPrice(CToken(address(cUSDC)), 1e30);
        simplePriceOracle.setUnderlyingPrice(CToken(address(cUNI)), 5e18);

        // Close factor 設定為 50%
        assertEq(
            comptrollerProxy._setCloseFactor(0.5e18),
            0 // no error
        );
        // Liquidation incentive 設為 8% (1.08 * 1e18)
        assertEq(
            comptrollerProxy._setLiquidationIncentive(1.08e18),
            0 // no error
        );
        // 設定 UNI 的 collateral factor 為 50%
        assertEq(
            comptrollerProxy._setCollateralFactor(CToken(address(cUNI)), 0.5e18),
            0 // no error
        );
        
        //deal(address(USDC), user1, initUSDC);
        deal(address(UNI), user1, initUNI);
        deal(address(USDC), user3, initUSDC);
        //deal(address(UNI), user3, initUNI);

        vm.label(address(comptrollerProxy), "comptrollerProxy");
        vm.label(address(cUSDC), "cUSDC");
        vm.label(address(cUNI), "cUNI");
        vm.label(address(USDC), "USDC");
        vm.label(address(UNI), "UNI");

        vm.stopPrank();
    }

    function user1Borrow() internal {
        
        vm.startPrank(user3);
        USDC.approve(address(cUSDC), initUSDC);
        cUSDC.mint(initUSDC);
        assertEq(cUSDC.balanceOf(user3), initUSDC * 1e12);
        //UNI.approve(address(cUNI), initUNI);
        //cUNI.mint(initUNI);
        //assertEq(cUNI.balanceOf(user3), initUNI);
        vm.stopPrank();

        //User1 使用 1000 顆 UNI 作為抵押品借出 2500 顆 USDC
        vm.startPrank(user1);
        UNI.approve(address(cUNI), initUNI);
        cUNI.mint(1000e18);
        assertEq(cUNI.balanceOf(user1), 1000e18);

        address[] memory cTokens = new address[](2);
        cTokens[0] = address(cUNI);
        cTokens[1] = address(cUSDC);
        comptrollerProxy.enterMarkets(cTokens);
        cUSDC.borrow(2500e6);
        //assertEq(USDC.balanceOf(user1), 1);
        vm.stopPrank();
    }

    function user2Liquidate() internal {
        vm.startPrank(user2);
        (, , uint shortfall) = comptrollerProxy.getAccountLiquidity(user1);
        require(shortfall > 0, "user1 can not liquidate");

        uint borrowBalance = cUSDC.borrowBalanceStored(user1);
        // underlyingCoinA.approve(address(cTokenA), 100e18);
        // uint success = cTokenA.liquidateBorrow(
        //     user1,
        //     borrowBalance / 2,
        //     cTokenB
        // );
        // require(success == 0, "liquidateBorrow faild");
        vm.stopPrank();
    }

    function testFlashLoan() public {
        user1Borrow();

        // 將 UNI 價格改為 $4 使 User1 產生 Shortfall
        vm.startPrank(admin);
        simplePriceOracle.setUnderlyingPrice(CToken(address(cUNI)), 4e18);
        vm.stopPrank();

        //讓 User2 透過 AAVE 的 Flash loan 來借錢清算 User1
        user2Liquidate();

        // 可以自行檢查清算 50% 後是不是大約可以賺 63 USDC

    }
}
