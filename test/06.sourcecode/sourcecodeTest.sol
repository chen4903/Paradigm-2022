pragma solidity 0.8.16;

import "../../src/06.sourcecode/Setup.sol";
import "../../src/06.sourcecode/Challenge.sol";
import "forge-std/Test.sol";

contract sourcecodeTest is Test{

    Setup level;
    Challenge challenge;

    function setUp() public {
        level = new Setup();
        challenge = level.challenge();
    }

    function test_isSolved() public {
        IChallenge(address(challenge)).solve(
            abi.encodePacked(
                hex"7f5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b80600152602152607f60005360416000f35b5b5b5b5b5b5b5b5b5b5b5b5b5b5b80600152602152607f60005360416000f3")
        );
        assertEq(level.isSolved(),true);
    }

}

interface IChallenge{
    function solve(bytes memory ) external;
}