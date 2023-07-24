// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/01.random/random.sol";

contract randomTest is Test {

    Random public random;

    function setUp() public{
        random = new Random();
    }

    function test_Sloved() public {
        random.solve(4);
        assertEq(random.solved(), true);
    }
}
