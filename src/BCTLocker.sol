pragma solidity ^0.8.13;

import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interface/dex/IRouter.sol";

contract BCTLocker {
    IRouter public constant router =
        IRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // SushiSwap

    ERC20 public constant BCT =
        ERC20(0x2F800Db0fdb5223b3C3f354886d907A671414A7F);
    ERC20 public constant WMATIC =
        ERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    uint256 public totalBCTLocked = 0;

    address[] public WMATICtoBCT = [
        address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270),
        address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174),
        address(0x2F800Db0fdb5223b3C3f354886d907A671414A7F)
    ];

    constructor() {
        WMATIC.approve(address(router), type(uint256).max);
    }

    function deposit(uint256 _amount) public returns (uint256 BCTLocked) {
        WMATIC.transferFrom(msg.sender, address(this), _amount);

        BCTLocked = router.swapExactTokensForTokens(
            _amount,
            0,
            WMATICtoBCT,
            address(this),
            block.timestamp
        )[WMATICtoBCT.length - 1];

        totalBCTLocked += BCTLocked;
    }
}
