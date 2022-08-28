// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "openzeppelin/contracts/token/ERC20/ERC20.sol";

// import "../src/Vault.sol";
// import "../src/Strategy.sol";
// import "../src/interface/IWETH.sol";
// import "../src/interface/IStrategy.sol";
// import "../src/interface/curve/ICurveSwap.sol";
// import "../src/interface/dex/IRouter.sol";

import "../src/Vault.sol";
import "../src/Strategy.sol";
import "../src/BCTLocker.sol";
import "../src/interface/IWETH.sol";
import "../src/interface/IStrategy.sol";
import "../src/interface/dex/IRouter.sol";
import "../src/interface/curve/ICurveSwap.sol";

contract IntegrationTest is Test {
    Vault vault;
    MooCurveLPBoostStakerStrategy strategy;
    BCTLocker locker;

    address admin = address(101);
    address u1 = address(1);
    address u2 = address(2);

    IWETH constant WMATIC = IWETH(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    function setUp() public {
        startHoax(admin);
        vault = new Vault("mooCrvSTMATIC-F Boost", "boost(mooCrvSTMATIC-F)");
        locker = new BCTLocker();
        strategy = new MooCurveLPBoostStakerStrategy(
            address(vault),
            address(locker)
        );
        vault.setStrategy(IStrategy(address(strategy)));

        vm.label(address(vault.want()), "want");
        vm.label(strategy.pool(), "pool");
        vm.label(address(strategy.beefyVault()), "Beefy Vault");
        vm.label(address(strategy.beefyBoostFarm()), "Beefy Farm");
        vm.label(address(strategy.reward()), "LDO");
        vm.label(address(strategy.wmatic()), "WMATIC");

        vm.stopPrank();
    }

    // Everything is fair in hackathons, bad tests ftw :P
    function testEverything() public {
        startHoax(u1);
        depositMaticInCurvePool(1 ether);
        ERC20(strategy.want()).approve(address(vault), type(uint256).max);
        vault.depositAll();
        emit log_named_uint("u1:share_balance", vault.balanceOf(u1));
        vm.stopPrank();

        startHoax(u2);
        depositMaticInCurvePool(1.5 ether);
        ERC20(strategy.want()).approve(address(vault), type(uint256).max);
        vault.depositAll();
        emit log_named_uint("u1:share_balance", vault.balanceOf(u2));
        vm.stopPrank();

        skip(2000);
        strategy.harvest();
        emit log_named_uint("BCT Locked", locker.totalBCTLocked());

        startHoax(u1);
        vault.withdrawAll();
        vm.stopPrank();
    }

    function wrapMatic(uint256 _amount) internal {
        WMATIC.deposit{value: _amount}();
    }

    function depositMaticInCurvePool(uint256 _amount) internal {
        wrapMatic(_amount);

        uint256[2] memory amounts;
        amounts[1] = _amount;
        ERC20(address(WMATIC)).approve(strategy.pool(), _amount);
        ICurveSwap(strategy.pool()).add_liquidity(amounts, 0);
    }
}
