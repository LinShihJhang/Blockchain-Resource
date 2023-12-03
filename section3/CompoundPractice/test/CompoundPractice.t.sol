// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {EIP20Interface} from "compound-protocol/contracts/EIP20Interface.sol";
import {CErc20} from "compound-protocol/contracts/CErc20.sol";
import {Comptroller} from "compound-protocol/contracts/Comptroller.sol";
import "forge-std/console.sol";
import "test/helper/CompoundPracticeSetUp.sol";

interface IBorrower {
    function borrow() external;
}

contract CompoundPracticeTest is CompoundPracticeSetUp {
    EIP20Interface public USDC =
        EIP20Interface(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    CErc20 public cUSDC = CErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    address public user;

    IBorrower public borrower;

    function setUp() public override {
        super.setUp();

        // Deployed in CompoundPracticeSetUp helper
        borrower = IBorrower(borrowerAddress);
        vm.makePersistent(address(borrower));

        user = makeAddr("User");

        uint256 initialBalance = 10000 * 10 ** USDC.decimals();
        deal(address(USDC), user, initialBalance);

        vm.label(address(cUSDC), "cUSDC");
        vm.label(borrowerAddress, "Borrower");
    }

    function test_compound_mint_interest() public {
        console.log("P1");
        console.log(USDC.balanceOf(user));
        vm.startPrank(user);
        // TODO: 1. Mint some cUSDC with USDC
        uint beforUSDC = USDC.balanceOf(user);
        USDC.approve(address(cUSDC), 1000 * 10 ** USDC.decimals());
        uint mintSuccess = cUSDC.mint(1000 * 10 ** USDC.decimals());
        require(mintSuccess == 0, "error: mint return not 0");

        // TODO: 2. Modify block state to generate interest
        vm.roll(block.number + 100);

        // TODO: 3. Redeem and check the redeemed amount
        cUSDC.redeem(cUSDC.balanceOf(user));

        console.log(USDC.balanceOf(user));
        require(USDC.balanceOf(user) > beforUSDC, "error");
    }

    function test_compound_mint_interest_with_borrower() public {
        console.log("P2");
        console.log(USDC.balanceOf(user));

        vm.startPrank(user);
        // TODO: 1. Mint some cUSDC with USDC
        uint beforUSDC = USDC.balanceOf(user);
        USDC.approve(address(cUSDC), 1000 * 10 ** USDC.decimals());
        uint mintSuccess = cUSDC.mint(1000 * 10 ** USDC.decimals());
        require(mintSuccess == 0, "error: mint return not 0");

        // 2. Borrower contract will borrow some USDC
        borrower.borrow();

        // TODO: 3. Modify block state to generate interest
        vm.roll(block.number + 100);

        // TODO: 4. Redeem and check the redeemed amount
        cUSDC.redeem(cUSDC.balanceOf(user));

        console.log(USDC.balanceOf(user));

        require(USDC.balanceOf(user) > beforUSDC, "error");
    }

    function test_compound_mint_interest_with_borrower_advanced() public {
        console.log("P3");
        console.log(USDC.balanceOf(user));

        vm.startPrank(user);
        // TODO: 1. Mint some cUSDC with USDC
        uint beforUSDC = USDC.balanceOf(user);
        USDC.approve(address(cUSDC), 1000 * 10 ** USDC.decimals());
        uint mintSuccess = cUSDC.mint(1000 * 10 ** USDC.decimals());
        require(mintSuccess == 0, "error: mint return not 0");
        vm.stopPrank();

        address anotherBorrower = makeAddr("Another Borrower");
        vm.startPrank(anotherBorrower);
        // TODO: 2. Borrow some USDC with another borrower
        EIP20Interface dai = EIP20Interface(
            0x6B175474E89094C44Da98b954EedeAC495271d0F
        );
        CErc20 cDai = CErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
        deal(address(dai), anotherBorrower, 10000000 * 10 ** dai.decimals());

        dai.approve(address(cDai), 10000000 * 10 ** dai.decimals());

        uint mintCDaiSuccess = cDai.mint(10000000 * 10 ** dai.decimals());
        require(mintCDaiSuccess == 0, "error: mintCDaiSuccess return not 0");

        Comptroller comptroller = Comptroller(
            0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B
        );
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cDai);
        comptroller.enterMarkets(cTokens);

        uint mintBorrowSuccess = cUSDC.borrow(1500000 * 10 ** USDC.decimals());
        require(
            mintBorrowSuccess == 0,
            "error: mintBorrowSuccess return not 0"
        );

        vm.stopPrank();

        // TODO: 3. Modify block state to generate interest
        vm.roll(block.number + 10000);

        // TODO: 4. Redeem and check the redeemed amount
        vm.startPrank(user);
        cUSDC.redeem(cUSDC.balanceOf(user));

        console.log(USDC.balanceOf(user));

        require(USDC.balanceOf(user) > beforUSDC, "error");
        vm.stopPrank();
    }

    function test_compound_mint_interest_without_borrower_advanced() public {
        console.log("P4");
        console.log(USDC.balanceOf(user));

        vm.startPrank(user);
        // TODO: 1. Mint some cUSDC with USDC
        uint beforUSDC = USDC.balanceOf(user);
        USDC.approve(address(cUSDC), 1000 * 10 ** USDC.decimals());
        uint mintSuccess = cUSDC.mint(1000 * 10 ** USDC.decimals());
        require(mintSuccess == 0, "error: mint return not 0");
        vm.stopPrank();

        // not TODO: 2. Borrow some USDC with another borrower

        // TODO: 3. Modify block state to generate interest
        vm.roll(block.number + 10000);

        // TODO: 4. Redeem and check the redeemed amount
        vm.startPrank(user);
        cUSDC.redeem(cUSDC.balanceOf(user));

        console.log(USDC.balanceOf(user));

        require(USDC.balanceOf(user) > beforUSDC, "error");
        vm.stopPrank();
    }
}
