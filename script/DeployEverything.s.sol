// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Vault.sol";
import "../src/Strategy.sol";
import "../src/BCTLocker.sol";
import "../src/interface/IStrategy.sol";

contract DeployEverything is Script {
    function run() external {
        vm.startBroadcast();
        Vault vault = new Vault(
            "mooCrvSTMATIC-F Boost",
            "boost(mooCrvSTMATIC-F)"
        );
        BCTLocker locker = new BCTLocker();
        MooCurveLPBoostStakerStrategy strategy = new MooCurveLPBoostStakerStrategy(
                address(vault),
                address(locker)
            );
        vault.setStrategy(IStrategy(address(strategy)));

        vm.stopBroadcast();
    }
}
