pragma solidity 0.8.16;

import "forge-std/Test.sol";

contract Addrs {
    
    address[3] public underlyingTokens = [
        0x89Ab32156e46F46D02ade3FEcbe5Fc4243B9AAeD,
        ///PNT 777
        0x3845badAde8e6dFF049820680d1F14bD3903a5d0,
        ///SAND
        0xfF20817765cB7f73d4bde2e66e067E58D11095C2
        ///AMP 777
    ];

    address public EIP1820 = 0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24;

}

interface EIP1820Like {
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer)
        external;
}

interface SandLike {
    function approveAndCall(address target, uint256 amount, bytes calldata data) external;
}