pragma solidity >=0.5.0; // 注意版本，一些库的版本很低，foundry无法通过编译

import "../../src/05.vanity/Setup.sol";
import "forge-std/Test.sol";
import "../../src/05.vanity/Challenge.sol";
pragma abicoder v2; // foundry提示说要添加这个否则不兼容

contract vanityTest is Test{

    Setup level;
    Challenge challenge;

    function setUp() public {
        level = new Setup();
        challenge = level.challenge();
    }

    function test_isSolved() public {
        // 解法1：
        //IChallenge(address(challenge)).solve(address(0x0000000000000000000000000000000000000002), hex"8cf1a8bb");
        // 解法2：
        IChallenge(address(challenge)).solve(address(0x0000000000000000000000000000000000000002), abi.encodePacked(uint256(3341776893)));
        assertEq(level.isSolved(),true);
    }

}

interface IChallenge{
    function solve(address , bytes memory ) external;
}