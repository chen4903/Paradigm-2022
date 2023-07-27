// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

contract Deployer {
    constructor(bytes memory code) {
        assembly {
            return (add(code, 0x20), mload(code)) 
        }
    }
}

contract Challenge {

    bool public solved = false;

    function safe(bytes memory code) private pure returns (bool) {
        uint i = 0;
        while (i < code.length) {
            uint8 op = uint8(code[i]); 
            // 以下操作码不可用
            if (op >= 0x30 && op <= 0x48) {
                return false;
            }
            // 除了0x30~0x48的一些操作码，下面这些操作码也不可以用
            if (
                   op == 0x54 // SLOAD
                || op == 0x55 // SSTORE
                || op == 0xF0 // CREATE
                || op == 0xF1 // CALL
                || op == 0xF2 // CALLCODE
                || op == 0xF4 // DELEGATECALL
                || op == 0xF5 // CREATE2
                || op == 0xFA // STATICCALL
                || op == 0xFF // SELFDESTRUCT
            ) return false;
            // 如果操作码是0x60~0x7f，那么判断的位置i就可以向前推进
            // 似乎可以跳过一些判断？意思是bytecode某些位置可以包含这些黑名单操作码？
            // 只要这些黑名单操作码位于操作码0x60~0x7f后面的适当位置
            if (op >= 0x60 && op < 0x80) i += (op - 0x60) + 1;
            
            i++;
        }
        
        return true;
    }

    function solve(bytes memory code) external {
        require(code.length > 0);
        require(safe(code), "deploy/code-unsafe");
        address target = address(new Deployer(code));
        (bool ok, bytes memory result) = target.staticcall("");
        require(
            ok &&
            keccak256(code) == target.codehash &&
            keccak256(result) == target.codehash
        );
        solved = true;
    }
}