pragma solidity ^0.8.13;

import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./BCTLocker.sol";
import "./interface/beefy/IBeefyVault.sol";
import "./interface/beefy/IBeefyBoost.sol";
import "./interface/dex/IRouter.sol";

contract MooCurveLPBoostStakerStrategy {
    address vault;
    ERC20 public want = ERC20(0xe7CEA2F6d7b120174BF3A9Bc98efaF1fF72C997d); // moo curve matic-stmatic lp token
    ERC20 public reward = ERC20(0xC3C7d422809852031b44ab29EEC9F1EfF2A58756); // $LDO
    ERC20 public wmatic = ERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270); // $WMATIC

    address public pool = address(0xFb6FE7802bA9290ef8b00CA16Af4Bc26eb663a28);

    IBeefyVault public beefyVault =
        IBeefyVault(0xE0570ddFca69E5E90d83Ea04bb33824D3BbE6a85);
    IBeefyBoost public beefyBoostFarm =
        IBeefyBoost(0xBb77dDe3101B8f9B71755ABe2F69b64e79AE4A41);
    IRouter public router = IRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    BCTLocker public creditLocker;

    uint256 public totalStaked = 0;

    address[] public RewardtoWMATIC = [
        address(0xC3C7d422809852031b44ab29EEC9F1EfF2A58756),
        address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270)
    ];

    constructor(address _vault, address _creditLocker) {
        vault = _vault;
        creditLocker = BCTLocker(_creditLocker);

        want.approve(address(beefyVault), type(uint256).max);
        beefyVault.approve(address(beefyBoostFarm), type(uint256).max);
        wmatic.approve(address(creditLocker), type(uint256).max);
        reward.approve(address(router), type(uint256).max);
    }

    function deposit() public {
        /*
            1. Deposit `want` in Beefy vault.
            2. Stake Beefy's moo tokens in Boost farm.
         
        */
        beefyVault.depositAll();
        uint256 mooBal = beefyVault.balanceOf(address(this));
        beefyBoostFarm.stake(mooBal);
        totalStaked += mooBal;
    }

    function beforeDeposit() external {
        require(msg.sender == vault, "!vault");
        _harvest();
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 startingWantBal = want.balanceOf(address(this));
        if (startingWantBal >= _amount) want.transfer(vault, _amount);
        /* 
            1. Unstake from BoostFarm
            2. Redeem shares
        */
        uint256 sharesToUnstake = ((_amount * 1e18) /
            beefyVault.getPricePerFullShare()) + 1;
        beefyBoostFarm.withdraw(sharesToUnstake);
        totalStaked -= sharesToUnstake;
        beefyVault.withdraw(sharesToUnstake);
        uint256 endingWantBal = want.balanceOf(address(this));

        require(
            endingWantBal - startingWantBal >= _amount,
            "Strategy Insolvent"
        );
        want.transfer(vault, _amount);
    }

    function harvest() external virtual {
        _harvest();
    }

    function _harvest() internal {
        beefyBoostFarm.getReward();
        uint256 rewardBalance = reward.balanceOf(address(this));
        if (rewardBalance > 0) {
            uint256 wmaticGot = router.swapExactTokensForTokens(
                rewardBalance,
                0,
                RewardtoWMATIC,
                address(this),
                block.timestamp
            )[RewardtoWMATIC.length - 1];

            creditLocker.deposit(wmaticGot);
        }
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfPool() public view returns (uint256) {
        return (totalStaked * beefyVault.getPricePerFullShare()) / 1e18;
    }
}
