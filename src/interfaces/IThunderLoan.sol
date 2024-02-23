// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// @Audit Ithunder loan is not implemmented in ThunderLoan Contract
// Also The Repay fucntion of The IThunderLoan InterfAce Is Diffrenent From the ThunderLoan Contract
interface IThunderLoan {
    function repay(address token, uint256 amount) external;
}
