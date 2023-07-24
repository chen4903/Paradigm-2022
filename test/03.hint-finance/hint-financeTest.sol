pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../../src/03.hint-finance/Setup.sol";
import "./utils.sol";
import "./attacker.sol";
import "../../src/03.hint-finance/HintFinanceFactory.sol";

contract POC is Addrs, Test {
    Hack public hack; // 攻击合约
    Setup public setUpInstance;
    HintFinanceFactory public hintFinanceFactory;

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.alchemyapi.io/v2/7Brn0mxZnlMWbHf0yqAEicmsgKdLJGmA", 15_409_399);
        // 因为这道题也是fork主网数据，因此可以复现，其实30个就够了。
        setUpInstance = new Setup{value: 1000 ether}(); 
        hintFinanceFactory = setUpInstance.hintFinanceFactory();
        hack = new Hack(hintFinanceFactory);

        vm.label(0x89Ab32156e46F46D02ade3FEcbe5Fc4243B9AAeD,"ERC777 PNT");
        vm.label(0x3845badAde8e6dFF049820680d1F14bD3903a5d0,"ERC20 SAND");
        vm.label(0xfF20817765cB7f73d4bde2e66e067E58D11095C2,"ERC777 AMP");
        vm.label(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24,"EIP1820");
        vm.label(address(hack),"attacker");
        vm.label(address(hintFinanceFactory),"hintFinanceFactory");
        vm.label(address(setUpInstance),"setUpInstance");
    }

    function test_Hack() public {
        hack.attack();
    }

}
