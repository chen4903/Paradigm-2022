// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface ERC20Like {
    function transfer(address dst, uint qty) external returns (bool);
    function transferFrom(address src, address dst, uint qty) external returns (bool);
    function approve(address dst, uint qty) external returns (bool);
    function balanceOf(address who) external view returns (uint);
}

interface IHintFinanceFlashloanReceiver {
    function onHintFinanceFlashloan(
        address token,
        address factory,
        uint256 amount,
        bool isUnderlyingOrReward,
        bytes memory data
    ) external;
}

contract HintFinanceVault {

    // 主要用来存储奖励的相关时间
    struct Reward {
        uint256 rewardsDuration;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    // 每一个 rewardToken 对应的相关时间
    mapping(address => Reward) public rewardData;
    // 存放所有 rewardTokens 的数组
    address[] public rewardTokens;

    // 用户和 rewardToken ID 的对应关系
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    // 用户和 rewardToken 的拥有数量情况
    mapping(address => mapping(address => uint256)) public rewards;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    address public immutable factory;
    address public immutable underlyingToken;

    bool locked = false;

    // 设置铸造这个金库的工厂和 underlyingTokens
    constructor(address _underlyingToken) {
        underlyingToken = _underlyingToken;
        factory = msg.sender;
    }

    /* ========== MODIFIERS ========== */

    // 更新某个用户的rewardToken信息，因为用户的 rewardToken信息会随着时间变化
    modifier updateReward(address account) {
        for (uint i; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            rewardData[token].rewardPerTokenStored = rewardPerToken(token);
            rewardData[token].lastUpdateTime = lastTimeRewardApplicable(token);
            if (account != address(0)) {
                rewards[account][token] = earned(account, token);
                userRewardPerTokenPaid[account][token] = rewardData[token].rewardPerTokenStored;
            }
        }
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // 增加一种 rewardToken
    function addReward(address rewardToken, uint256 rewardDuration) external {
        require(msg.sender == factory);
        require(rewardData[rewardToken].rewardsDuration == 0);
        rewardTokens.push(rewardToken);
        rewardData[rewardToken].rewardsDuration = rewardDuration;
    }

    /* ========== VIEWS ========== */

    // 用于查看 rewardToken 是否达到了完成时间
    function lastTimeRewardApplicable(address rewardToken) public view returns (uint256) {
        if (block.timestamp < rewardData[rewardToken].periodFinish) {
            return block.timestamp;
        } else {
            return rewardData[rewardToken].periodFinish;
        }
    }

    // 计算：根据时间来线性释放 rewardToken
    function rewardPerToken(address rewardToken) public view returns (uint256) {
        if (totalSupply == 0) return 0;
        uint256 newTime = lastTimeRewardApplicable(rewardToken) - rewardData[rewardToken].lastUpdateTime;
        uint256 newAccumulated = newTime * rewardData[rewardToken].rewardRate / totalSupply;
        return rewardData[rewardToken].rewardPerTokenStored + newAccumulated;
    }

    // 计算：给 account 用户随着时间变化，更新 rewardToken 
    function earned(address account, address rewardToken) public view returns (uint256) {
        uint256 newAccumulated = balanceOf[account] * (rewardPerToken(rewardToken) - userRewardPerTokenPaid[account][rewardToken]);
        return rewards[account][rewardToken] + newAccumulated;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // 转账
    function provideRewardTokens(address rewardToken, uint256 amount) public updateReward(address(0)) {
        require(rewardData[rewardToken].rewardsDuration != 0);
        _updateRewardRate(rewardToken, amount);
        ERC20Like(rewardToken).transferFrom(msg.sender, address(this), amount);
    }

    // 更新 rewardToken 的利率
    function _updateRewardRate(address rewardToken, uint256 amount) internal {
        if (block.timestamp >= rewardData[rewardToken].periodFinish) {
            rewardData[rewardToken].rewardRate = amount / rewardData[rewardToken].rewardsDuration;
        } else {
            uint256 remaining = rewardData[rewardToken].periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardData[rewardToken].rewardRate;
            rewardData[rewardToken].rewardRate = (amount + leftover) / rewardData[rewardToken].rewardsDuration;
        }
        rewardData[rewardToken].lastUpdateTime = block.timestamp;
        rewardData[rewardToken].periodFinish = block.timestamp + rewardData[rewardToken].rewardsDuration;
    }

    // 批量取款
    function getRewards() external updateReward(msg.sender) {
        for (uint i; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            uint256 reward = rewards[msg.sender][rewardToken];
            if (reward > 0) {
                rewards[msg.sender][rewardToken] = 0;
                ERC20Like(rewardToken).transfer(msg.sender, reward);
            }
        }
    }

//////////////////////////////////////////// ERC777重入攻击 ///////////////////////////////////////////////

    // 存款，缺乏重入保护
    function deposit(uint256 amount) external updateReward(msg.sender) returns (uint256) {
        uint256 bal = ERC20Like(underlyingToken).balanceOf(address(this));
        // 4. totalSupply会远大于bal，因为bal是金库拥有的数量，而totalSupply是全部人拥有的量，
        //    因为在withdraw的时候转给了攻击地址一大笔钱，但是totalSupply还没来得及更新，因此
        //    下面式子中totalSupply和bal不变，计算出来的shares会比原来大很多.
        // PS：注意它这样计算shares是为了线性计算用户存入token之后可以得到的份额，然后根据份额在取款的时候给利息
        uint256 shares = totalSupply == 0 ? amount : amount * totalSupply / bal;
        // 5. 然后金库给攻击合约转 bal-1 的金额
        //    注意此时的amount是(bal-1)/2，因此在调用钩子函数的时候并不会再次重入
        ERC20Like(underlyingToken).transferFrom(msg.sender, address(this), amount);
        totalSupply += shares;
        // 6. 但是金库却给我们记录了大了好多倍的金额
        balanceOf[msg.sender] += shares;
        return shares;
    }

    // 单个取款，缺乏重入保护
    function withdraw(uint256 shares) external updateReward(msg.sender) returns (uint256) {
        // 1. 不用验证msg.sender是不是拥有shares这么多钱，因为不够的话会下溢，但0.8.0^会报错revert
        uint256 bal = ERC20Like(underlyingToken).balanceOf(address(this));
        // PS：这里的式子是计算我们的shares占总totalSupply的百分比，然后获取金库一定比例的金额
        uint256 amount = shares * bal / totalSupply;
        // 2. 会给我们的攻击合约发送一大笔钱：bal-1
        // 3. 然后进入到钩子函数，然后钩子函数又会调用到deposit()
        ERC20Like(underlyingToken).transfer(msg.sender, amount); 
        // 7. 执行完钩子函数之后，我们将我们的余额减去bal-1，此时不会失败，因为我们的deposit()时给我们记录了好几倍的金额
        totalSupply -= shares;
        // 8.最后减去一小部分shares
        balanceOf[msg.sender] -= shares;
        return amount;
    }

//////////////////////////////////////////// ERC777重入攻击 ///////////////////////////////////////////////

//////////////////////////////////////////// ERC20函数选择器碰撞approve授权 ///////////////////////////////////////////////
    // 闪电贷
    function flashloan(address token, uint256 amount, bytes calldata data) external updateReward(address(0)) {
        // 1.调用SAND合约的approveAndCall()，让他来调用闪电贷
        uint256 supplyBefore = totalSupply;
        uint256 balBefore = ERC20Like(token).balanceOf(address(this));
        bool isUnderlyingOrReward = token == underlyingToken || rewardData[token].rewardsDuration != 0;

        // 需要攻击合约实现这个方法
        ERC20Like(token).transfer(msg.sender, amount);
        // 2.金库合约调用onHintFinanceFlashloan()，因为函数选择器碰撞的原因，金库合约会调用到SAND合约的approveAndCall()，然后授权金额uint256(factory)数量给攻击合约token
        // 3.在approveAndCall合约中需要注意的是，形参需要满足doFirstParamEqualsAddress()的要求，查看此方法，要求是：第一个是msg.sender，并且至少两个形参
        IHintFinanceFlashloanReceiver(msg.sender).onHintFinanceFlashloan(token, factory, amount, isUnderlyingOrReward, data);

        // 需要攻击合约实现这个方法
        uint256 balAfter = ERC20Like(token).balanceOf(address(this));
        uint256 supplyAfter = totalSupply;

        require(supplyBefore == supplyAfter);
        // isUnderlyingOrReward需要是一个bool
        if (isUnderlyingOrReward) {
            uint256 extra = balAfter - balBefore;
            if (extra > 0 && token != underlyingToken) {
                _updateRewardRate(token, extra);
            }
        } else {
            require(balAfter == balBefore); // don't want random tokens to get stuck
        }
    }

//////////////////////////////////////////// ERC20函数选择器碰撞approve授权 ///////////////////////////////////////////////

}