// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import "./HintFinanceVault.sol";

contract HintFinanceFactory {

    // underlyingTokens 对应一个金库
    mapping(address => address) public underlyingToVault;
    // 金库对应一个 underlyingTokens
    mapping(address => address) public vaultToUnderlying;
    // 白名单
    mapping(address => bool) public rewardTokenWhitelist;

    // 设置奖励时间
    uint256 public constant rewardDuration = 10 days;
    address public immutable owner = msg.sender;

    // 修改白名单。只有owner可以修改
    function modifyRewardTokenWhitelist(address rewardToken, bool ok) external {
        require(msg.sender == owner);
        rewardTokenWhitelist[rewardToken] = ok;
    }

    // 创建一个金库，并将其和某种 underlyingToken 对应
    function createVault(address token) external returns (address) {
        require(underlyingToVault[token] == address(0));
        address vault = underlyingToVault[token] = address(new HintFinanceVault(token));
        vaultToUnderlying[vault] = token;
        return vault;
    }

    // 给金库增加一种 rewardToken
    function addRewardToVault(address vault, address rewardToken) external {
        require(rewardTokenWhitelist[rewardToken]);
        require(vaultToUnderlying[vault] != address(0) && vaultToUnderlying[vault] != rewardToken);
        HintFinanceVault(vault).addReward(rewardToken, rewardDuration);
    }
}