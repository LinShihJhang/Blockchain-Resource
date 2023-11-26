// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { testERC20 } from "../src/test/testERC20.sol";
import { testERC721 } from "../src/test/testERC721.sol";
import { MultiSigWallet } from "../src/MultiSigWallet/MultiSigWallet.sol";
import { BasicProxy } from "../src/BasicProxy.sol";

contract BasicProxyTest is Test {

  address public admin = makeAddr("admin");
  address public alice = makeAddr("alice");
  address public bob = makeAddr("bob");
  address public carol = makeAddr("carol");
  address public receiver = makeAddr("receiver");

  MultiSigWallet public wallet;
  BasicProxy public proxy;
  MultiSigWallet public proxyWallet;

  testERC20 public erc20;
  testERC721 public erc721;

  function setUp() public {
    vm.startPrank(admin);
    wallet = new MultiSigWallet([alice, bob, carol]);

    // 1. deploy proxy contract, which implementation should points at wallet's address
    proxy  = new BasicProxy(address(wallet));

    // 2. proxyWallet is a pointer that treats proxy contract as MultiSigWallet
    proxyWallet = MultiSigWallet(address(proxy));

    proxyWallet.initializer([alice, bob, carol]);


    vm.deal(address(proxy), 100 ether);
    vm.stopPrank();
  }

  function test_updateOwner() public {
    // 1. try to update Owner
    proxyWallet.updateOwner(alice, bob, carol);
    // 2. check the owner1 is alice, owner2 is bob and owner3 is carol
    assertEq(proxyWallet.owner1(), alice);
    assertEq(proxyWallet.owner2(), bob);
    assertEq(proxyWallet.owner3(), carol);
  }

  // function test_submit_tx() public {
  //   test_updateOwner();
  //   // 1. prank as one of the owner
  //   vm.startPrank(alice);
    
  //   // 2. submit a transaction that transfer 10 ether to bob
  //   proxyWallet.submitTransaction(bob, 10 ether, "");

  //   // Does it success? Why?
  // }

  function test_call_initialize_and_check() public {
    // 1. call initialize function

    // 2. check the owner1, owner2, owner3 is initialized
    assertEq(proxyWallet.owner1(), alice);
    assertEq(proxyWallet.owner2(), bob);
    assertEq(proxyWallet.owner3(), carol);
  }

  event SubmitTransaction(uint indexed txIndex, address indexed to, uint value);

  function test_call_initialize_and_submit_tx() public {

    // 1. call initialize function

    // 2. submit a transaction that transfer 10 ether to bob
    vm.startPrank(alice);
    //vm.expectEmit(true, true, false, true);
    //emit proxyWallet.SubmitTransaction(proxyWallet.transactions().length, bob, 10 ether);
    proxyWallet.submitTransaction(bob, 10 ether, "");

    // 3. check the transaction is submitted
    (address to, uint256 value, bytes memory data,,)= proxyWallet.transactions(0);
    assertEq(to, bob);
    assertEq(value, 10 ether);
    assertEq(data.length, 0);
  }

}
