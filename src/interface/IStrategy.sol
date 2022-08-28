// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IStrategy {
    function vault() external view returns (address);

    function want() external view returns (ERC20);

    function balanceOf() external view returns (uint256);

    function beforeDeposit() external;

    function deposit() external;

    function withdraw(uint256) external;

    function balanceOfWant() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function harvest() external;

    function panic() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    function unirouter() external view returns (address);
}
